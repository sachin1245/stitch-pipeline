#!/usr/bin/env bash
# validate.sh - Validate .stitch-claude/ tracking files for common corruption
#
# Checks:
#   1. .stitch-claude/ directory existence
#   2. screens.md table integrity (column counts, status values, asset/component paths)
#   3. project.md existence and content
#
# Exit codes:
#   0 - All checks passed (warnings may be present)
#   1 - One or more errors found

set -euo pipefail

# ---------------------------------------------------------------------------
# Color helpers
# ---------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m' # No Color

pass_count=0
warn_count=0
error_count=0

pass()  { ((pass_count++));  echo -e "  ${GREEN}PASS${NC}  $1"; }
warn()  { ((warn_count++));  echo -e "  ${YELLOW}WARN${NC}  $1"; }
error() { ((error_count++)); echo -e "  ${RED}ERROR${NC} $1"; }
header() { echo -e "\n${BOLD}$1${NC}"; }

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
    # Fallback: use CWD
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
PROJECT_FILE="$STITCH_DIR/project.md"

# Valid status values for the pipeline lifecycle
VALID_STATUSES="planned|generated_in_stitch|assets_pulled|component_converted|hardened|experimental|skipped|failed_generate|failed_pull|failed_convert|failed_harden"

echo -e "${BOLD}Stitch Pipeline Validator${NC}"
echo "Project root: $PROJECT_ROOT"

# ---------------------------------------------------------------------------
# 1. Check .stitch-claude/ directory exists
# ---------------------------------------------------------------------------
header "1. Directory structure"

if [[ -d "$STITCH_DIR" ]]; then
    pass ".stitch-claude/ directory exists"
else
    error ".stitch-claude/ directory not found at $STITCH_DIR"
    # Cannot continue without the tracking directory
    echo ""
    echo -e "${BOLD}Summary:${NC} ${GREEN}${pass_count} passed${NC}, ${YELLOW}${warn_count} warnings${NC}, ${RED}${error_count} errors${NC}"
    exit 1
fi

# ---------------------------------------------------------------------------
# 2. Validate screens.md
# ---------------------------------------------------------------------------
header "2. screens.md validation"

if [[ ! -f "$SCREENS_FILE" ]]; then
    error "screens.md not found at $SCREENS_FILE"
