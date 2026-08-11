#!/usr/bin/env bash
#
# Trigger a GitHub Actions release deployment via repository_dispatch.
#
# Usage:
#   ./scripts/deploy.sh                # auto-increment patch from latest release
#   ./scripts/deploy.sh 1.2.0          # explicit version
#   DEPLOY_NO_AUTO=1 ./scripts/deploy.sh  # use the version from pubspec.yaml
#
# Requires the GH_DEPLOY_TOKEN environment variable (a fine-grained PAT
# with "Contents: Read and write" on the repo). Set it once with:
#   export GH_DEPLOY_TOKEN="<your-token>"
#
set -euo pipefail

REPO="${REPO:-charleskwame/Gamified-Quiz-Application}"
BRANCH="${BRANCH:-main}"
VERSION="${1:-}"

if [[ -z "${GH_DEPLOY_TOKEN:-}" ]]; then
  echo "Missing token. Set it first with:" >&2
  echo "  export GH_DEPLOY_TOKEN=\"<your-token>\"" >&2
  exit 1
fi

# --- Version resolution ------------------------------------------------------
# 1) positional arg -> explicit version
# 2) default        -> auto-increment the patch from the latest GitHub release
# 3) DEPLOY_NO_AUTO=1 -> fall back to the version in pubspec.yaml

if [[ -z "$VERSION" && "${DEPLOY_NO_AUTO:-0}" != "1" ]]; then
  LATEST="$(curl -fsS -H "Authorization: Bearer ${GH_DEPLOY_TOKEN}" \
    "https://api.github.com/repos/${REPO}/releases/latest" | jq -r '.tag_name // empty')"
  if [[ -n "$LATEST" ]]; then
    BASE="$(sed -E 's/^v//' <<< "$LATEST")"
    IFS='.' read -r MAJ MIN PAT <<< "$BASE"
    if [[ -n "$MAJ" && -n "$MIN" && -n "$PAT" ]]; then
      VERSION="${MAJ}.${MIN}.$((PAT+1))"
      echo "Auto-incrementing: ${LATEST} -> v${VERSION}"
    fi
  fi
fi
if [[ -z "$VERSION" ]]; then
  # Fall back to pubspec.yaml (e.g. "1.1.0+3" -> "1.1.0")
  VERSION="$(grep -m1 '^version:' pubspec.yaml | awk '{print $2}' | cut -d'+' -f1)"
fi
if [[ -z "$VERSION" ]]; then
  echo "Could not determine a version. Pass it explicitly (./scripts/deploy.sh 1.2.0)" >&2
  exit 1
fi

BUILD_NUMBER="$(awk -F. '{print ($1*10000)+($2*100)+$3}' <<< "$VERSION")"

payload="$(jq -n --arg v "$VERSION" --arg b "$BRANCH" --argjson bn "$BUILD_NUMBER" \
  '{event_type:"deploy", client_payload:{version:$v, buildNumber:$bn, branch:$b}}')"

curl -fsS -X POST \
  -H "Authorization: Bearer ${GH_DEPLOY_TOKEN}" \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "https://api.github.com/repos/${REPO}/dispatches" \
  -d "$payload"

echo ""
echo "Deployment triggered for ${REPO} (branch: ${BRANCH})"
[[ -n "$VERSION" ]] && echo "   Version: ${VERSION}"
echo "   Build number: ${BUILD_NUMBER}"
echo "   Watch it at: https://github.com/${REPO}/actions"
