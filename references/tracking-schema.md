# .stitch-claude/ Tracking Schema

All `.stitch-claude/` files use markdown tables with pipe-delimited columns. Skills must read the full file, parse the table, update rows, and write the entire file back. Never use partial edits on markdown tables.

---

## project.md

Stores project metadata. Single key-value table.

```markdown
# Project Metadata

| Key | Value |
|-----|-------|
| Project Name | Kinetic Precision |
| Stitch Project ID | projects/4629429685104421845 |
| Tech Stack | react-vite |
| Framework | React 19 |
| Bundler | Vite 8 |
| CSS | Tailwind CSS v4 |
| Router | React Router DOM |
| Design System | Kinetic Precision |
| Design System ID | (stitch design system ID) |
| Vision | Crypto analytics dashboard with premium dark UI |
| Components Dir | src/components |
| Layouts Dir | src/layouts |
| Pages Dir | src/pages |
| Hooks Dir | src/hooks |
| Styles Entry | src/index.css |
| Route File | src/App.tsx |
| Created | 2026-04-03 |
| Updated | 2026-04-03 |
```

### Project Directory Keys

These are auto-detected during `stitch-init` based on the tech stack. Skills should read these values from `project.md` instead of hardcoding paths.

| Key | react-vite | react-nextjs | vue-vite | vue-nuxt | svelte-kit |
|-----|-----------|-------------|---------|---------|-----------|
| Components Dir | `src/components` | `components` | `src/components` | `components` | `src/lib/components` |
| Layouts Dir | `src/layouts` | `app` (via layout.tsx) | `src/layouts` | `layouts` | `src/lib/layouts` |
| Pages Dir | `src/pages` | `app` (via page.tsx) | `src/pages` | `pages` | `src/routes` |
| Hooks Dir | `src/hooks` | `hooks` | `src/composables` | `composables` | `src/lib/stores` |
| Styles Entry | `src/index.css` | `app/globals.css` | `src/style.css` | `assets/css/main.css` | `src/app.css` |
| Route File | `src/App.tsx` | (file-based) | `src/router/index.ts` | (file-based) | (file-based) |

### Tech Stack Values

| Value | Detection | Meaning |
|-------|-----------|---------|
| `react-vite` | `vite.config.*` + react in deps | React + Vite SPA |
| `react-nextjs` | `next.config.*` | Next.js App Router |
| `vue-vite` | `vite.config.*` + vue in deps | Vue + Vite SPA |
| `vue-nuxt` | `nuxt.config.*` | Nuxt 3 |
| `svelte-kit` | `svelte.config.*` | SvelteKit |
| `static` | None of the above | Plain HTML/CSS/JS |

---

## screens.md

Tracks every screen through its lifecycle. One row per screen+variant combination.

```markdown
# Screen Inventory

| Screen | Variant | Stitch ID | Status | HTML Asset | PNG Asset | Component | Error | Retries | Updated |
|--------|---------|-----------|--------|------------|-----------|-----------|-------|---------|---------|
| home | desktop | f7b073... | hardened | html/kinetic-home-desktop.html | screenshots/kinetic-home-desktop.png | layouts/DesktopHome.tsx | - | 0 | 2026-04-03 |
| swap | desktop | 7750b4... | failed_pull | - | - | - | MCP timeout after 180s | 1 | 2026-04-03 |

## Status Lifecycle
planned → generated_in_stitch → assets_pulled → component_converted → hardened

## Failure Statuses
- **failed_generate**: Generation failed in Stitch (MCP timeout, API error)
- **failed_pull**: Asset fetch failed (network error, screen deleted)
- **failed_convert**: Component conversion failed (missing imports, compile error)
- **failed_harden**: Accessibility hardening failed (file not found, JSX syntax error)

On retry, a `failed_*` status resets to the stage's input status (e.g., `failed_pull` → `generated_in_stitch`).

## Special Statuses
- **experimental**: Exists in Stitch canvas but not intended for this project build
- **skipped**: Intentionally not pulling/converting (e.g., superseded by another design)
```

### Column Definitions

