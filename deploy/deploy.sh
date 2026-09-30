#!/usr/bin/env bash
# deploy.sh — publish the built _site/ of hegoburu.com.ar_src to the
# GitHub Pages deployment repo (matiashegoburu.github.io).
#
# Usage:
#   bash deploy.sh --dry-run          # show what would be committed, no push
#   bash deploy.sh                    # full deploy: build, sync, commit, push
#   bash deploy.sh --skip-build       # deploy an existing _site/ (no rebuild)
#   bash deploy.sh --message "..."    # custom commit message
#
# Env (defaults match this machine):
#   SRC_REPO     source repo path (default: the repo containing this script)
#   DEP_REPO     deployment clone path (default: sibling .deploy/matiashegoburu.github.io)
#   DEP_REMOTE   deployment remote URL (default: https://github.com/matiashegoburu/matiashegoburu.github.io)

set -euo pipefail

SRC_REPO="$(cd "$(dirname "$0")/.." && pwd)"
DEP_REPO="${DEP_REPO:-$(dirname "$SRC_REPO")/.deploy/matiashegoburu.github.io}"
DEP_REMOTE="${DEP_REMOTE:-https://github.com/matiashegoburu/matiashegoburu.github.io}"
BRANCH="${DEP_BRANCH:-master}"

DRY_RUN=0
SKIP_BUILD=0
MSG="Deploy: retheme build $(date -u +%Y-%m-%d)"

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run)    DRY_RUN=1; shift ;;
    --skip-build) SKIP_BUILD=1; shift ;;
    --message)    MSG="$2"; shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

# Files in _site that are dev cruft and must NOT be published.
EXCLUDES=(AGENTS.md clases_raw.json workspace.code-workspace placeholder .hermes-tmp.3Aohsy)

echo "==> Source repo : $SRC_REPO"
echo "==> Deployment  : $DEP_REPO"
echo "==> Remote      : $DEP_REMOTE ($BRANCH)"
echo "==> Mode        : $([ $DRY_RUN -eq 1 ] && echo DRY-RUN || echo LIVE)  build=$([ $SKIP_BUILD -eq 1 ] && echo skip || echo yes)"
echo

# 1. Source repo must be clean-ish (only allow untracked scratch + jekyll cache).
cd "$SRC_REPO"
git fetch origin --quiet 2>/dev/null || true
STATUS=$(git status --porcelain)
TRACKED_CHANGES=$(echo "$STATUS" | grep -v '^??' | grep -v '^.M\t\.jekyll-cache' | grep -v '^.M\t_site' || true)
if [ -n "$TRACKED_CHANGES" ]; then
  echo "WARNING: source repo has uncommitted tracked changes (deploy will use the working tree):"
  echo "$TRACKED_CHANGES"
fi
# HEAD must be on a branch we consider deployable (master or a retheme branch).
BR=$(git rev-parse --abbrev-ref HEAD)
echo "==> Deploying from source branch: $BR"

# 2. Build (unless --skip-build).
SITE="$SRC_REPO/_site"
if [ $SKIP_BUILD -eq 0 ]; then
  echo "==> Building site (WSL Jekyll)..."
  # Portable WSL build (same command as AGENTS.md). Convert the Windows
  # path (whether C:\... or /c/...) to its /mnt/c/... form for WSL.
  rel="${SRC_REPO#C:\\Users}"          # if it was a native C:\ path
  rel="${rel#/c/Users}"               # if it was an MSYS /c/ path
  rel="${rel#/C/Users}"
  wsl_path="/mnt/c/Users$([ -n "$rel" ] && printf /$rel || true)"
  echo "    WSL path: $wsl_path"
  wsl.exe -d Ubuntu -- bash -lc "cd '$wsl_path' && unset BUNDLE_PATH BUNDLE_GEMFILE && rm -rf _site && timeout 300 bundle _2.2.26_ exec jekyll build" | tail -3
else
  echo "==> Skipping build (using existing _site/)"
fi

[ -d "$SITE" ] || { echo "ERROR: $SITE not found after build"; exit 1; }
[ -f "$SITE/index.html" ] || { echo "ERROR: no index.html in _site"; exit 1; }
[ -f "$SITE/CNAME" ] || { echo "ERROR: no CNAME in _site (required for GitHub Pages domain)"; exit 1; }

# 3. Clone / update the deployment repo.
mkdir -p "$(dirname "$DEP_REPO")"
if [ ! -d "$DEP_REPO/.git" ]; then
  echo "==> Cloning deployment repo..."
  ok=0
  for i in 1 2 3; do
    if git clone --quiet --branch "$BRANCH" "$DEP_REMOTE" "$DEP_REPO"; then ok=1; break; fi
    echo "    clone attempt $i failed, retrying..."
    rm -rf "$DEP_REPO"; sleep 3
  done
  [ $ok -eq 1 ] || { echo "ERROR: could not clone deployment repo after 3 tries"; exit 1; }
fi
cd "$DEP_REPO"
git remote set-url origin "$DEP_REMOTE"
git checkout -q "$BRANCH"
git fetch origin --quiet
git reset --hard "origin/$BRANCH"
# Drop any local cruft (e.g. the stray workflow_data folder) so the tree matches _site exactly.

# 4. Mirror _site into the deployment repo.
#    Use rsync-like semantics via a clean-and-copy approach (no rsync on Windows).
#    Remove all tracked content except .git, then copy _site contents (minus excludes).
echo "==> Syncing _site -> deployment repo..."
# Remove everything except .git
find "$DEP_REPO" -mindepth 1 -maxdepth 1 ! -name ".git" -exec rm -rf {} +
# Copy _site contents (top-level items only; subdirs come with -r)
for item in "$SITE"/* "$SITE"/.[!.]* "$SITE"/..?*; do
  [ -e "$item" ] || continue
  base="$(basename "$item")"
  skip=0
  for ex in "${EXCLUDES[@]}"; do
    [ "$base" = "$ex" ] && skip=1 && break
  done
  [ $skip -eq 1 ] && { echo "    excluding: $base"; continue; }
  cp -r "$item" "$DEP_REPO/"
done
# Ensure .nojekyll (GitHub Pages must NOT re-run Jekyll on the output).
touch "$DEP_REPO/.nojekyll"

# 5. Stage + report the diff.
git add -A
CHANGED=$(git status --porcelain | wc -l)
echo
echo "==> Deployment tree ready. Files changed: $CHANGED"
if [ $DRY_RUN -eq 1 ]; then
  echo "==> DRY-RUN: showing what would be committed (no push)."
  git status --short | head -60
  echo "    ... ($CHANGED total changed entries)"
  echo "==> Done (dry-run). Re-run without --dry-run to push."
  exit 0
fi

# 6. Commit + push.
if [ $CHANGED -eq 0 ]; then
  echo "==> No changes to deploy (deployment already matches _site)."
  exit 0
fi
git -c user.email="matias@hegoburu.com.ar" -c user.name="Matias Hegoburu" commit -q -m "$MSG"
echo "==> Pushing to $DEP_REMOTE ($BRANCH)..."
git push origin "$BRANCH" 2>&1 | tail -5
echo
echo "==> Deploy complete. GitHub Pages will publish within ~1 minute."
echo "    https://matias.hegoburu.com.ar"
