#!/usr/bin/env bash
set -euo pipefail

ENV_NAME="dev"
WORKTREE="/srv/yoohoo/${ENV_NAME}"
SERVICE_NAME="yoohoo-bsc-${ENV_NAME}"

echo "[deploy] updating worktree: ${WORKTREE}"

if [ ! -d "${WORKTREE}" ]; then
  echo "ERROR: worktree ${WORKTREE} does not exist" >&2
  exit 1
fi

cd "${WORKTREE}"

echo "[deploy] restarting systemd service: ${SERVICE_NAME}"
systemctl restart "${SERVICE_NAME}"
systemctl status "${SERVICE_NAME}" --no-pager || true

echo "[deploy] done."
