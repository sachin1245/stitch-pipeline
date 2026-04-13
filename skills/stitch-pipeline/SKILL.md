---
name: stitch-pipeline
description: End-to-end Stitch design-to-code orchestrator — chains init, generate, pull, convert, and harden skills in sequence with user confirmation at each stage. Use to run the full pipeline from scratch, continue an interrupted pipeline, or process new screens through all stages.
metadata:
  filePattern:
    - ".stitch-claude/*"
    - ".stitch-project.json"
  bashPattern:
    - "stitch.pipeline|stitch-pipeline"
  priority: 100
  tags:
    - stitch
    - pipeline
    - orchestrator
---

# stitch-pipeline — End-to-End Orchestrator

Chains all pipeline skills in sequence: init → generate → pull → convert → harden. Confirms with the user at each stage transition (unless running in auto mode).

---

## Pre-flight

Determine the current project state by checking what exists:

| Check | Result |
|-------|--------|
| `.stitch-claude/` doesn't exist | Start from `stitch-init` |
| `.stitch-claude/` exists, screens at `planned` | Start from `stitch-generate` |
| `.stitch-claude/` exists, screens at `generated_in_stitch` | Start from `stitch-pull` |
| `.stitch-claude/` exists, screens at `assets_pulled` | Start from `stitch-convert` |
| `.stitch-claude/` exists, screens at `component_converted` | Start from `stitch-harden` |
| All screens `hardened` | Pipeline complete |
| `.stitch-claude/` exists, screens at `failed_generate` | Offer retry for failed screens, then continue from `stitch-generate` |
| `.stitch-claude/` exists, screens at `failed_pull` | Offer retry for failed screens, then continue from `stitch-pull` |
| `.stitch-claude/` exists, screens at `failed_convert` | Offer retry for failed screens, then continue from `stitch-convert` |
| `.stitch-claude/` exists, screens at `failed_harden` | Offer retry for failed screens, then continue from `stitch-harden` |
| Mixed statuses | Process earliest incomplete screens first |

---

## Pipeline Flow

```
Product Vision / Spec
        │
        ▼
 ┌──────────────┐
 │ stitch-init   │  Create project + design system + .stitch-claude/
 └──────┬───────┘
        │ ← User confirms screen list
        ▼
 ┌──────────────────┐
 │ stitch-generate   │  Generate screens in Stitch (desktop + mobile)
 └──────┬───────────┘  screens.md → "generated_in_stitch"
        │ ← User confirms generation results
        ▼
 ┌──────────────┐
 │ stitch-pull   │  Fetch HTML + PNG to stitch-assets/
 └──────┬───────┘  screens.md → "assets_pulled"
        │ ← User confirms assets look correct
        ▼
 ┌────────────────┐
 │ stitch-convert  │  Atomic decomposition → framework components
 └──────┬─────────┘  screens.md → "component_converted"
        │ ← User confirms components render correctly
        ▼
 ┌────────────────┐
 │ stitch-harden   │  A11y + interactive states + semantic HTML
 └──────┬─────────┘  screens.md → "hardened"
        │
        ▼
 ┌────────────────┐
 │ stitch-status   │  Final dashboard
 └────────────────┘
```

---

## Orchestration Modes

### Interactive Mode (default)

At each stage transition, pause and ask the user:
- Show what was just completed
- Show what the next step will do
- Ask for confirmation: "Continue to {next stage}? (y/n)"

This allows the user to:
- Review generated designs in Stitch before pulling
- Check pulled assets before converting
- Test converted components before hardening
- Provide additional instructions at each step

### Auto Mode

If the user says "run the full pipeline" or "auto mode":
- Execute all stages without pausing
- Still show progress at each stage
- Stop if any stage encounters an error

### Selective Mode

The user can specify which stages to run:
- "Run generate and pull" → only those two stages
- "Convert and harden the home screen" → only those stages for that screen
- "Skip hardening" → stop after convert

---

## Handling Mixed States

When screens are at different stages:

1. **Group screens by status**
2. **Process the earliest incomplete group first**
3. If the user wants to process a specific screen through the full pipeline, chain all remaining stages for just that screen

Example:
```
3 screens at generated_in_stitch → pull these first
2 screens at assets_pulled → convert these next
5 screens at component_converted → harden these last
```

---

## Stage Entry Points

Each skill is independently invocable. The orchestrator is optional — users can run any stage directly:

| Command | Action |
|---------|--------|
| `/stitch-init` | Initialize project (or re-scan existing) |
| `/stitch-generate` | Generate new screens |
| `/stitch-pull` | Pull assets for generated screens |
| `/stitch-convert` | Convert pulled assets to components |
| `/stitch-harden` | Harden converted components |
| `/stitch-status` | View progress dashboard |
| `/stitch-pipeline` | Run full pipeline (this skill) |

---

## Error Recovery

### When a stage fails

1. **Set the screen's status** to `failed_{stage}` (e.g., `failed_pull`, `failed_convert`)
2. **Record the error** in the `Error` column with a human-readable message
3. **Increment `Retries`** column (starts at 0)
4. **Do NOT advance** other screens' statuses — only the failed screen is affected
5. **Continue processing** remaining screens in the batch (one failure doesn't block others)

### On pipeline resume (startup with failed screens)

When the orchestrator detects `failed_*` statuses in screens.md:

1. **Group failed screens by stage** (e.g., 2 failed at pull, 1 failed at convert)
2. **Present to user:**
   ```
   Found failed screens:
   - 2 screens failed at pull: swap-desktop (MCP timeout), trade-mobile (MCP timeout)
   - 1 screen failed at convert: settings-desktop (missing SideNav import)

   Options:
   [r] Retry all failed screens
   [s] Skip failed screens (mark as skipped)
   [c] Choose per screen
   [i] Ignore and continue with other screens
   ```
3. **On retry**: Reset status to the stage's input status (e.g., `failed_pull` → `generated_in_stitch`), increment `Retries`, clear `Error`, attempt the stage again
4. **On skip**: Set status to `skipped`, preserve error in a note
5. **Max retries**: After 3 retries for the same screen at the same stage, recommend skipping

### Partial stage completion

When a stage processes multiple screens and some succeed while others fail:
- Succeeded screens advance normally
- Failed screens get `failed_{stage}` status
- The orchestrator reports: "5 of 7 screens pulled successfully. 2 failed (see /stitch-status)."
- The next stage processes only the successfully advanced screens

---

## New Project vs Existing Project

### New Project (no `.stitch-claude/`)
Full pipeline starting from scratch:
1. `stitch-init` — create project, design system, tracking
2. User provides screen list
3. `stitch-generate` — create all screens
4. `stitch-pull` — fetch all assets
5. `stitch-convert` — create all components
6. `stitch-harden` — audit everything

### Existing Project (has `.stitch-claude/`)
Resume from current state:
1. Check `stitch-status` to understand where things stand
2. Pick up from the earliest incomplete stage
3. Process new/changed screens through remaining stages
