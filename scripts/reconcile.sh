#!/usr/bin/env bash
# reconcile.sh - Reconcile tracking state in screens.md with files on disk
#
# Compares the .stitch-claude/screens.md inventory against actual files in
# stitch-assets/ and src/ to find drift between tracked state and disk.
#
# Modes:
#   --dry-run  (default) Report discrepancies without modifying anything
#   --fix      Attempt to repair screens.md where possible
#
# Repairs (--fix only):
#   - Screens whose component file is missing but HTML/PNG assets exist:
#     status is set back to "assets_pulled" so the convert step can re-run.
#
# Exit codes:
#   0 - No discrepancies (or all fixed)
#   1 - Discrepancies found (dry-run) or unfixable issues remain
#
# Compatible with bash 3.2+ (macOS default). Avoids associative arrays.

set -euo pipefail

# ---------------------------------------------------------------------------
# Color helpers
# ---------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "  ${CYAN}INFO${NC}   $1"; }
ok()      { echo -e "  ${GREEN}OK${NC}     $1"; }
warning() { echo -e "  ${YELLOW}UNTRKD${NC} $1"; }
missing() { echo -e "  ${RED}MISS${NC}   $1"; }
fixed()   { echo -e "  ${GREEN}FIXED${NC}  $1"; }
header()  { echo -e "\n${BOLD}$1${NC}"; }

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------
FIX_MODE=false

for arg in "$@"; do
    case "$arg" in
        --fix)     FIX_MODE=true ;;
        --dry-run) FIX_MODE=false ;;
        -h|--help)
            echo "Usage: $(basename "$0") [--dry-run | --fix]"
            echo ""
            echo "  --dry-run  (default) Report discrepancies only"
            echo "  --fix      Attempt to repair screens.md where possible"
            exit 0
            ;;
        *)
            echo "Unknown argument: $arg" >&2
            echo "Usage: $(basename "$0") [--dry-run | --fix]" >&2
            exit 2
            ;;
    esac
done

# ---------------------------------------------------------------------------
# Determine project root
# ---------------------------------------------------------------------------
# Walk up from CWD looking for .stitch-claude/ or stitch-claude/ (some projects
# omit the leading dot). Prefer .stitch-claude/ when both exist.
find_project_root() {
    local dir="$PWD"
    while [[ "$dir" != "/" ]]; do
        if [[ -d "$dir/.stitch-claude" ]]; then
            echo "$dir"
            return 0
        fi
        if [[ -d "$dir/stitch-claude" ]]; then
            echo "$dir"
            return 0
        fi
        dir="$(dirname "$dir")"
    done
    echo "$PWD"
}

PROJECT_ROOT="$(find_project_root)"
# Prefer .stitch-claude/ but fall back to stitch-claude/
if [[ -d "$PROJECT_ROOT/.stitch-claude" ]]; then
    STITCH_DIR="$PROJECT_ROOT/.stitch-claude"
elif [[ -d "$PROJECT_ROOT/stitch-claude" ]]; then
    STITCH_DIR="$PROJECT_ROOT/stitch-claude"
else
    STITCH_DIR="$PROJECT_ROOT/.stitch-claude"
fi
SCREENS_FILE="$STITCH_DIR/screens.md"
HTML_DIR="$PROJECT_ROOT/stitch-assets/html"
PNG_DIR="$PROJECT_ROOT/stitch-assets/screenshots"

echo -e "${BOLD}Stitch Pipeline Reconciler${NC}"
echo "Project root: $PROJECT_ROOT"
if $FIX_MODE; then
    echo -e "Mode: ${YELLOW}fix${NC} (will modify screens.md)"
else
    echo -e "Mode: ${CYAN}dry-run${NC} (read-only)"
fi

# ---------------------------------------------------------------------------
# Pre-flight checks
# ---------------------------------------------------------------------------
if [[ ! -d "$STITCH_DIR" ]]; then
    echo -e "\n${RED}ERROR${NC} .stitch-claude/ not found at $STITCH_DIR"
    echo "Run stitch-init first to set up the tracking directory."
    exit 1
fi

if [[ ! -f "$SCREENS_FILE" ]]; then
    echo -e "\n${RED}ERROR${NC} screens.md not found at $SCREENS_FILE"
    exit 1
fi

# ---------------------------------------------------------------------------
# Temp files for tracked asset lists (portable alternative to associative arrays)
# ---------------------------------------------------------------------------
TMPDIR_RECONCILE=$(mktemp -d)
TRACKED_HTML_FILE="$TMPDIR_RECONCILE/tracked_html.txt"
TRACKED_PNG_FILE="$TMPDIR_RECONCILE/tracked_png.txt"
FIXABLE_FILE="$TMPDIR_RECONCILE/fixable.txt"

