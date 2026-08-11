#!/usr/bin/env bash
#
# Trigger a GitHub Actions release deployment via repository_dispatch.
#
# Usage:
#   ./scripts/deploy.sh
#   ./scripts/deploy.sh 1.2.0
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

# Default version from pubspec.yaml (e.g. "1.1.0+3" -> "1.1.0")
if [[ -z "$VERSION" ]]; then
  VERSION="$(grep -m1 '^version:' pubspec.yaml | awk '{print $2}' | cut -d'+' -f1)"
fi

payload="$(jq -n --arg v "$VERSION" --arg b "$BRANCH" \
  '{event_type:"deploy", client_payload:{version:$v, branch:$b}}')"

curl -fsS -X POST \
  -H "Authorization: Bearer ${GH_DEPLOY_TOKEN}" \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "https://api.github.com/repos/${REPO}/dispatches" \
  -d "$payload"

echo ""
echo "Deployment triggered for ${REPO} (branch: ${BRANCH})"
[[ -n "$VERSION" ]] && echo "   Version: ${VERSION}"
echo "   Watch it at: https://github.com/${REPO}/actions"
