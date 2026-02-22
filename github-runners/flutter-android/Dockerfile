FROM ubuntu:22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# ─── Layer 1: System packages ────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
        curl \
        wget \
        unzip \
        git \
        openjdk-17-jdk \
        ca-certificates \
        xz-utils \
        jq \
        libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*

# ─── Layer 2: Android SDK ────────────────────────────────────────────────────
ENV ANDROID_HOME=/opt/android-sdk
ENV PATH="${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${PATH}"

RUN mkdir -p "${ANDROID_HOME}/cmdline-tools" \
    && CMDLINE_URL="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip" \
    && wget -q "${CMDLINE_URL}" -O /tmp/cmdline-tools.zip \
    && unzip -q /tmp/cmdline-tools.zip -d /tmp/cmdline-tools-extract \
    && mv /tmp/cmdline-tools-extract/cmdline-tools "${ANDROID_HOME}/cmdline-tools/latest" \
    && rm -rf /tmp/cmdline-tools.zip /tmp/cmdline-tools-extract

RUN yes | sdkmanager --licenses > /dev/null 2>&1 \
    && sdkmanager \
        "platforms;android-34" \
        "build-tools;34.0.0" \
        "platform-tools"

# ─── Layer 3: Flutter SDK ────────────────────────────────────────────────────
ARG FLUTTER_VERSION=3.41.1

ENV FLUTTER_HOME=/opt/flutter
ENV PATH="${FLUTTER_HOME}/bin:${PATH}"

RUN wget -q "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
        -O /tmp/flutter.tar.xz \
    && tar -xf /tmp/flutter.tar.xz -C /opt \
    && rm /tmp/flutter.tar.xz \
    && git config --global --add safe.directory /opt/flutter \
    && flutter config --no-analytics \
    && flutter precache --android

# ─── Layer 4: GitHub Actions runner ──────────────────────────────────────────
ENV RUNNER_HOME=/opt/actions-runner

RUN mkdir -p "${RUNNER_HOME}" \
    && RUNNER_VERSION=$(curl -sSL \
        -H "Accept: application/vnd.github+json" \
        "https://api.github.com/repos/actions/runner/releases/latest" \
        | jq -r '.tag_name' | sed 's/^v//') \
    && curl -sSL \
        "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz" \
        -o /tmp/runner.tar.gz \
    && tar -xf /tmp/runner.tar.gz -C "${RUNNER_HOME}" \
    && rm /tmp/runner.tar.gz \
    && "${RUNNER_HOME}/bin/installdependencies.sh"

# ─── Layer 5: Non-root runner user ───────────────────────────────────────────
RUN useradd -m -s /bin/bash runner \
    && mkdir -p "${RUNNER_HOME}/_work" \
    && chown -R runner:runner "${RUNNER_HOME}" "${FLUTTER_HOME}" "${ANDROID_HOME}"

ARG ENTRYPOINT_VERSION=1
RUN curl -sSL \
        "https://raw.githubusercontent.com/andarilhoz/gh-infra/master/github-runners/flutter-android/entrypoint.sh" \
        -o /entrypoint.sh \
    && chmod +x /entrypoint.sh

USER runner
WORKDIR ${RUNNER_HOME}

ENTRYPOINT ["/entrypoint.sh"]
