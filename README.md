# gh-infra

Self-hosted GitHub Actions runners for Flutter/Android builds, deployed via Portainer.

---

## Prerequisites

- Portainer running with access to a Docker host
- A GitHub fine-grained PAT with **Administration: Read & Write** permission on the target repository

---

## 1. Build the image in Portainer

1. Go to **Images → Build image**
2. Set the image name to `gh-runner-image:1.0.0`
3. Switch to **Upload** and upload the contents of `github-runners/flutter-android/` (both `Dockerfile` and `entrypoint.sh` must be in the same upload)
4. Click **Build the image** and wait for it to complete — this takes a few minutes as it downloads the Android SDK and Flutter

---

## 2. Deploy the stack

1. Go to **Stacks → Add stack**
2. Name it (e.g. `gh-runners`)
3. Paste the contents of `docker-compose.yml` into the editor
4. Scroll down to **Environment variables** and add the following:

| Variable | Value |
|---|---|
| `GITHUB_PAT` | Your fine-grained PAT |
| `GITHUB_REPOSITORY` | `owner/repo` (e.g. `myorg/myrepo`) |
| `RUNNER_NAME` | Prefix for runner names (e.g. `flutter-runner`) |

5. Click **Deploy the stack**

---

## 3. Verify

- Open your repository on GitHub → **Settings → Actions → Runners**
- Both `flutter-runner-<hostname>` runners should appear as **Online**
- They will accept jobs with the labels `self-hosted`, `flutter`, and `android`

---

## Stopping the runners

Removing or stopping the stack in Portainer sends `SIGTERM` to the containers, which automatically deregisters both runners from GitHub before they shut down.

---

## Upgrading Flutter

1. Rebuild the image in Portainer with a new tag (e.g. `gh-runner-image:1.1.0`) using an updated `Dockerfile` (`ARG FLUTTER_VERSION=<new-version>`)
2. Update the `image:` field in `docker-compose.yml` to the new tag
3. Redeploy the stack
