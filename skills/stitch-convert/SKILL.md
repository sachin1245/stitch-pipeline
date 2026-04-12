---
name: stitch-convert
description: Convert Stitch HTML/PNG assets into framework components using atomic design decomposition — creates atoms, molecules, organisms, layouts, and pages following project patterns and design system tokens. Use after pulling assets from Stitch, when screens.md shows screens at "assets_pulled" status, or when the user wants to implement a specific screen.
metadata:
  filePattern:
    - "stitch-assets/html/*.html"
    - "stitch-assets/screenshots/*.png"
    - "src/layouts/*"
    - "src/pages/*"
    - ".stitch-claude/screens.md"
  bashPattern:
    - "stitch.convert|stitch-convert"
  priority: 90
  tags:
    - stitch
    - convert
    - components
    - atomic-design
---

# stitch-convert — Assets to Framework Components

The core conversion skill — transforms Stitch HTML/PNG assets into production framework components using atomic design decomposition.

---

## Pre-flight

1. **Read references**:
   - `references/atomic-design.md` — decomposition rules
   - `references/tech-stack-templates.md` — framework-specific patterns
2. **Read `.stitch-claude/project.md`** — tech stack, framework, design system
3. **Read `.stitch-claude/screens.md`** — screens at `assets_pulled` status
4. **Read `.stitch-claude/components.md`** — existing component library (avoid duplicates)
5. **Read `design.md`** — design system rules (colors, typography, no-line rule, surfaces)
6. **Read project's CLAUDE.md** — project-specific patterns and conventions

---

## Workflow

### Step 1: Select Screens

Identify screens at `assets_pulled` status in `screens.md`.

If the user specifies a screen, convert only that one. Otherwise, process screens in order (usually desktop variant first, then mobile).

### Step 2: Analyze Assets

For each screen to convert:

1. **Read the HTML** from `stitch-assets/html/{name}.html`
   - If rich HTML (200+ lines): Parse the structure — identify sections, components, layout grid
   - If stub HTML (<50 lines): Note that PNG is the primary reference

2. **Read the PNG** from `stitch-assets/screenshots/{name}.png`
   - Use as visual reference for layout, spacing, colors, component placement
   - This is always available and always the ground truth for visual design

3. **Check for downloaded image assets** — `stitch-assets/images/{screen-name}-image-map.json`
   - If this file exists, load the URL→local path mapping
   - During conversion, replace any `lh3.googleusercontent.com/aida-public/` `src` URLs with their `local` path from the map
   - Convert `data-alt` attributes to proper `alt` attributes using the `alt` field from the map
   - If no map exists but the HTML contains remote image URLs, use the remote URL as a fallback (better than omitting the image entirely) — note this in your summary as "remote image fallback used"

4. **Cross-reference**: HTML gives structure/classes, PNG gives visual truth. When they conflict, trust the PNG.

### Step 3: Atomic Decomposition

Following `references/atomic-design.md`:

#### 3a. Identify the Layout Grid
- Desktop: typically sidebar + main content area with multi-column grid
- Mobile: typically top bar + stacked sections + bottom nav + FAB
- This becomes the Layout component

#### 3b. Identify Organisms (Sections)
Each visually distinct section/card in the screen is an organism:
- Navigation bars (SideNav, TopNav, BottomNav)
- Data panels (portfolio summary, market overview)
- Card groups (yield cards, market cards)
- Feed sections (alerts, intelligence feed)

#### 3c. Check Existing Components
**Critical**: Read `components.md` before creating anything new.

Common shared organisms that already exist:
- `SideNav` — all desktop layouts
- `TopNav` — all desktop layouts
- `BottomNav` — all mobile layouts
- `TopAppBar` — all mobile layouts
- `FAB` — all mobile layouts

Import these rather than recreating.

#### 3d. Identify Molecules
Within new organisms, find repeating units:
- Individual card components
- List item components
- Stat/metric displays
- Chart widgets

#### 3e. Identify Atoms
Any new atomic elements:
- New badge variants
- New chart types (sparkline, progress ring)
- New icon usages

### Step 4: Implementation

Build bottom-up following the framework patterns from `references/tech-stack-templates.md`.

#### 4a. Create New Atoms (if any)
Place in `src/components/`. Keep stateless, prop-driven.

#### 4b. Create New Molecules
Place in `src/components/`. Combine atoms into meaningful units.

#### 4c. Create New Organisms
Place in `src/components/`. Compose molecules into screen sections.

#### 4d. Create Layout
Place in `src/layouts/`.

