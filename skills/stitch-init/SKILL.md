---
name: stitch-init
description: Initialize a project for the Stitch design-to-code pipeline — verify MCP connection, detect tech stack, create/link Stitch project, set up design system, create .stitch-claude/ tracking directory, and auto-discover existing assets. Use when starting a new Stitch project, onboarding an existing project, or when .stitch-claude/ doesn't exist yet.
metadata:
  filePattern:
    - ".stitch-project.json"
    - ".stitch-claude/project.md"
  bashPattern:
    - "stitch.init|stitch-init"
  priority: 80
  tags:
    - stitch
    - init
    - setup
---

# stitch-init — Project Initialization

Initialize a project for the Stitch design-to-code pipeline. This skill handles first-time setup and onboarding of existing projects.

---

## Pre-flight

1. **Read references** before proceeding:
   - `references/tracking-schema.md` — file formats for `.stitch-claude/`
   - `references/tech-stack-templates.md` — framework detection rules

---

## Workflow

### Step 1: Verify MCP Connection

Call `get_workspace_project` via stitch-mcp.

- **If it responds**: MCP is working. Note the current project link (if any).
- **If it fails/times out**: Instruct the user:
  ```
  Stitch MCP is not connected. Run:
  claude mcp add stitch-mcp -s user -e GOOGLE_CLOUD_PROJECT=stitch-96cd6 -- npx -y stitch-mcp-auto

  Then restart Claude Code and try again.
  See STITCH_SETUP.md for full setup instructions.
  ```
  Stop here — the rest of the pipeline requires MCP.

### Step 2: Detect Tech Stack

Use the heuristics from `references/tech-stack-templates.md`:

1. Check for framework config files (`next.config.*`, `nuxt.config.*`, `vite.config.*`, `svelte.config.*`)
2. Read `package.json` for framework + CSS + router dependencies
3. Determine the `techStack` value (e.g., `react-vite`, `react-nextjs`, `vue-nuxt`)
4. Note secondary deps (Tailwind, router, ORM, etc.)

### Step 3: Check / Create Stitch Project

**If `.stitch-project.json` exists:**
- Read it to get `projectId` and `projectName`
- Call `get_project` with that ID to verify it still exists in Stitch
- If the project was deleted in Stitch, inform user and offer to create a new one

**If `.stitch-project.json` does NOT exist:**
- Ask the user for a project name (suggest based on `package.json` name or directory name)
- Call `create_project` with the name
- Call `set_workspace_project` with the new project ID (this creates `.stitch-project.json`)

### Step 4: Create Asset Directories

Ensure these directories exist:
- `stitch-assets/screenshots/`
- `stitch-assets/html/`

Add to `.gitignore` if not already present:
```
# Stitch generated assets (large binary files)
# stitch-assets/screenshots/*.png
```

### Step 5: Check / Create Design System

1. Call `list_design_systems` for the project
2. **If a design system exists**: Note its ID and name
3. **If no design system exists**:
   - Ask the user for a design direction/vision (or use existing `design.md` if present)
   - Call `create_design_system` with the direction
4. **If `design.md` already exists**: Skip token export — design system is already local
5. **If `design.md` does NOT exist**:
   - Call `export_design_system` to get the design documentation
   - Call `generate_design_tokens` to get framework-specific tokens
   - Write `design.md` with the design system documentation
   - Integrate tokens into the project's CSS (e.g., Tailwind CSS variables in `src/index.css`)

### Step 6: Create `.stitch-claude/` Directory

Create the tracking directory with initial files following `references/tracking-schema.md`.

**`project.md`** — populate with detected metadata:
```markdown
# Project Metadata

| Key | Value |
|-----|-------|
| Project Name | {name from .stitch-project.json or user input} |
| Stitch Project ID | {project ID} |
| Tech Stack | {detected tech stack} |
| Framework | {framework name + version from package.json} |
| Bundler | {Vite/Webpack/Turbopack} |
| CSS | {Tailwind version or other} |
| Router | {React Router/Vue Router/file-based/etc} |
| Design System | {design system name} |
| Design System ID | {stitch design system ID or "local-only"} |
| Vision | {from design.md or user input} |
| Created | {today's date} |
| Updated | {today's date} |
```

**`screens.md`** — initialize with header (populated in Step 7 if existing project):
```markdown
# Screen Inventory

| Screen | Variant | Stitch ID | Status | HTML Asset | PNG Asset | Component | Updated |
|--------|---------|-----------|--------|------------|-----------|-----------|---------|

## Status Lifecycle
planned → generated_in_stitch → assets_pulled → component_converted → hardened

## Special Statuses
- **experimental**: Exists in Stitch canvas but not intended for this project build
- **skipped**: Intentionally not pulling/converting
```

**`components.md`** — initialize with sections (populated in Step 7):
```markdown
# Component Library

## Atoms
| Component | File | Used By | Created |
|-----------|------|---------|---------|

## Molecules
| Component | File | Used By | Created |
|-----------|------|---------|---------|

## Organisms
| Component | File | Used By | Created |
|-----------|------|---------|---------|

## Layouts
| Component | File | Screen | Variant | Created |
|-----------|------|--------|---------|---------|

## Pages
| Component | File | Route | Created |
|-----------|------|-------|---------|
```

**`design-system.md`** — initialize with current sync status
**`hardening-log.md`** — initialize with empty log

### Step 7: Scan Existing Assets (Existing Projects)

If this is an existing project with assets already in place:

1. **Scan `stitch-assets/html/`** — list all `.html` files
2. **Scan `stitch-assets/screenshots/`** — list all `.png` files
3. **Scan `src/pages/`** — list all page components
4. **Scan `src/layouts/`** — list all layout components
5. **Scan `src/components/`** — list all shared components

**Auto-detect screen status by matching assets:**

For each screenshot PNG, extract the screen name and variant from the filename pattern `{project}-{screen}-{variant}.png`:

| Has PNG | Has HTML | Has Layout Component | Status |
|---------|----------|---------------------|--------|
| Yes | Yes | Yes | `hardened` or `component_converted` |
| Yes | Yes | No | `assets_pulled` |
| Yes | No | No | `generated_in_stitch` |
| No | No | No | `planned` |

**Populate `screens.md`** with discovered screens and their statuses.

**Populate `components.md`** by categorizing existing components:
- Files in `src/components/` → classify as atoms, molecules, or organisms based on complexity (read each file briefly)
- Files in `src/layouts/` → layouts section
- Files in `src/pages/` → pages section

### Step 8: Summary

Present the initialized project state:
- Project name and Stitch ID
- Tech stack detected
- Design system status
- Number of screens discovered (by status)
- Number of components cataloged (by level)
- Recommended next action (e.g., "Run /stitch-generate to create new screens" or "Run /stitch-pull to fetch assets for generated screens")

---

## For Existing Kinetic Project

When running on the kinetic project specifically, expect to find:
- `.stitch-project.json` with project ID `projects/4629429685104421845`
- 15 HTML files and 28 PNG files in `stitch-assets/`
- 12 pages, 24 layouts, 16 components in `src/`
- `design.md` already present

The auto-discovery should produce a screens.md with:
- Screens with full HTML+PNG+layout → `component_converted` (pending hardening audit)
- Screens with PNG only (governance, notifications, swap, trade, wallet, onboarding) → `generated_in_stitch`
- Each screen should have desktop and mobile variants where both PNG files exist
