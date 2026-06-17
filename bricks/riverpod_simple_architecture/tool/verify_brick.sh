#!/usr/bin/env bash
# Usage: verify_brick.sh <project_name> <responsive:true|false> [extra mason flags...]
#
# Materializes the brick into a throwaway Flutter project and verifies it:
#   flutter create -> mason init -> mason add (local) -> mason make -> pub get ->
#   slang -> build_runner -> flutter analyze -> flutter test
#
# Prints VERIFY_OK on success (exit 0). Exits non-zero on any failure.
#
# CLI-flag notes (mason 0.1.3):
#   - Variables are passed via --config-path JSON, NOT as --var_name flags.
#   - mason add requires mason init first (no mason.yaml in a fresh flutter project).
#   - --responsive is included in the JSON config for when the brick declares it
#     (Task 6+). Before that, mason ignores undeclared vars gracefully.
#   - pre_gen.dart calls context.logger.prompt() which requires a TTY; we skip
#     hooks and run pub get / slang / build_runner manually to stay non-interactive.

set -euo pipefail

NAME="${1:?project_name required}"
RESPONSIVE="${2:?responsive (true|false) required}"
shift 2
EXTRA=("$@")

BRICK_DIR="$(cd "$(dirname "$0")/.." && pwd)"   # .../riverpod_simple_architecture
BRICK_NAME="$(basename "$BRICK_DIR")"            # riverpod_simple_architecture
WORK_PARENT="$(mktemp -d)"
WORK="$WORK_PARENT/$NAME"

echo "=== verify_brick: NAME=$NAME RESPONSIVE=$RESPONSIVE ==="
echo "=== BRICK_DIR=$BRICK_DIR ==="
echo "=== WORK=$WORK ==="

# ── 1. Create throwaway Flutter project ──────────────────────────────────────
echo "=== flutter create ==="
flutter create --org com.verify --project-name "$NAME" "$WORK" >/dev/null

cd "$WORK"

# ── 2. Initialise mason + register brick from local path ─────────────────────
echo "=== mason init ==="
mason init >/dev/null 2>&1

echo "=== mason add $BRICK_NAME --path $BRICK_DIR ==="
mason add "$BRICK_NAME" --path "$BRICK_DIR" >/dev/null 2>&1

# ── 3. Write vars config JSON (non-interactive; skips pre_gen TTY prompt) ────
VARS_JSON="$WORK/.mason_vars.json"
cat > "$VARS_JSON" << VARS_EOF
{
  "project_name": "$NAME",
  "responsive": $RESPONSIVE
}
VARS_EOF

# ── 4. Generate brick (skip hooks to avoid pre_gen TTY requirement) ──────────
echo "=== mason make $BRICK_NAME ==="
mason make "$BRICK_NAME" \
  --config-path "$VARS_JSON" \
  --on-conflict overwrite \
  --no-hooks \
  ${EXTRA[@]+"${EXTRA[@]}"}

# ── 5. Run post-gen steps manually (mirrors post_gen.dart behaviour) ─────────
# Remove pre-shipped generated files so build_runner can regenerate cleanly
for f in \
  lib/core/router/router.gr.dart \
  lib/i18n/strings.g.dart \
  lib/i18n/strings_en.g.dart \
  lib/i18n/strings_es.g.dart; do
  [ -f "$f" ] && rm "$f"
done

echo "=== flutter pub get ==="
flutter pub get

echo "=== dart run slang ==="
dart run slang

echo "=== dart run build_runner build ==="
dart run build_runner build

# ── 6. Verify ─────────────────────────────────────────────────────────────────
echo "=== flutter analyze ==="
flutter analyze

echo "=== flutter test ==="
flutter test

echo "WORKDIR=$WORK"
echo "VERIFY_OK"
