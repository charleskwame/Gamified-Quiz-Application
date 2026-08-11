# gamified_quiz_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

## 🚀 Deployment (GitHub Release)

Build a signed Android **APK + App Bundle** and publish them as a GitHub Release with one command:

```powershell
# Windows (PowerShell) — auto-increments the patch version each deployment
.\scripts\deploy.ps1                     # v1.1.0 -> v1.1.1 -> v1.1.2 ...
.\scripts\deploy.ps1 -Version 1.2.0      # explicit version
.\scripts\deploy.ps1 -NoAutoIncrement    # use the static version from pubspec.yaml
```

```bash
# macOS / Linux / bash
./scripts/deploy.sh                      # auto-increment
./scripts/deploy.sh 1.2.0                # explicit version
DEPLOY_NO_AUTO=1 ./scripts/deploy.sh     # use version from pubspec.yaml
```

### How it works

- The script sends a `repository_dispatch` event (`event_type: "deploy"`) to GitHub.
- **By default it auto-increments the patch version** from the latest GitHub release tag (e.g. `v1.1.0` → `v1.1.1`). Pass `-Version` (PowerShell) / a positional arg (bash) to pin a specific version, or `-NoAutoIncrement` / `DEPLOY_NO_AUTO=1` to fall back to `pubspec.yaml`.
- The version and an auto-derived build number are passed to the build via `--build-name`/`--build-number`, so the APK/AAB carry the deployed version.
- `.github/workflows/deploy.yml` listens for the event, builds the release APK + AAB, and publishes a release tagged `v<version>` (e.g. `v1.1.1`).
- Re-running with the same version updates the existing release instead of failing.

### One-time setup

1. Create a **fine-grained PAT** (Settings → Developer settings → Personal access tokens → Fine-grained tokens) with **Contents: Read and write** on this repo.
2. Add the token as `GH_DEPLOY_TOKEN` in your shell profile:
   ```powershell
   [Environment]::SetEnvironmentVariable("GH_DEPLOY_TOKEN", "<your-token>", "User")
   ```
3. Add these **repo secrets** (repo → Settings → Secrets and variables → Actions) so CI can sign the release build:
   | Secret | Value |
   |--------|-------|
   | `KEYSTORE_BASE64` | base64-encoded `upload-keystore.jks` |
   | `KEYSTORE_PASSWORD` | keystore password |
   | `KEY_ALIAS` | key alias |
   | `KEY_PASSWORD` | key password |

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
