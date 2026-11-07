#!/usr/bin/env bash
set -euo pipefail
[[ "$RELEASE_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
[[ "$SOURCE_SHA" =~ ^[a-f0-9]{40}$ ]]
tag="v$RELEASE_VERSION"
if gh api "repos/$GITHUB_REPOSITORY/releases/tags/$tag" > "$RUNNER_TEMP/existing-release.json" 2>/dev/null; then
  python3 - "$RUNNER_TEMP/existing-release.json" <<'PY'
import json,sys
release=json.load(open(sys.argv[1]))
if release.get('draft') is not True or release.get('assets'):
    raise SystemExit('An existing published or nonempty release will not be overwritten')
PY
  gh release upload "$tag" distribution/Musify-Arabic.apk distribution/SHA256SUMS.txt --repo "$GITHUB_REPOSITORY"
  gh release edit "$tag" --draft=false --repo "$GITHUB_REPOSITORY"
else
  gh release create "$tag" distribution/Musify-Arabic.apk distribution/SHA256SUMS.txt --repo "$GITHUB_REPOSITORY" --target "$SOURCE_SHA" --title "Musify عربي $RELEASE_VERSION" --generate-notes
fi
