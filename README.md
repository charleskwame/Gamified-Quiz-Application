# gamified_quiz_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

## 🚀 Deployment (GitHub Release)

Build a signed Android **APK + App Bundle** and publish them as a GitHub Release with one command:

```powershell
# Windows (PowerShell)
.\scripts\deploy.ps1                      # uses the version from pubspec.yaml
.\scripts\deploy.ps1 -Version 1.2.0       # override the release version
```

```bash
# macOS / Linux / bash
./scripts/deploy.sh                       # or: ./scripts/deploy.sh 1.2.0
```

### How it works

- The script sends a `repository_dispatch` event (`event_type: "deploy"`) to GitHub.
- `.github/workflows/deploy.yml` listens for it, builds the release APK + AAB, and publishes a release tagged `v<version>` (e.g. `v1.1.0`).
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
