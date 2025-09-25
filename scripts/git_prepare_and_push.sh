#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./git_prepare_and_push.sh <repo-name> [https|ssh] [github-username] [PAT]
# Defaults:
#   mode=https, username=kulwantgolan
# Examples:
#   ./git_prepare_and_push.sh kodekloudrag                   # HTTPS (will prompt unless PAT stored)
#   ./git_prepare_and_push.sh kodekloudrag https kulwantgolan MY_PAT_HERE
#   ./git_prepare_and_push.sh kodekloudrag ssh   kulwantgolan

REPO="${1:-}"
MODE="${2:-https}"                 # https | ssh
USER="${3:-kulwantgolan}"
# PAT="${4:-}"                       # only used for https
PAT="${GITHUB_PAT:?Please set GITHUB_PAT environment variable}"


if [[ -z "$REPO" ]]; then
  echo "Usage: $0 <repo-name> [https|ssh] [github-username] [PAT]" >&2
  exit 1
fi

echo "==> Using repo: $USER/$REPO over $MODE"

# 1) Git init
git init

# 2) .gitignore (only create if missing)
if [[ ! -f .gitignore ]]; then
cat > .gitignore <<'EOF'
__pycache__/
*.py[cod]
*.pyo
*.pyd
*.so
.python-version
venv/
.venv/
env/
*.log
.coverage
htmlcov/
.pytest_cache/
.mypy_cache/
.dmypy.json
.pyre/
.pytype/
build/
dist/
*.egg-info/
.vscode/
.idea/
.DS_Store
.aws/
.config/
.local/
.opencode/
.ssh/            
.cache/  
.launchpadlib/  
.npm/        
.terminal_logs/
EOF
  echo "==> Wrote .gitignore"
fi

# 3) Add files
git add -A

# Git identity (global, once on this machine)
git config --global user.email "${USER}@gmail.com"
git config --global user.name  "${USER}"

# 4) Commit
git commit -m "Initial commit" || true

# 5) Branch main
git branch -M main

# 6) Remote
if [[ "$MODE" == "ssh" ]]; then
  REMOTE_URL="git@github.com:${USER}/${REPO}.git"
else
  REMOTE_URL="https://github.com/${USER}/${REPO}.git"
fi
git remote set-url origin "$REMOTE_URL" 2>/dev/null || git remote add origin "$REMOTE_URL"
echo "==> Remote set to: $REMOTE_URL"

# 7) If HTTPS + PAT provided, store it (plaintext)
# if [[ "$MODE" == "https" && -n "$PAT" ]]; then
#  git config --global credential.helper store
#  printf "https://%s:%s@github.com\n" "$USER" "$PAT" > ~/.git-credentials
#  chmod 600 ~/.git-credentials || true
#  echo "==> Stored PAT in ~/.git-credentials"
# fi

# helper: mask PAT in logs
mask() { echo "$1" | sed -E 's/.{6}$/*******/'; }

# 7) If HTTPS + PAT provided, store it (plaintext, verified, then proceed)
if [[ "$MODE" == "https" && -n "${PAT:-}" ]]; then
  CRED_FILE="${HOME:-/root}/.git-credentials"
  CRED_DIR="$(dirname "$CRED_FILE")"
  mkdir -p "$CRED_DIR"

  # explicitly point credential.helper to this file
  git config --global credential.helper "store --file=${CRED_FILE}"

  TMP_FILE="$(mktemp "${CRED_DIR}/.git-credentials.tmp.XXXXXX")"
  printf "https://%s:%s@github.com\n" "$USER" "$PAT" > "$TMP_FILE"

  # lock down perms before moving into place
  chmod 600 "$TMP_FILE"
  mv -f "$TMP_FILE" "$CRED_FILE"

  # verify file exists, readable, and contains expected username
  if [[ ! -s "$CRED_FILE" ]] || ! grep -q "https://${USER}:" "$CRED_FILE"; then
    echo "❌ Failed to create credentials at: $CRED_FILE"
    echo "   Make sure HOME is set and the script has write permission to ${CRED_DIR}"
    exit 1
  fi

  echo "✅ Stored PAT in $(mask "$CRED_FILE") and configured credential.helper"
fi

# ensure these lines are present in your .gitignore
grep -qxF '.git-credentials' .gitignore || echo '.git-credentials' >> .gitignore
grep -qxF '*.credentials'    .gitignore || echo '*.credentials'    >> .gitignore


# 8) Push

if [[ "$MODE" == "https" ]]; then
  CRED_FILE="${HOME:-/root}/.git-credentials"
  if [[ ! -s "$CRED_FILE" ]]; then
    echo "❌ No credentials at ${CRED_FILE}. Not pushing."
    echo "   Provide PAT or run: git config --global credential.helper 'store --file=${CRED_FILE}'"
    echo "   then push once and enter username (kulwantgolan) + PAT to save."
    exit 1
  fi
fi

echo "==> Pushing main ..."
if git push -u origin main; then
  echo "==> Push succeeded."
else
  echo "!! Push failed."
  if [[ "$MODE" == "https" ]]; then
    echo "   - If prompted repeatedly, ensure PAT is valid and has 'repo' (classic) or 'Contents: Read & write' (fine-grained)."
    echo "   - To save PAT later: git config --global credential.helper store; then push and enter creds once."
  else
    echo "   - For SSH, ensure a key is added to GitHub and try: ssh -T git@github.com"
  fi
fi
