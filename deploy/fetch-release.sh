#!/usr/bin/env bash
# Fetches a FeedbackFlow release artifact from GitHub Actions and installs it.
#
# Usage on the server:
#   sudo ./fetch-release.sh <run-id>           # latest run id from GitHub Actions
#   sudo ./fetch-release.sh tag v0.1.0         # by release tag (public release)
#
# Requires:
#   - gh CLI (https://cli.github.com/)
#   - GH_TOKEN environment variable or `gh auth login` already done
#   - GH_REPO=owner/repo environment variable (e.g. octocat/feedbackflow-server)

set -euo pipefail

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "${WORK_DIR}"' EXIT

if [[ -z "${GH_REPO:-}" ]]; then
    echo "Set GH_REPO to owner/repo before running." >&2
    exit 1
fi

mode="${1:-}"
case "${mode}" in
    "")
        echo "Usage: fetch-release.sh <run-id> | tag <version>" >&2
        exit 1
        ;;
    tag)
        version="${2:-}"
        if [[ -z "${version}" ]]; then
            echo "Tag mode requires a version, e.g. fetch-release.sh tag v0.1.0" >&2
            exit 1
        fi
        echo "Fetching release ${version} from ${GH_REPO}..."
        gh release download "${version}" \
            --repo "${GH_REPO}" \
            --pattern "feedbackflow-*.tar.gz" \
            --dir "${WORK_DIR}"
        ;;
    *)
        run_id="${mode}"
        echo "Fetching artifact 'feedbackflow-bundle' from run ${run_id}..."
        gh run download "${run_id}" \
            --repo "${GH_REPO}" \
            --name feedbackflow-bundle \
            --dir "${WORK_DIR}"
        ;;
esac

archive="$(find "${WORK_DIR}" -name 'feedbackflow-*.tar.gz' -print -quit)"
if [[ -z "${archive}" ]]; then
    echo "No archive found in download." >&2
    exit 1
fi

extract_dir="${WORK_DIR}/extracted"
mkdir -p "${extract_dir}"
tar -xzf "${archive}" -C "${extract_dir}"
chmod +x "${extract_dir}/install.sh"

# First-time bootstrap when /opt/feedbackflow does not exist.
if [[ -d /opt/feedbackflow/current ]]; then
    bash "${extract_dir}/install.sh" upgrade
else
    bash "${extract_dir}/install.sh" init
fi