# Ensure cleanup on exit
cleanup() { rm -rf "$TMPDIR_RECONCILE"; }
trap cleanup EXIT

# Initialize temp files
touch "$TRACKED_HTML_FILE" "$TRACKED_PNG_FILE" "$FIXABLE_FILE"

# Helper: check if a value is in a file (one value per line)
is_tracked() {
    grep -qxF "$1" "$2" 2>/dev/null
}

tracked_count=0
untracked_count=0
missing_count=0
fixed_count=0
fixable_count=0

# ---------------------------------------------------------------------------
# Parse screens.md — build tracked sets and check for missing assets
# ---------------------------------------------------------------------------
header "Checking tracked screens against disk"

while IFS= read -r line; do
    # Skip non-table-data lines
    [[ -z "${line// /}" ]] && continue
    [[ "$line" =~ ^# ]] && continue
    [[ ! "$line" =~ ^\| ]] && continue
    [[ "$line" =~ ^\|[[:space:]]*Screen[[:space:]]*\| ]] && continue
    [[ "$line" =~ ^\|[-[:space:]\|]+\|$ ]] && continue

    tracked_count=$((tracked_count + 1))

    screen=$(echo "$line"  | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}')
    variant=$(echo "$line" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $3); print $3}')
    status=$(echo "$line"  | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $5); print $5}')
    html_asset=$(echo "$line" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $6); print $6}')
    png_asset=$(echo "$line"  | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $7); print $7}')
    component=$(echo "$line"  | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $8); print $8}')

    row_label="$screen ($variant)"

    # Record tracked HTML assets
    if [[ -n "$html_asset" && "$html_asset" != "-" && "$html_asset" != "—" ]]; then
        echo "$html_asset" >> "$TRACKED_HTML_FILE"
    fi

    # Record tracked PNG assets
    if [[ -n "$png_asset" && "$png_asset" != "-" && "$png_asset" != "—" ]]; then
        echo "$png_asset" >> "$TRACKED_PNG_FILE"
    fi

    # --- Check tracked HTML asset exists on disk ---
    if [[ -n "$html_asset" && "$html_asset" != "-" && "$html_asset" != "—" ]]; then
        if [[ ! -f "$HTML_DIR/$html_asset" && ! -f "$PROJECT_ROOT/stitch-assets/$html_asset" ]]; then
            missing "[$row_label] HTML asset missing from disk: $html_asset"
            missing_count=$((missing_count + 1))
        fi
    fi

    # --- Check tracked PNG asset exists on disk ---
    if [[ -n "$png_asset" && "$png_asset" != "-" && "$png_asset" != "—" ]]; then
        if [[ ! -f "$PNG_DIR/$png_asset" && ! -f "$PROJECT_ROOT/stitch-assets/$png_asset" ]]; then
            missing "[$row_label] PNG asset missing from disk: $png_asset"
            missing_count=$((missing_count + 1))
        fi
    fi

    # --- Check component file for component_converted / hardened ---
    if [[ "$status" == "component_converted" || "$status" == "hardened" ]]; then
        if [[ -n "$component" && "$component" != "-" && "$component" != "—" ]]; then
            comp_name=$(echo "$component" | awk -F'/' '{gsub(/^[ \t]+|[ \t]+$/, "", $1); print $1}')
            found_component=false

            if [[ -d "$PROJECT_ROOT/src" ]]; then
                # Search for component files matching the name
                match_count=$(find "$PROJECT_ROOT/src" -type f \( \
                    -name "${comp_name}.tsx" -o \
                    -name "${comp_name}.jsx" -o \
                    -name "${comp_name}.ts" -o \
                    -name "${comp_name}.js" -o \
                    -name "${comp_name}.vue" -o \
                    -name "${comp_name}.svelte" \
                \) 2>/dev/null | head -1 | wc -l)
                if [[ "$match_count" -gt 0 ]]; then
                    # Verify find actually returned a result (wc -l counts lines, head -1 may output empty)
                    first_match=$(find "$PROJECT_ROOT/src" -type f \( \
                        -name "${comp_name}.tsx" -o \
                        -name "${comp_name}.jsx" -o \
                        -name "${comp_name}.ts" -o \
                        -name "${comp_name}.js" -o \
                        -name "${comp_name}.vue" -o \
                        -name "${comp_name}.svelte" \
                    \) 2>/dev/null | head -1)
                    if [[ -n "$first_match" ]]; then
                        found_component=true
                    fi
                fi
            fi

            if ! $found_component; then
                missing "[$row_label] component '$comp_name' not found under src/"
                missing_count=$((missing_count + 1))

                # Check if this is fixable: assets still exist on disk
                has_assets=false
                if [[ -n "$html_asset" && "$html_asset" != "-" && "$html_asset" != "—" ]]; then
                    if [[ -f "$HTML_DIR/$html_asset" || -f "$PROJECT_ROOT/stitch-assets/$html_asset" ]]; then
                        has_assets=true
                    fi
                fi
                if [[ -n "$png_asset" && "$png_asset" != "-" && "$png_asset" != "—" ]]; then
                    if [[ -f "$PNG_DIR/$png_asset" || -f "$PROJECT_ROOT/stitch-assets/$png_asset" ]]; then
                        has_assets=true
                    fi
                fi

                if $has_assets; then
                    # Record fixable entry: screen|variant|old_status
                    echo "${screen}|${variant}|${status}" >> "$FIXABLE_FILE"
                    fixable_count=$((fixable_count + 1))
                fi
            fi
        fi
    fi

