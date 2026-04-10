---
name: stitch-harden
description: Audit and harden converted components for production readiness — accessibility (ARIA, focus-visible, landmarks), interactive states (hover, active, disabled), semantic HTML, and screen reader support. Use after converting screens to components, when screens.md shows "component_converted" status, or when the user asks for accessibility hardening.
metadata:
  filePattern:
    - "src/components/*.tsx"
    - "src/layouts/*.tsx"
    - "src/pages/*.tsx"
    - ".stitch-claude/screens.md"
  bashPattern:
    - "stitch.harden|stitch-harden"
  priority: 70
  tags:
    - stitch
    - harden
    - a11y
    - accessibility
---

# stitch-harden — Accessibility & Interactive State Hardening

Audit and fix converted components for production readiness. This skill bridges the gap between "looks right" and "ships right."

---

## Pre-flight

1. **Read `references/hardening-checklist.md`** — the full audit checklist
2. **Read `.stitch-claude/screens.md`** — screens at `component_converted` status
3. **Read `.stitch-claude/components.md`** — component inventory with file paths

---

## Workflow

### Step 1: Identify Targets

Read `screens.md` and find screens at `component_converted` status.

For each screen, identify all related component files:
- The layout component (e.g., `src/layouts/DesktopHome.tsx`)
- The page component (e.g., `src/pages/HomePage.tsx`)
- Any screen-specific organisms/molecules created during conversion
- Shared components used by this screen (SideNav, BottomNav, etc.)

**Important**: Shared components (SideNav, BottomNav, FAB, TopNav, TopAppBar) should be hardened once, not per-screen. Track which shared components have been audited in `hardening-log.md`.

If the user specifies particular screens or components, audit only those.

### Step 2: Three-Pass Audit

For each component file, read it fully and run three passes:

#### Pass 1 — Quick Wins (check first, ~80% of issues)

1. **Icon-only buttons need `aria-label`**
   - Scan for `<button>` containing only `<Icon>` or SVG
   - Add `aria-label` describing the action

2. **Every interactive element needs `focus-visible`**
   - Check ALL `<button>`, `<a>`, `<input>`, `<select>`, clickable `<div>`
   - Add: `focus-visible:ring-2 focus-visible:ring-primary/50 focus-visible:outline-none`
   - Also ensure `hover:` and `active:scale-95` states

3. **Multiple `<nav>` need unique `aria-label`**
   - If the page has >1 `<nav>`, each must have a distinct `aria-label`

4. **Repeating items need `<ul>/<li>` with `role="list"`**
   - Look for `.map()` rendering lists
   - Wrap in `<ul role="list">` with `<li>` children

5. **Status indicators need `sr-only` text**
   - Colored dots, trend arrows, badges
   - Add `aria-hidden="true"` on visual element + `<span className="sr-only">` with meaning

#### Pass 2 — Widget Patterns

Scan for these specific patterns and apply the full ARIA treatment:

- **Toggle switches**: `role="switch"` + `aria-checked` + `aria-label`
- **Tab interfaces**: `role="tablist"` + `role="tab"` + `aria-selected` + `aria-controls` + `role="tabpanel"`
- **Radio groups** (theme selectors, filters): `<fieldset>` + `<legend>` + `role="radiogroup"` + hidden `<input type="radio">`
- **Dangerous action buttons**: `aria-describedby` linking to warning text

#### Pass 3 — Full Checklist

Run through every item in `references/hardening-checklist.md` Pass 3 section:
- Interactive element accessibility
- Focus & interactive states
- Navigation and `aria-current="page"`
- Form controls and labels
- Sections and heading hierarchy
- Semantic lists
- Data visualizations
- Status indicators and badges
- Touch targets (44×44px minimum on mobile)
- Images and media

### Step 3: Fix In-Place

For each issue found:
1. Fix directly in the component file using the Edit tool
2. Group fixes per component for efficiency
3. Don't change visual design or layout — hardening is the invisible layer

### Step 4: Record in Hardening Log

Update `.stitch-claude/hardening-log.md` with a new session entry:

```markdown
## Session: {today's date}

| Component | Fix | Category | Pass |
|-----------|-----|----------|------|
| FAB.tsx | Added `aria-label` prop | a11y | quick-win |
| BottomNav.tsx | Added `<ul role="list">` + `<li>` structure | semantic-html | quick-win |
| DesktopHome.tsx | Added `aria-labelledby` to sections | landmarks | full |
```

### Step 5: Update Screens

For each hardened screen:
1. **Update `screens.md`** — set status to `hardened`, update `Updated` column
2. If all screens for a page are hardened (both desktop + mobile), note this in the summary

### Step 6: Summary

Present the hardening summary table:

```markdown
## Component Hardening Summary

| Component | Fixes Applied | Category |
|-----------|--------------|----------|
| FAB.tsx | Added `aria-label` prop | a11y |
| BottomNav.tsx | Added `<ul role="list">` + `aria-current="page"` | landmarks |

### Before/After Highlight
[Show 1-2 most impactful changes with code snippets]

### Statistics
- Components audited: N
- Issues found: N
- Issues fixed: N
- Screens hardened: N
```

---

## What NOT to Do

- Don't add `aria-label` to elements with visible text (causes double-announcement)
- Don't add `role="button"` to `<button>` (already implicit)
- Don't wrap everything in landmarks (too many is as bad as none)
- Don't add `tabIndex={0}` to non-interactive elements
- Don't add redundant `aria-label` to `<label>` elements
- Don't change the visual design or layout
- Don't add loading/error states unless specifically requested

---

## Shared Component Strategy

These components appear in almost every screen. Harden them once:

| Component | Key Fixes |
|-----------|-----------|
| `SideNav` | `<nav aria-label="Main navigation">`, `<ul role="list">`, `aria-current="page"` on active, `focus-visible` on all links |
| `TopNav` | `<nav aria-label="Top navigation">`, search `role="search"` + `<label>`, `focus-visible` on all buttons |
| `BottomNav` | `<nav aria-label="Bottom navigation">`, `<ul role="list">`, `aria-current="page"`, 44px touch targets |
| `TopAppBar` | `<header>` wrapper, icon buttons get `aria-label`, `focus-visible` |
| `FAB` | `aria-label` describing action, `focus-visible:ring-2`, 44px minimum size |
| `Icon` | Ensure `aria-hidden="true"` when decorative (most cases) |

After hardening shared components once, note it in `hardening-log.md` so subsequent screen audits skip them.
