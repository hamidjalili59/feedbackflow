#!/usr/bin/env bash
# Installs / upgrades FeedbackFlow on a Linux host.
#
# Usage:
#   ./install.sh            # upgrade in place (assumes /opt/feedbackflow exists)
#   sudo ./install.sh init  # first-time bootstrap (creates user, dirs, service)
#
# This script is meant to be run from inside an extracted release bundle
# created by .github/workflows/release.yml. The bundle layout is:
#   feedbackflow-server     -> static binary
#   web/                    -> Flutter web build output
#   feedbackflow.service    -> systemd unit
#   .env.example            -> template environment file
#   install.sh              -> this script

set -euo pipefail

APP_USER="feedbackflow"
APP_DIR="/opt/feedbackflow"
RELEASES_DIR="${APP_DIR}/releases"
CURRENT_LINK="${APP_DIR}/current"
ENV_FILE="${APP_DIR}/.env"
SERVICE_NAME="feedbackflow"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

require_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "This step must run as root. Re-run with sudo." >&2
        exit 1
    fi
}

ensure_user() {
    if ! id -u "${APP_USER}" >/dev/null 2>&1; then
        useradd --system --home-dir "${APP_DIR}" --shell /usr/sbin/nologin \
            "${APP_USER}"
    fi
}

ensure_dirs() {
    install -d -o "${APP_USER}" -g "${APP_USER}" -m 0755 \
        "${APP_DIR}" "${RELEASES_DIR}"
}

ensure_env() {
    if [[ ! -f "${ENV_FILE}" ]]; then
        if [[ -f "${SCRIPT_DIR}/.env.example" ]]; then
            cp "${SCRIPT_DIR}/.env.example" "${ENV_FILE}"
        else
            : > "${ENV_FILE}"
        fi
        chown "${APP_USER}:${APP_USER}" "${ENV_FILE}"
        chmod 0600 "${ENV_FILE}"
        echo
        echo ">>> A new ${ENV_FILE} was created from .env.example."
        echo ">>> Edit it now and re-run this script:"
        echo ">>>   sudo nano ${ENV_FILE}"
        echo
    fi
}

install_release() {
    local timestamp
    timestamp="$(date +%Y%m%d-%H%M%S)"
    local target="${RELEASES_DIR}/${timestamp}"

    install -d -o "${APP_USER}" -g "${APP_USER}" -m 0755 "${target}"
    install -m 0755 -o "${APP_USER}" -g "${APP_USER}" \
        "${SCRIPT_DIR}/feedbackflow-server" "${target}/feedbackflow-server"
    if [[ -d "${SCRIPT_DIR}/web" ]]; then
        cp -r "${SCRIPT_DIR}/web" "${target}/web"
        chown -R "${APP_USER}:${APP_USER}" "${target}/web"
    fi

    ln -sfn "${target}" "${CURRENT_LINK}"
    chown -h "${APP_USER}:${APP_USER}" "${CURRENT_LINK}"

    # Keep the last 5 releases for rollback.
    ls -1dt "${RELEASES_DIR}"/* 2>/dev/null \
        | tail -n +6 | xargs -r rm -rf
}

install_service() {
    install -m 0644 "${SCRIPT_DIR}/feedbackflow.service" \
        "/etc/systemd/system/${SERVICE_NAME}.service"
    systemctl daemon-reload
    systemctl enable "${SERVICE_NAME}.service"
}

restart_service() {
    systemctl restart "${SERVICE_NAME}.service"
    sleep 1
    systemctl --no-pager --full status "${SERVICE_NAME}.service" || true
}

main() {
    local mode="${1:-upgrade}"
    require_root

    case "${mode}" in
        init|upgrade) ;;
        *)
            echo "Unknown mode: ${mode}" >&2
            echo "Usage: install.sh [init|upgrade]" >&2
            exit 1
            ;;
    esac

    ensure_user
    ensure_dirs
    ensure_env

    # Refuse to install or restart while .env still has placeholder values.
    if grep -qE 'change-me|STRONG_PASSWORD_HERE' "${ENV_FILE}"; then
        echo
        echo "============================================================"
        echo " ${ENV_FILE} still has placeholder values."
        echo " Edit it and re-run this script:"
        echo "   sudo nano ${ENV_FILE}"
        echo "   sudo ./install.sh"
        echo "============================================================"
        exit 1
    fi

    install_release
    install_service
    restart_service

    echo
    echo "Done. Tail logs with:  journalctl -u ${SERVICE_NAME} -f"
}

main "$@"
