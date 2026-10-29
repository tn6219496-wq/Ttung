#!/usr/bin/env bash
set -euo pipefail

# Usage: ./push.sh REPOSITORY_URL [BRANCH]
url=${1:-${GITHUB_REPO_URL:-}}
branch=${2:-main}
if [[ -z "$url" ]]; then
  echo 'Usage: ./push.sh <repository-url> [branch]' >&2
  exit 1
fi
# Do not accept embedded HTTPS credentials, which would be saved in .git/config.
if [[ "$url" =~ ^https?://[^/]*@ ]]; then
  echo 'Do not put credentials in the URL; use GitHub CLI or SSH.' >&2
  exit 1
fi
if [[ ! "$url" =~ ^https://github\.com/[^/]+/[^/]+/?$ && ! "$url" =~ ^git@github\.com:[^/]+/[^/]+/?$ && ! "$url" =~ ^ssh://git@github\.com/[^/]+/[^/]+/?$ ]]; then
  echo 'Use a GitHub HTTPS or SSH repository URL.' >&2
  exit 1
fi
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
git check-ref-format --branch "$branch" >/dev/null
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git init -b "$branch"
fi
# Do not accidentally operate on a parent repository.
root=$(git rev-parse --show-toplevel)
if [[ "$root" != "$(pwd -P)" ]]; then
  echo 'Project is inside another repository; refusing to modify its root.' >&2
  exit 1
fi
current=$(git symbolic-ref --quiet --short HEAD || true)
if [[ "$current" != "$branch" ]]; then
  echo "Current branch is '$current', not '$branch'; switch branches explicitly or pass the current branch." >&2
  exit 1
fi
if git remote get-url origin >/dev/null 2>&1; then
  existing=$(git remote get-url origin)
  if [[ "$existing" != "$url" ]]; then
    echo 'Existing origin differs from the supplied URL; refusing to change it.' >&2
    exit 1
  fi
else
  git remote add origin "$url"
fi
git add --all
if ! git diff --cached --quiet; then
  git commit -m 'Update project'
elif ! git rev-parse --verify HEAD >/dev/null 2>&1; then
  echo 'Nothing to commit.' >&2
  exit 1
fi
# Fail instead of prompting when credentials or host trust are missing.
GIT_TERMINAL_PROMPT=0 GIT_SSH_COMMAND="${GIT_SSH_COMMAND:-ssh -oBatchMode=yes}" \
  git push -u origin "$branch"
