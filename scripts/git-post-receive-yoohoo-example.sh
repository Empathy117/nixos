#!/usr/bin/env bash
# 示例：用于 /srv/git/yoohoo.git/hooks/post-receive 的简易 CI/CD 钩子。
# 根据被推送的 main 分支更新工作目录并调用对应的 deploy 脚本。

set -euo pipefail

REPO_DIR="$(pwd)"

while read -r oldrev newrev ref; do
  case "${ref}" in
    refs/heads/main)
      ENV_NAME="main"
      ;;
    *)
      continue
      ;;
  esac

  WORKTREE="/srv/yoohoo/${ENV_NAME}"

  echo "[hook] update ${ENV_NAME} worktree at ${WORKTREE}"

  if [ ! -d "${WORKTREE}" ]; then
    mkdir -p "${WORKTREE}"
    git --work-tree="${WORKTREE}" --git-dir="${REPO_DIR}" checkout -f "${ENV_NAME}"
  else
    git --work-tree="${WORKTREE}" --git-dir="${REPO_DIR}" checkout -f "${ENV_NAME}"
  fi

  echo "[hook] calling deploy-yoohoo-${ENV_NAME}"
  sudo "/usr/local/bin/deploy-yoohoo-${ENV_NAME}.sh"
done