**Desktop layout pattern** (react-vite):
```tsx
import SideNav from '../components/SideNav'
import TopNav from '../components/TopNav'
// Import screen-specific organisms

export default function Desktop{Name}() {
  return (
    <div className="flex h-screen bg-background">
      <SideNav />
      <div className="flex-1 flex flex-col overflow-hidden">
        <TopNav />
        <main className="flex-1 overflow-y-auto p-14">
          {/* Arrange organisms in grid */}
        </main>
      </div>
    </div>
  )
}
```

**Mobile layout pattern** (react-vite):
```tsx
import TopAppBar from '../components/TopAppBar'
import BottomNav from '../components/BottomNav'
import FAB from '../components/FAB'
// Import screen-specific organisms

export default function Mobile{Name}() {
  return (
    <div className="flex flex-col h-screen bg-background">
      <TopAppBar title="{Name}" />
      <main className="flex-1 overflow-y-auto px-5 pt-4 pb-24">
        {/* Stack organisms vertically */}
      </main>
      <FAB />
      <BottomNav />
    </div>
  )
}
```

#### 4e. Create Page
Place in `src/pages/`.

```tsx
import { useMediaQuery } from '../hooks/useMediaQuery'
import Desktop{Name} from '../layouts/Desktop{Name}'
import Mobile{Name} from '../layouts/Mobile{Name}'

export default function {Name}Page() {
  const isDesktop = useMediaQuery('(min-width: 1024px)')
  return isDesktop ? <Desktop{Name} /> : <Mobile{Name} />
}
```

#### 4f. Add Route
Add `<Route path="/{route}" element={<{Name}Page />} />` to `src/App.tsx`.

### Step 5: Apply Design System

**Critical rules from design.md:**

- **No raw hex values** — use design token CSS variables (`bg-background`, `text-primary`, `bg-surface-container`)
- **No 1px solid borders** — use tonal layering for depth (the "No-Line Rule")
- **Ghost border fallback**: `border-outline-variant/10` at 15% opacity max if edge definition needed
- **Typography**: `font-headline` (Space Grotesk) for headlines, `font-body`/`font-label` (Manrope) for body
- **Surface hierarchy**: `surface` → `surface-container-low` → `surface-container` → `surface-container-highest`
- **Trend colors**: up = `primary` (#b1ffce mint), down = `tertiary` (#ff6e85 pink)
- **Spacing**: Generous — `p-14` for page margins, `gap-8` between sections
- **Radii**: `rounded-2xl` for cards, `rounded-full` for buttons. Never `rounded` (DEFAULT)
- **No pure white** — use `on-surface` (#fdfbfe)

### Step 6: Update Tracking

After converting each screen:

1. **Update `screens.md`**:
   - Set `Status` to `component_converted`
   - Set `Component` to the layout path (e.g., `layouts/DesktopHome.tsx`)
   - Update `Updated` column

2. **Update `components.md`**:
   - Add new atoms, molecules, organisms to their respective sections
   - Add the layout to the Layouts section
   - Add the page to the Pages section
   - Include `Used By` cross-references

### Step 7: Summary

Present results:
- Components created (by level: atoms, molecules, organisms, layouts, pages)
- Existing components reused
- Design system tokens applied
- Any ambiguities resolved (HTML vs PNG conflicts)
- Recommended next step: "Run /stitch-harden to add accessibility and interactive states"

---

## Handling HTML Quality Variance

| HTML Quality | Strategy |
|-------------|----------|
| **Rich** (200+ lines, Tailwind classes) | Parse structure, adapt classes to project's design tokens, restructure into components |
| **Stub** (<50 lines) | Ignore HTML structure, build entirely from PNG visual reference + design system |
| **Partial** (some sections detailed, others stub) | Use detailed sections from HTML, fill in stubs from PNG |

In all cases, the PNG is the visual truth. The HTML is a structural suggestion.

---

## Cross-Screen Consistency

When converting multiple screens:

1. **First screen** establishes the component patterns
2. **Subsequent screens** should reuse established patterns
3. If a new screen's organism looks like an existing one with slight differences:
   - Prefer props/variants on the existing component over creating a new one
   - Only create a new component if the visual and functional difference is significant

---

## Framework-Specific Notes

### react-vite (Kinetic project)
- Function components with TypeScript
- `useMediaQuery` hook at 1024px for responsive switch
- React Router DOM for routing
- Tailwind CSS v4 with `@theme` variables in `src/index.css`
- Import paths: `../components/`, `../layouts/`, `../hooks/`

### react-nextjs
- Server Components by default, `'use client'` only for interactivity
- App Router file conventions (`page.tsx`, `layout.tsx`)
- `next/image` for images, `next/font` for fonts

### vue-vite / vue-nuxt
- `<script setup lang="ts">` SFC format
- Composition API with `ref`/`computed`
- Vue Router (vite) or file-based routing (nuxt)

### svelte-kit
- `+page.svelte` file convention
- Svelte stores for reactive state
- File-based routing
