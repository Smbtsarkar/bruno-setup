#!/usr/bin/env bash
# sync.sh — install bruno-setup/framework/ into ~/.claude/, plus selected
#           user-home dotfiles (currently: .tmux.conf).
#
# Usage:
#   bash scripts/sync.sh           # backup existing + sync
#   DRY_RUN=1 bash scripts/sync.sh # show what would change without applying
#   NO_BACKUP=1 bash scripts/sync.sh # skip backups (faster; not recommended)

set -euo pipefail

# --- Locate repo root + framework source ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SRC="$REPO_ROOT/framework"
DEST="$HOME/.claude"

if [[ ! -d "$SRC" ]]; then
    echo "ERROR: framework source not found at $SRC" >&2
    exit 1
fi

# --- Deps ---
for cmd in rsync; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "ERROR: $cmd is required but not found in PATH." >&2
        echo "  On Windows: install Git for Windows (provides git-bash + rsync)" >&2
        echo "  On macOS:   rsync is pre-installed" >&2
        echo "  On Linux:   apt-get install rsync / dnf install rsync" >&2
        exit 1
    fi
done

# --- Backup existing ~/.claude/ + user-home dotfiles (unless NO_BACKUP=1) ---
TS=$(date +%Y%m%d-%H%M%S)
BACKUP_FILES=(
    "$DEST/CLAUDE.md"
    "$DEST/settings.json"
    "$HOME/.tmux.conf"
)
BACKUP_DIRS=(
    "$DEST/agents"
    "$DEST/docs"
    "$DEST/templates"
    "$DEST/hooks"
    "$DEST/themes"
)

if [[ -z "${NO_BACKUP:-}" ]]; then
    echo "[INFO] Backup timestamp: $TS"
    for f in "${BACKUP_FILES[@]}"; do
        if [[ -f "$f" ]]; then
            cp "$f" "$f.bak.$TS"
            echo "[INFO] Backed up: $f -> $f.bak.$TS"
        fi
    done
    for d in "${BACKUP_DIRS[@]}"; do
        if [[ -d "$d" ]]; then
            cp -r "$d" "$d.bak.$TS"
            echo "[INFO] Backed up: $d -> $d.bak.$TS"
        fi
    done
else
    echo "[WARN] NO_BACKUP=1 set; skipping backups."
fi

# --- Sync ---
RSYNC_OPTS=(-a --no-perms --chmod=ugo=rwX)
if [[ -n "${DRY_RUN:-}" ]]; then
    RSYNC_OPTS+=(--dry-run --itemize-changes)
    echo "[INFO] DRY_RUN=1: showing changes only (no files written)"
fi

mkdir -p "$DEST"

echo "[INFO] Syncing $SRC/ -> $DEST/"

# Top-level framework files (CLAUDE.md, settings.json, settings-README.md) — copy individually.
# Don't --delete at the top level: $DEST also contains runtime dirs (projects/, sessions/,
# cache/, plugins/, etc.) that the framework doesn't own and must not touch.
for f in CLAUDE.md settings.json settings-README.md; do
    if [[ -f "$SRC/$f" ]]; then
        rsync "${RSYNC_OPTS[@]}" "$SRC/$f" "$DEST/$f"
    fi
done

# Framework-owned subdirectories — sync WITH --delete so retired agents/hooks/docs
# get pruned from $DEST instead of accumulating as orphans. These dirs are 100%
# framework-owned; no Claude Code runtime files live under them.
DELETE_OPTS=("${RSYNC_OPTS[@]}" --delete)
for d in agents docs hooks templates commands; do
    if [[ -d "$SRC/$d" ]]; then
        mkdir -p "$DEST/$d"
        rsync "${DELETE_OPTS[@]}" "$SRC/$d/" "$DEST/$d/"
    fi
done

# themes/ — sync WITHOUT --delete. Framework ships a default set (e.g. midnight),
# but operators can drop their own theme JSONs in $DEST/themes/ — preserve those.
if [[ -d "$SRC/themes" ]]; then
    mkdir -p "$DEST/themes"
    rsync "${RSYNC_OPTS[@]}" "$SRC/themes/" "$DEST/themes/"
fi

