#!/usr/bin/env bash
# Usage: verify_brick.sh <project_name> <responsive:true|false> [--key value ...]
#
# Materializes the brick into a throwaway Flutter project and verifies it:
#   flutter create -> mason init -> mason add (local) -> mason make (with hooks) ->
#   flutter analyze -> flutter test
#
# Prints VERIFY_OK on success (exit 0). Exits non-zero on any failure.
#
# CLI-flag notes (mason 0.1.3):
#   - Variables are passed via --config-path JSON, NOT as --var_name flags.
#   - mason add requires mason init first (no mason.yaml in a fresh flutter project).
#   - pre_gen.dart is now non-interactive (no prompt() calls); hooks run normally.
#   - post_gen.dart runs pub get / slang / build_runner headlessly.
#   - Extra --key value pairs override the defaults in the JSON config.
#   - ALL declared brick vars must appear in the JSON to prevent Mason from
#     interactively prompting for missing ones (fatal without a TTY).

set -euo pipefail

NAME="${1:?project_name required}"
RESPONSIVE="${2:?responsive (true|false) required}"
shift 2

# Parse extra --key value pairs into a simple list of "key=value" entries.
EXTRA_KEYS=()
EXTRA_VALS=()
while [[ $# -gt 0 ]]; do
  key="${1:?expected --key}"
  val="${2:?expected value after $key}"
  EXTRA_KEYS+=("${key#--}")
  EXTRA_VALS+=("$val")
  shift 2
done

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

# ── 3. Write vars config JSON ─────────────────────────────────────────────────
# Seed defaults for ALL declared brick vars so Mason never prompts interactively.
# These match the defaults in brick.yaml. Caller overrides take precedence.
_app_title=""
_seed_color="3F51B5"
_org="com.example"
_app_description=""
_author=""
_support_email=""
_privacy_url=""

# Apply overrides from extra --key value args.
for i in "${!EXTRA_KEYS[@]}"; do
  k="${EXTRA_KEYS[$i]}"
  v="${EXTRA_VALS[$i]}"
  case "$k" in
    app_title)       _app_title="$v" ;;
    seed_color)      _seed_color="$v" ;;
    org)             _org="$v" ;;
    app_description) _app_description="$v" ;;
    author)          _author="$v" ;;
    support_email)   _support_email="$v" ;;
    privacy_url)     _privacy_url="$v" ;;
    # project_name and responsive are positional args handled above; ignore here.
  esac
done

VARS_JSON="$WORK/.mason_vars.json"
cat > "$VARS_JSON" << VARS_EOF
{
  "project_name":    "$NAME",
  "app_title":       "$_app_title",
  "seed_color":      "$_seed_color",
  "org":             "$_org",
  "app_description": "$_app_description",
  "author":          "$_author",
  "support_email":   "$_support_email",
  "privacy_url":     "$_privacy_url",
  "responsive":      $RESPONSIVE
}
VARS_EOF

echo "=== vars JSON: $(cat "$VARS_JSON") ==="

# ── 4. Generate brick WITH hooks (pre_gen is now non-interactive) ─────────────
echo "=== mason make $BRICK_NAME ==="
mason make "$BRICK_NAME" \
  --config-path "$VARS_JSON" \
  --on-conflict overwrite

# ── 5. Verify ─────────────────────────────────────────────────────────────────
echo "=== flutter analyze ==="
flutter analyze

echo "=== flutter test ==="
flutter test

echo "WORKDIR=$WORK"
echo "VERIFY_OK"
