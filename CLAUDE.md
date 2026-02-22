# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

Docker Compose–based infrastructure repository. Currently hosts self-hosted GitHub Actions runners.

## Commands

```bash
# Build runner images
docker compose build

# Start both runner containers
docker compose up -d

# Stop and deregister runners
docker compose down

# Upgrade Flutter version
docker compose build --build-arg FLUTTER_VERSION=3.x.x
```

## Architecture

```
github-runners/
  flutter-android/
    Dockerfile       # Ubuntu 22.04 + Android SDK + Flutter + GH Actions runner
    entrypoint.sh    # Registers runner on start, deregisters on stop
docker-compose.yml   # Two runner-1 / runner-2 services sharing pub_cache volume
.env.example         # Template for required secrets (copy to .env, never commit)
```

### Flutter/Android Runner

- **Image:** `flutter-android-runner:<FLUTTER_VERSION>`
- **Flutter version:** controlled by `FLUTTER_VERSION` build arg (default `3.41.1`)
- **Pub cache:** shared Docker volume (`pub_cache`) — survives image rebuilds
- **Runner labels:** `flutter`, `android`, `self-hosted`
- **Registration:** fine-grained PAT via `GITHUB_PAT` env var at runtime
