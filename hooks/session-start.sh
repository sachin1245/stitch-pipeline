#!/usr/bin/env bash
# Stitch Pipeline — SessionStart hook
# Detects .stitch-claude/ in the working directory and prints a one-line pipeline status.
# Silent in non-Stitch projects.

set -euo pipefail

STITCH_DIR=".stitch-claude"
SCREENS_FILE="${STITCH_DIR}/screens.md"

# Exit silently if no .stitch-claude/ directory
if [ ! -d "$STITCH_DIR" ]; then
  exit 0
fi

# Exit silently if no screens.md
if [ ! -f "$SCREENS_FILE" ]; then
  echo "Stitch Pipeline: .stitch-claude/ exists but screens.md is missing. Run /stitch-status to diagnose."
  exit 0
fi

# Count screens by status
planned=0
generated=0
pulled=0
converted=0
hardened=0
failed=0
skipped=0
total=0

while IFS='|' read -r _ screen variant stitch_id status rest; do
  # Skip header rows and separator
  status=$(echo "$status" | xargs 2>/dev/null || true)
  case "$status" in
    planned) planned=$((planned + 1)); total=$((total + 1)) ;;
    generated_in_stitch) generated=$((generated + 1)); total=$((total + 1)) ;;
    assets_pulled) pulled=$((pulled + 1)); total=$((total + 1)) ;;
    component_converted) converted=$((converted + 1)); total=$((total + 1)) ;;
    hardened) hardened=$((hardened + 1)); total=$((total + 1)) ;;
    failed_*) failed=$((failed + 1)); total=$((total + 1)) ;;
    skipped) skipped=$((skipped + 1)) ;;
  esac
done < "$SCREENS_FILE"

# Read project name if available
project_name=""
if [ -f "${STITCH_DIR}/project.md" ]; then
  project_name=$(grep -m1 '^| Project Name' "${STITCH_DIR}/project.md" 2>/dev/null | awk -F'|' '{print $3}' | xargs 2>/dev/null || true)
fi

# Build status line
if [ "$total" -eq 0 ] && [ "$skipped" -eq 0 ]; then
  echo "Stitch Pipeline: No screens tracked yet. Run /stitch-generate or /stitch-init to get started."
  exit 0
fi

name_prefix=""
if [ -n "$project_name" ]; then
  name_prefix="${project_name} — "
fi

parts=()
[ "$hardened" -gt 0 ] && parts+=("${hardened} hardened")
[ "$converted" -gt 0 ] && parts+=("${converted} converted")
[ "$pulled" -gt 0 ] && parts+=("${pulled} pulled")
[ "$generated" -gt 0 ] && parts+=("${generated} generated")
[ "$planned" -gt 0 ] && parts+=("${planned} planned")
[ "$failed" -gt 0 ] && parts+=("${failed} failed")

status_str=$(IFS=', '; echo "${parts[*]}")

echo "Stitch Pipeline: ${name_prefix}${total} screens (${status_str}). Use /stitch-status for full dashboard."
