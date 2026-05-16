#!/usr/bin/env bash
# Downloads the Vazirmatn font files used by the FeedbackFlow Flutter client.
#
# Pulls the official release archive from
# https://github.com/rastikerdar/vazirmatn/releases and copies the TTF
# weights referenced in pubspec.yaml under assets/fonts/.
set -euo pipefail

VERSION="${1:-33.003}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST_DIR="${SCRIPT_DIR}/../assets/fonts"
mkdir -p "${DEST_DIR}"

WEIGHTS=("Regular" "Medium" "SemiBold" "Bold" "ExtraBold" "Black")

URL="https://github.com/rastikerdar/vazirmatn/releases/download/v${VERSION}/vazirmatn-v${VERSION}.zip"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

echo "Downloading Vazirmatn v${VERSION}..."
# -L follows redirects, --fail makes curl exit non-zero on HTTP errors so
# we don't silently pretend a 404 page is a zip.
curl -fL "${URL}" -o "${TMP_DIR}/vazirmatn.zip"
unzip -q "${TMP_DIR}/vazirmatn.zip" -d "${TMP_DIR}/extracted"

for weight in "${WEIGHTS[@]}"; do
    src="$(find "${TMP_DIR}/extracted" -name "Vazirmatn-${weight}.ttf" -print -quit)"
    if [[ -z "${src}" ]]; then
        echo "WARN: Vazirmatn-${weight}.ttf not found in archive." >&2
        continue
    fi
    cp "${src}" "${DEST_DIR}/Vazirmatn-${weight}.ttf"
    echo "  -> ${DEST_DIR}/Vazirmatn-${weight}.ttf"
done

echo "Done."