done < "$SCREENS_FILE"

# ---------------------------------------------------------------------------
# Scan disk for untracked HTML assets
# ---------------------------------------------------------------------------
header "Untracked HTML assets (on disk but not in screens.md)"

if [[ -d "$HTML_DIR" ]]; then
    found_untracked_html=false
    for file in "$HTML_DIR"/*.html; do
        # Handle the case where glob matches nothing
        [[ -e "$file" ]] || break
        basename_file="$(basename "$file")"
        if ! is_tracked "$basename_file" "$TRACKED_HTML_FILE"; then
            warning "$basename_file"
            untracked_count=$((untracked_count + 1))
            found_untracked_html=true
        fi
    done

    if ! $found_untracked_html; then
        ok "No untracked HTML assets"
    fi
else
    info "stitch-assets/html/ directory not found — skipping HTML scan"
fi

# ---------------------------------------------------------------------------
# Scan disk for untracked PNG assets
# ---------------------------------------------------------------------------
header "Untracked PNG assets (on disk but not in screens.md)"

if [[ -d "$PNG_DIR" ]]; then
    found_untracked_png=false
    for file in "$PNG_DIR"/*.png; do
        [[ -e "$file" ]] || break
        basename_file="$(basename "$file")"
        if ! is_tracked "$basename_file" "$TRACKED_PNG_FILE"; then
            warning "$basename_file"
            untracked_count=$((untracked_count + 1))
            found_untracked_png=true
        fi
    done

    if ! $found_untracked_png; then
        ok "No untracked PNG assets"
    fi
else
    info "stitch-assets/screenshots/ directory not found — skipping PNG scan"
fi

# ---------------------------------------------------------------------------
# Apply fixes (--fix mode only)
# ---------------------------------------------------------------------------
if $FIX_MODE && [[ -s "$FIXABLE_FILE" ]]; then
    header "Applying fixes"

    while IFS='|' read -r fix_screen fix_variant old_status; do
        screen_label="$fix_screen ($fix_variant)"

        # Use awk for a safe in-place update: match the row by screen name, variant,
        # and old status, then swap the status field to "assets_pulled".
        tmp_file="${SCREENS_FILE}.tmp"
        awk -F'|' -v screen="$fix_screen" -v variant="$fix_variant" -v old="$old_status" '
        BEGIN { OFS="|" }
        {
            # Trim fields for comparison
            s = $2; gsub(/^[ \t]+|[ \t]+$/, "", s);
            v = $3; gsub(/^[ \t]+|[ \t]+$/, "", v);
            st = $5; gsub(/^[ \t]+|[ \t]+$/, "", st);
            if (s == screen && v == variant && st == old) {
                gsub(old, "assets_pulled", $5);
            }
            print
        }
        ' "$SCREENS_FILE" > "$tmp_file" && mv "$tmp_file" "$SCREENS_FILE"

        fixed "[$screen_label] status changed from '$old_status' to 'assets_pulled'"
        fixed_count=$((fixed_count + 1))
    done < "$FIXABLE_FILE"

elif $FIX_MODE; then
    header "Applying fixes"
    info "Nothing to fix"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo -e "${BOLD}Summary:${NC}"
echo -e "  Tracked screens:    ${GREEN}${tracked_count}${NC}"
echo -e "  Untracked assets:   ${YELLOW}${untracked_count}${NC}"
echo -e "  Missing on disk:    ${RED}${missing_count}${NC}"
if $FIX_MODE; then
    echo -e "  Fixed:              ${GREEN}${fixed_count}${NC}"
fi

if (( untracked_count > 0 || missing_count > 0 )); then
    if ! $FIX_MODE && (( fixable_count > 0 )); then
        echo ""
        echo -e "${CYAN}Tip:${NC} Run with --fix to reset ${fixable_count} screen(s) with missing components back to 'assets_pulled'."
    fi
    exit 1
else
    exit 0
fi