# User-home dotfiles — currently just .tmux.conf. Add more here as needed.
if [[ -f "$SRC/.tmux.conf" ]]; then
    rsync "${RSYNC_OPTS[@]}" "$SRC/.tmux.conf" "$HOME/.tmux.conf"
    echo "[INFO] Synced: $SRC/.tmux.conf -> $HOME/.tmux.conf"
fi

if [[ -z "${DRY_RUN:-}" ]]; then
    # Also place base.json under templates/_settings/ (scaffolder expects it there)
    mkdir -p "$DEST/templates/_settings"
    cp "$SRC/settings.json" "$DEST/templates/_settings/base.json"
    echo "[INFO] Copied: $SRC/settings.json -> $DEST/templates/_settings/base.json (for scaffolder)"

    # Make all hook scripts executable
    find "$DEST/hooks" -name '*.sh' -exec chmod +x {} \;
    echo "[INFO] chmod +x on all hook scripts under $DEST/hooks/"
fi

# --- Verify ---
echo ""
echo "[INFO] Verification:"
[[ -f "$DEST/CLAUDE.md" ]] && echo "  OK $DEST/CLAUDE.md" || echo "  MISSING: $DEST/CLAUDE.md"
[[ -f "$DEST/settings.json" ]] && echo "  OK $DEST/settings.json" || echo "  MISSING: $DEST/settings.json"
[[ -d "$DEST/agents" ]] && echo "  OK $DEST/agents/ ($(ls "$DEST/agents" 2>/dev/null | wc -l) files)" || echo "  MISSING: $DEST/agents/"
[[ -d "$DEST/docs" ]] && echo "  OK $DEST/docs/ ($(ls "$DEST/docs" 2>/dev/null | wc -l) files)" || echo "  MISSING: $DEST/docs/"
[[ -d "$DEST/templates" ]] && echo "  OK $DEST/templates/" || echo "  MISSING: $DEST/templates/"
[[ -d "$DEST/hooks" ]] && echo "  OK $DEST/hooks/ ($(find "$DEST/hooks" -name '*.sh' 2>/dev/null | wc -l) scripts)" || echo "  MISSING: $DEST/hooks/"
[[ -d "$DEST/themes" ]] && echo "  OK $DEST/themes/ ($(ls "$DEST/themes" 2>/dev/null | wc -l) themes)" || echo "  MISSING: $DEST/themes/"
[[ -f "$HOME/.tmux.conf" ]] && echo "  OK $HOME/.tmux.conf" || echo "  MISSING: $HOME/.tmux.conf"

# Validate themes parse as JSON
if command -v node >/dev/null 2>&1 && [[ -d "$DEST/themes" ]]; then
    THEME_FAILS=0
    while IFS= read -r tf; do
        if ! node -e "JSON.parse(require('fs').readFileSync('$tf','utf8'))" 2>/dev/null; then
            echo "  FAIL $tf did not parse as JSON"
            THEME_FAILS=$((THEME_FAILS + 1))
        fi
    done < <(find "$DEST/themes" -maxdepth 1 -name '*.json' 2>/dev/null)
    [[ "$THEME_FAILS" -eq 0 ]] && echo "  OK All theme JSON files parse"
fi

# Validate JSON files parse
if command -v node >/dev/null 2>&1; then
    if node -e "JSON.parse(require('fs').readFileSync('$DEST/settings.json','utf8'))" 2>/dev/null; then
        echo "  OK $DEST/settings.json parses as JSON"
    else
        echo "  FAIL $DEST/settings.json did not parse"
    fi
fi

# Check hook scripts are syntactically valid
SYNTAX_FAILS=0
while IFS= read -r f; do
    if ! bash -n "$f" 2>/dev/null; then
        echo "  FAIL syntax error in: $f"
        SYNTAX_FAILS=$((SYNTAX_FAILS + 1))
    fi
done < <(find "$DEST/hooks" -name '*.sh' 2>/dev/null)
[[ "$SYNTAX_FAILS" -eq 0 ]] && echo "  OK All hook scripts pass bash -n"

echo ""
echo "[DONE] Restart any open Claude Code sessions to pick up the new settings + hooks."
echo ""
echo "[INFO] To undo: rename *.bak.$TS files back, e.g.:"
echo "       mv $DEST/CLAUDE.md.bak.$TS $DEST/CLAUDE.md"
