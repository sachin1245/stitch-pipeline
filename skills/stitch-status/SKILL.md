---
name: stitch-status
description: Display the full Stitch pipeline dashboard — project metadata, screen inventory with lifecycle status, component library summary, design system sync status, and recommended next actions. Use to check pipeline progress, diagnose issues, or get an overview of the project state.
metadata:
  filePattern:
    - ".stitch-claude/project.md"
    - ".stitch-claude/screens.md"
    - ".stitch-claude/components.md"
  bashPattern:
    - "stitch.status|stitch-status"
  priority: 60
  tags:
    - stitch
    - status
    - dashboard
---

# stitch-status — Pipeline Progress Dashboard

Read all `.stitch-claude/` tracking files and present a comprehensive dashboard of the project's pipeline state.

---

## Workflow

### Step 1: Check for `.stitch-claude/`

If `.stitch-claude/` doesn't exist:
```
No Stitch pipeline tracking found in this project.
Run /stitch-init to set up the pipeline.
```

### Step 2: Read All Tracking Files

Read these files in parallel:
- `.stitch-claude/project.md`
- `.stitch-claude/screens.md`
- `.stitch-claude/components.md`
- `.stitch-claude/design-system.md`
- `.stitch-claude/hardening-log.md`

### Step 3: Present Dashboard

Format the output as a structured dashboard:

```markdown
## Stitch Pipeline — {Project Name}

### Project
| Key | Value |
|-----|-------|
| Stitch ID | {project ID} |
| Tech Stack | {tech stack} |
| Design System | {name} ({synced/not synced}) |
| Last Updated | {date} |

### Screen Inventory ({total} screens)

| Status | Count | Screens |
|--------|-------|---------|
| Hardened | N | home, markets, portfolio |
| Converted | N | settings |
| Pulled | N | yield |
| Generated | N | swap, trade |
| Planned | N | governance |
| Skipped | N | - |

### Screen Details

| Screen | Desktop | Mobile |
|--------|---------|--------|
| home | hardened | hardened |
| markets | hardened | hardened |
| swap | generated | generated |
| governance | planned | planned |

### Failed Screens ({count})

If any screens have `failed_*` status, show this section:

| Screen | Variant | Failed At | Error | Retries | Suggestion |
|--------|---------|-----------|-------|---------|------------|
| swap | desktop | pull | MCP timeout after 180s | 1 | Retry — likely transient |
| settings | desktop | convert | Missing SideNav import | 0 | Check src/components/SideNav.tsx exists |

Recovery suggestions by error type:
| Error Pattern | Suggestion |
|--------------|------------|
| MCP timeout | "Retry — likely transient network issue" |
| connection error | "Check Stitch MCP is running, retry" |
| compile error | "Check import paths and missing dependencies" |
| missing import | "Verify the referenced component file exists" |
| generation failed | "Try a simpler prompt, or switch model to GEMINI_3_1_PRO" |

### Component Library
| Level | Count | Components |
|-------|-------|------------|
| Atoms | N | Icon, Badge, ... |
| Molecules | N | MarketWatch, YieldCard, ... |
| Organisms | N | SideNav, TopNav, ... |
| Layouts | N | DesktopHome, MobileHome, ... |
| Pages | N | HomePage, MarketsPage, ... |

### Hardening Log
- Last session: {date}
- Total fixes applied: N
- Shared components hardened: {list}

### Pipeline Progress
[==========------] 62% (10/16 screens hardened)

### Recommended Next Action
{Based on current state, suggest the most impactful next step}
```

### Step 4: Recommend Next Action

Based on the current state, suggest the best next step:

| State | Recommendation |
|-------|---------------|
| Screens at `planned` | "Run /stitch-generate to create designs for {N} planned screens" |
| Screens at `generated_in_stitch` | "Run /stitch-pull to fetch assets for {N} generated screens" |
| Screens at `assets_pulled` | "Run /stitch-convert to create components for {N} pulled screens" |
| Screens at `component_converted` | "Run /stitch-harden to add a11y and interactive states to {N} converted screens" |
| All screens `hardened` | "Pipeline complete! All {N} screens are hardened and production-ready." |
| Mixed states | "Next priority: {earliest incomplete stage} for {screen names}" |
| Screens at `failed_*` | "Run /stitch-pipeline to retry {N} failed screens, or /stitch-status for details" |

---

## Quick Status (SessionStart Hook)

The SessionStart hook (`hooks/session-start.sh`) provides a condensed one-line status on every session start. The full `/stitch-status` provides the detailed dashboard.

---

## Troubleshooting

| Issue | Diagnosis |
|-------|-----------|
| `.stitch-claude/` exists but `screens.md` is empty | Project initialized but no screens planned/generated yet |
| Stitch IDs show `(none)` | Screens planned but not yet generated in Stitch |
| HTML/PNG paths show `-` | Screens generated but not yet pulled |
| Component paths show `-` | Screens pulled but not yet converted |
| Status stuck at `generated_in_stitch` | Pull may have failed — try `/stitch-pull` again |
| Counts don't match `stitch-assets/` files | Run `/stitch-init` to re-scan and reconcile |
