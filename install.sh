#!/usr/bin/env bash
#
# remove-codecv-watermark - one-line installer
#
#   curl -fsSL https://raw.githubusercontent.com/liangkingjin/codecv-watermark-skill/main/install.sh | bash
#
set -euo pipefail

REPO="liangkingjin/codecv-watermark-skill"
BRANCH="main"
SKILL_NAME="remove-codecv-watermark"

# Candidate skill directories for AI coding tools.
CANDIDATES=(
  "$HOME/.workbuddy/skills"
  "$HOME/.claude/skills"
  "$HOME/.codebuddy/skills"
  "$HOME/.cursor/skills"
)

MODE="auto"        # auto | all
CUSTOM_DIRS=()
FORCE=0

usage() {
  cat <<'EOF'
Usage: install.sh [options]

Options:
  --all             Install to every supported tool's skill directory
  --dir <path>      Install to a custom skill directory (repeatable)
  --force           Overwrite an existing installation
  -h, --help        Show this help

Default behavior ("auto"): install into the skill directories that already
exist on this machine; if none exist, fall back to ~/.workbuddy/skills.
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --all) MODE="all"; shift ;;
    --dir) shift; [ $# -gt 0 ] || { echo "--dir requires a path" >&2; exit 1; }; CUSTOM_DIRS+=("$1"); shift ;;
    --force) FORCE=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
done

TMP_DIR="$(mktemp -d)"
cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

echo "==> Fetching $REPO@$BRANCH ..."
if command -v git >/dev/null 2>&1; then
  git clone --depth 1 --branch "$BRANCH" "https://github.com/$REPO.git" "$TMP_DIR/repo" >/dev/null 2>&1
  SRC="$TMP_DIR/repo/skill/$SKILL_NAME"
else
  curl -fsSL "https://codeload.github.com/$REPO/tar.gz/refs/heads/$BRANCH" -o "$TMP_DIR/repo.tar.gz"
  mkdir -p "$TMP_DIR/repo"
  tar -xzf "$TMP_DIR/repo.tar.gz" -C "$TMP_DIR/repo" --strip-components=1
  SRC="$TMP_DIR/repo/skill/$SKILL_NAME"
fi

if [ ! -f "$SRC/SKILL.md" ]; then
  echo "Error: skill files not found in the downloaded repository." >&2
  exit 1
fi

# Decide target directories.
TARGETS=()
if [ "$MODE" = "all" ]; then
  TARGETS=("${CANDIDATES[@]}")
else
  for d in "${CANDIDATES[@]}"; do
    [ -d "$d" ] && TARGETS+=("$d")
  done
  if [ ${#TARGETS[@]} -eq 0 ]; then
    TARGETS+=("$HOME/.workbuddy/skills")
  fi
fi
for d in "${CUSTOM_DIRS[@]:-}"; do
  [ -n "$d" ] && TARGETS+=("$d")
done

for dir in "${TARGETS[@]}"; do
  dest="$dir/$SKILL_NAME"
  if [ -d "$dest" ] && [ "$FORCE" -eq 0 ]; then
    echo "==> Skipped (already exists): $dest  (use --force to overwrite)"
    continue
  fi
  mkdir -p "$dir"
  rm -rf "$dest"
  cp -R "$SRC" "$dest"
  echo "==> Installed: $dest"
done

cat <<EOF

Done.

Next steps:
  1. Install the Python dependency:  pip install -r ${TARGETS[0]}/$SKILL_NAME/scripts/requirements.txt
  2. In your AI coding tool, say:
     "帮我去掉这份 CodeCV 简历的水印 @简历.pdf"

The skill triggers automatically on requests like "CodeCV 水印" / "简历去水印".
EOF