else
    pass "screens.md exists"

    # Check file is not empty
    if [[ ! -s "$SCREENS_FILE" ]]; then
        error "screens.md is empty"
    else
        pass "screens.md has content"

        # Read data rows: skip blank lines, header row (starts with | Screen),
        # separator row (starts with |---), comment lines (starting with * or #),
        # and section headers (## ...)
        line_num=0
        data_row_count=0

        while IFS= read -r line; do
            ((line_num++))

            # Skip blank lines
            [[ -z "${line// /}" ]] && continue

            # Skip markdown headings
            [[ "$line" =~ ^#  ]] && continue

            # Skip non-table lines (footnotes, plain text)
            [[ ! "$line" =~ ^\| ]] && continue

            # Skip the header row
            [[ "$line" =~ ^\|[[:space:]]*Screen[[:space:]]*\| ]] && continue

            # Skip separator rows (|---|---|...)
            [[ "$line" =~ ^\|[-[:space:]\|]+\|$ ]] && continue

            # This should be a data row
            ((data_row_count++))

            # Count pipe-delimited columns.
            # A row like "| A | B | C | D |" has leading and trailing pipes,
            # so splitting on | gives empty first/last elements.
            # We count the fields between the outer pipes.
            col_count=$(echo "$line" | awk -F'|' '{print NF - 1}')

            # The table has 8 content columns (Screen, Variant, Stitch ID, Status,
            # HTML Asset, PNG Asset, Component, Updated) plus the outer pipes = 9 fields.
            # However, newer schemas may add Error and Retries columns (up to 10).
            # We require at least 8 columns (the leading empty counts as one field from
            # the split, so col_count = number of pipes minus 1). A row with 8 columns
            # between outer pipes gives col_count=9. Accept 8-11 to be flexible.
            if (( col_count < 8 )); then
                error "Line $line_num: expected at least 8 columns, found $col_count — $line"
            else
                pass "Line $line_num: column count OK ($col_count)"
            fi

            # Extract fields (trim whitespace)
            screen=$(echo "$line"  | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}')
            variant=$(echo "$line" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $3); print $3}')
            stitch_id=$(echo "$line" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $4); print $4}')
            status=$(echo "$line"  | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $5); print $5}')
            html_asset=$(echo "$line" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $6); print $6}')
            png_asset=$(echo "$line"  | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $7); print $7}')
            component=$(echo "$line"  | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $8); print $8}')

            row_label="$screen ($variant)"

            # --- Validate status value ---
            if [[ -n "$status" ]] && ! echo "$status" | grep -qE "^(${VALID_STATUSES})$"; then
                error "Line $line_num [$row_label]: invalid status '$status'"
            elif [[ -n "$status" ]]; then
                pass "Line $line_num [$row_label]: status '$status' is valid"
            fi

            # --- Stitch ID should not be empty/placeholder for non-planned screens ---
            if [[ "$status" != "planned" ]]; then
                if [[ -z "$stitch_id" || "$stitch_id" == "(none)" ]]; then
                    error "Line $line_num [$row_label]: status is '$status' but Stitch ID is empty or '(none)'"
                fi
            fi

            # --- HTML Asset file existence ---
            # Treat "-", em-dash, and empty as "no asset"
            if [[ -n "$html_asset" && "$html_asset" != "-" && "$html_asset" != "—" ]]; then
                # Check under stitch-assets/html/ first, then stitch-assets/ directly
                if [[ -f "$PROJECT_ROOT/stitch-assets/html/$html_asset" ]]; then
                    pass "Line $line_num [$row_label]: HTML asset exists (stitch-assets/html/$html_asset)"
                elif [[ -f "$PROJECT_ROOT/stitch-assets/$html_asset" ]]; then
                    pass "Line $line_num [$row_label]: HTML asset exists (stitch-assets/$html_asset)"
                else
                    warn "Line $line_num [$row_label]: HTML asset not found — $html_asset"
                fi
            fi

            # --- PNG Asset file existence ---
            if [[ -n "$png_asset" && "$png_asset" != "-" && "$png_asset" != "—" ]]; then
                if [[ -f "$PROJECT_ROOT/stitch-assets/screenshots/$png_asset" ]]; then
                    pass "Line $line_num [$row_label]: PNG asset exists (stitch-assets/screenshots/$png_asset)"
                elif [[ -f "$PROJECT_ROOT/stitch-assets/$png_asset" ]]; then
                    pass "Line $line_num [$row_label]: PNG asset exists (stitch-assets/$png_asset)"
                else
                    warn "Line $line_num [$row_label]: PNG asset not found — $png_asset"
                fi
            fi

            # --- Component file existence (for component_converted / hardened) ---
            if [[ "$status" == "component_converted" || "$status" == "hardened" ]]; then
                if [[ -n "$component" && "$component" != "-" && "$component" != "—" ]]; then
                    # Component field may be "ComponentName / PageName" — extract the
                    # first part as a rough path check, or look for any matching file.
                    # We check src/ for common patterns.
                    comp_name=$(echo "$component" | awk -F'/' '{gsub(/^[ \t]+|[ \t]+$/, "", $1); print $1}')
                    # Try to find a file matching the component name under src/
                    found_component=false
                    if [[ -d "$PROJECT_ROOT/src" ]]; then
                        # Search for files containing the component name (case-sensitive)
                        while IFS= read -r -d '' match; do
                            found_component=true
                            break
                        done < <(find "$PROJECT_ROOT/src" -type f \( -name "${comp_name}.tsx" -o -name "${comp_name}.jsx" -o -name "${comp_name}.ts" -o -name "${comp_name}.js" -o -name "${comp_name}.vue" -o -name "${comp_name}.svelte" \) -print0 2>/dev/null)
                    fi

                    if $found_component; then
                        pass "Line $line_num [$row_label]: component '$comp_name' found under src/"
                    else
                        warn "Line $line_num [$row_label]: component '$comp_name' not found under src/"
                    fi
                elif [[ "$component" == "-" || "$component" == "—" || -z "$component" ]]; then
                    warn "Line $line_num [$row_label]: status is '$status' but no component listed"
                fi
            fi

        done < "$SCREENS_FILE"

        if (( data_row_count == 0 )); then
            warn "screens.md has no data rows (only headers/comments)"
        else
            pass "screens.md contains $data_row_count data row(s)"
        fi
    fi
fi

# ---------------------------------------------------------------------------
# 3. Validate project.md
# ---------------------------------------------------------------------------
header "3. project.md validation"

if [[ ! -f "$PROJECT_FILE" ]]; then
    error "project.md not found at $PROJECT_FILE"
else
    pass "project.md exists"
    if [[ ! -s "$PROJECT_FILE" ]]; then
        error "project.md is empty (should contain project metadata)"
    else
        pass "project.md has content"
    fi
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo -e "${BOLD}Summary:${NC} ${GREEN}${pass_count} passed${NC}, ${YELLOW}${warn_count} warnings${NC}, ${RED}${error_count} errors${NC}"

if (( error_count > 0 )); then
    exit 1
else
    exit 0
fi
