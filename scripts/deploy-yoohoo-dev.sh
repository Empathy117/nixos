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

if [ -f "./flake.nix" ]; then
  echo "[deploy] building Nix-generated config (bsc-config-local)..."
  nix build .#bsc-config-local || echo "[deploy] warning: nix build .#bsc-config-local failed, continuing"

  if [ -d "./result" ] && [ -d "./bsc-service" ]; then
    echo "[deploy] syncing config to bsc-service/source-file/local"
    rm -rf ./bsc-service/source-file/local
    mkdir -p ./bsc-service/source-file/local
    cp -r ./result/* ./bsc-service/source-file/local/
  fi
fi

echo "[deploy] restarting systemd service: ${SERVICE_NAME}"
systemctl restart "${SERVICE_NAME}"
systemctl status "${SERVICE_NAME}" --no-pager || true

echo "[deploy] done."