| Column | Type | Description |
|--------|------|-------------|
| Screen | string | Screen name in kebab-case (e.g., `home`, `advanced-insights`) |
| Variant | `desktop` or `mobile` | Responsive variant |
| Stitch ID | string or `(none)` | Stitch screen ID from API response. `(none)` if not yet generated |
| Status | enum | Current lifecycle status (see below) |
| HTML Asset | path or `-` | Relative path from project root to HTML file, or `-` if not pulled |
| PNG Asset | path or `-` | Relative path from project root to PNG file, or `-` if not pulled |
| Component | path or `-` | Relative path from `src/` to the component file, or `-` if not created |
| Error | string or `-` | Human-readable error message on failure, `-` on success |
| Retries | integer | Number of retry attempts for current stage (starts at 0) |
| Updated | date | ISO date (YYYY-MM-DD) of last status change |

### Status Enum

| Status | Meaning |
|--------|---------|
| `planned` | Screen identified but not yet generated in Stitch |
| `generated_in_stitch` | Screen exists in Stitch, has a Stitch ID |
| `assets_pulled` | HTML and/or PNG fetched to local `stitch-assets/` |
| `component_converted` | React/Vue/Svelte component created from assets |
| `hardened` | Component passed accessibility and interactivity audit |
| `failed_generate` | Generation failed — check Error column for details |
| `failed_pull` | Asset fetch failed — check Error column for details |
| `failed_convert` | Conversion failed — check Error column for details |
| `failed_harden` | Hardening failed — check Error column for details |
| `experimental` | Exists in Stitch but not targeted for build |
| `skipped` | Intentionally excluded from pipeline |

---

## components.md

Tracks the component library organized by atomic design level.

```markdown
# Component Library

## Atoms
| Component | File | Used By | Created |
|-----------|------|---------|---------|
| Icon | components/Icon.tsx | SideNav, BottomNav, TopNav | 2026-04-03 |

## Molecules
| Component | File | Used By | Created |
|-----------|------|---------|---------|
| MarketWatch | components/MarketWatch.tsx | DesktopHome, MobileHome | 2026-04-03 |

## Organisms
| Component | File | Used By | Created |
|-----------|------|---------|---------|
| SideNav | components/SideNav.tsx | All Desktop layouts | 2026-04-03 |

## Layouts
| Component | File | Screen | Variant | Created |
|-----------|------|--------|---------|---------|
| DesktopHome | layouts/DesktopHome.tsx | home | desktop | 2026-04-03 |

## Pages
| Component | File | Route | Created |
|-----------|------|-------|---------|
| HomePage | pages/HomePage.tsx | /home | 2026-04-03 |
```

---

## design-system.md

Tracks design system synchronization between Stitch and the local project.

```markdown
# Design System Sync

| Key | Value |
|-----|-------|
| Stitch Design System ID | (ID from list_design_systems) |
| Local Token File | src/index.css |
| Design Doc | design.md |
| Last Synced | 2026-04-03 |
| Token Format | Tailwind CSS v4 @theme variables |

## Token Mapping Status
| Token Category | Stitch | Local | Synced |
|---------------|--------|-------|--------|
| Colors | 24 tokens | 24 vars | Yes |
| Typography | 3 families | 3 families | Yes |
| Spacing | 8 steps | Tailwind default | Partial |
| Radii | 4 values | 4 values | Yes |
```

---

## hardening-log.md

Records all accessibility and interactivity fixes applied during hardening.

```markdown
# Hardening Log

## Session: 2026-04-03

| Component | Fix | Category | Pass |
|-----------|-----|----------|------|
| FAB.tsx | Added `aria-label` prop | a11y | quick-win |
| BottomNav.tsx | Added `<ul role="list">` + `<li>` structure | semantic-html | quick-win |
| SideNav.tsx | Added `aria-current="page"` to active link | navigation | quick-win |
```

---

## Parsing Rules for Skills

1. **Read the full file** with the Read tool
2. **Parse tables** by splitting on `|` — trim whitespace from each cell
3. **Skip header and separator rows** (rows containing `---` or column names)
4. **Update in-place** — modify the relevant cells, keep all other rows intact
5. **Write the full file** back with the Write tool
6. **Always update the `Updated` column** when changing a row's status
7. **Use today's date** in ISO format (YYYY-MM-DD)
8. **Preserve table alignment** — use consistent column widths where practical
