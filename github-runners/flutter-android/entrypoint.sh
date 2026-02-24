#!/bin/bash
set -euo pipefail

# ─── Validate required environment variables ─────────────────────────────────
: "${GITHUB_PAT:?GITHUB_PAT must be set}"
: "${GITHUB_REPOSITORY:?GITHUB_REPOSITORY must be set}"

RUNNER_DIR="/opt/actions-runner"
RUNNER_NAME="${RUNNER_NAME:-flutter-runner}-$(hostname)"

# ─── Obtain a runner registration token ──────────────────────────────────────
echo "Requesting runner registration token for ${GITHUB_REPOSITORY}..."
REGISTRATION_TOKEN=$(curl -sSL \
    -X POST \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer ${GITHUB_PAT}" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/repos/${GITHUB_REPOSITORY}/actions/runners/registration-token" \
    | jq -r '.token')

if [[ -z "${REGISTRATION_TOKEN}" || "${REGISTRATION_TOKEN}" == "null" ]]; then
    echo "ERROR: Failed to obtain registration token. Check GITHUB_PAT and GITHUB_REPOSITORY." >&2
    exit 1
fi

# ─── Remove stale configuration if present ───────────────────────────────────
if [[ -f "${RUNNER_DIR}/.runner" ]]; then
    echo "Stale runner config detected, removing before reconfiguring..."
    REMOVAL_TOKEN=$(curl -sSL \
        -X POST \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer ${GITHUB_PAT}" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        "https://api.github.com/repos/${GITHUB_REPOSITORY}/actions/runners/remove-token" \
        | jq -r '.token')
    "${RUNNER_DIR}/config.sh" remove --token "${REMOVAL_TOKEN}" || true
fi

# ─── Configure the runner ─────────────────────────────────────────────────────
echo "Configuring runner '${RUNNER_NAME}'..."
"${RUNNER_DIR}/config.sh" \
    --url "https://github.com/${GITHUB_REPOSITORY}" \
    --token "${REGISTRATION_TOKEN}" \
    --name "${RUNNER_NAME}" \
    --labels "self-hosted,linux,homelab,flutter,android" \
    --work "_work" \
    --unattended \
    --replace

# ─── Clean deregistration on container stop ──────────────────────────────────
cleanup() {
    echo "Deregistering runner '${RUNNER_NAME}'..."
    REMOVAL_TOKEN=$(curl -sSL \
        -X POST \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer ${GITHUB_PAT}" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        "https://api.github.com/repos/${GITHUB_REPOSITORY}/actions/runners/remove-token" \
        | jq -r '.token')

    "${RUNNER_DIR}/config.sh" remove --token "${REMOVAL_TOKEN}" || true
    echo "Runner deregistered."
}

trap cleanup SIGTERM SIGINT

# ─── Start the runner ─────────────────────────────────────────────────────────
echo "Starting runner '${RUNNER_NAME}'..."
"${RUNNER_DIR}/run.sh" &

# Wait for the runner process so the trap fires on signals
wait $!
