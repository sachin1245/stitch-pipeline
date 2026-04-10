# Atomic Design Decomposition Rules

When converting a Stitch screen (HTML + PNG) into framework components, decompose into atomic design levels. The goal is maximum reuse — every screen shares the same atoms and molecules.

---

## Hierarchy

```
Pages          Route-level: responsive switch between desktop/mobile layouts
  └── Layouts  Full-screen composition for one variant (desktop OR mobile)
       └── Organisms  Self-contained sections (navigation, card groups, data panels)
            └── Molecules  Small groups of atoms (stat card, chart widget, list item)
                 └── Atoms  Single-purpose elements (icon, button, badge, avatar)
```

---

## Level Definitions

### Atoms (`src/components/`)
Single HTML element or minimal wrapper. No business logic. No data fetching.

**Examples:** Icon, Badge, Avatar, Sparkline, ProgressRing, StatusDot

**Rules:**
- One visual concern only
- Props control appearance (variant, size, color)
- No internal state (stateless or controlled)
- Named generically — `Icon` not `NavigationIcon`

### Molecules (`src/components/`)
Small cluster of atoms that work together as a unit. May have minimal UI state (hover, expanded).

**Examples:** MarketWatch (icon + name + price + change), YieldCard (title + APY + sparkline), DeployCard (icon + title + description + button)

**Rules:**
- Combines 2-5 atoms into a meaningful unit
- May accept data as props
- Reusable across multiple organisms/layouts
- Self-contained — no knowledge of page layout

### Organisms (`src/components/`)
Distinct section of a screen. May contain multiple molecules. May have internal state.

**Examples:** SideNav, TopNav, BottomNav, PortfolioHeader, IntelligenceFeed, ActiveMarkets, StakingHub

**Rules:**
- Represents a recognizable UI section
- May manage its own state (selected tab, scroll position)
- Typically maps to a "card" or "panel" in the design
- Can be reused across pages but doesn't have to be

### Layouts (`src/layouts/`)
Full-screen composition for one responsive variant. Arranges organisms in a grid/flex layout. One per screen+variant.

**Examples:** DesktopHome, MobileHome, DesktopMarkets, MobileMarkets

**Rules:**
- Always desktop OR mobile, never both
- Imports and arranges organisms
- Handles the overall grid/flex structure
- Includes navigation (SideNav for desktop, BottomNav for mobile)
- No data fetching — passes data down to organisms

### Pages (`src/pages/`)
Route-level component. Its only job is the responsive switch.

**Examples:** HomePage, MarketsPage

**Rules:**
- Uses `useMediaQuery` (or framework equivalent) to pick layout
- One per route
- No visual markup — just the layout switch

---

## Decomposition Process

When analyzing a screen's HTML/PNG:

### Step 1: Identify the layout grid
Look at the overall structure: sidebar + main content area (desktop), stacked sections (mobile). This becomes the Layout component.

### Step 2: Identify organisms (sections)
Each visually distinct section/card is an organism. Look for:
- Cards with their own title/header
- Navigation bars
- Data panels or dashboards
- Feed/list sections

### Step 3: Check existing organisms
Read `components.md` — does this organism already exist? Many organisms repeat across screens:
- SideNav appears in ALL desktop layouts
- BottomNav appears in ALL mobile layouts
- TopNav/TopAppBar are shared navigation

### Step 4: Decompose new organisms into molecules
Within each new organism, identify repeating units:
- A list of tokens → the token row is a molecule
- A grid of stat cards → each card is a molecule
- A chart with legend → chart + legend could be separate molecules

### Step 5: Identify new atoms
Are there any new atomic elements not yet in the library?
- New icon variants
- New badge styles
- New chart types (sparkline, progress ring)

### Step 6: Bottom-up implementation
Create in this order:
1. New atoms (if any)
2. New molecules
3. New organisms
4. Layout (composes organisms)
5. Page (responsive switch)

---

## Reuse Signals

When decomposing, watch for these reuse patterns:

| Signal | Action |
|--------|--------|
| Same card appears on 3+ screens | Extract as shared molecule |
| Same list item pattern in multiple lists | Extract the item as a molecule |
| Section title + content follows the same pattern | Ensure organism is consistent |
| Navigation is identical across screens | Reuse the existing organism |
| Same stat/metric format (number + label + trend) | Extract as atom or molecule |

---

## Anti-Patterns

| Don't | Instead |
|-------|---------|
| Create a "DesktopHomeCard1" molecule | Name by purpose: `PortfolioSummary` |
| Duplicate SideNav code in each layout | Import the shared `SideNav` |
| Put responsive logic in organisms | Keep it in the Page component |
| Create atoms with business logic | Atoms are visual primitives only |
| Over-abstract — making atoms for every `<div>` | Only extract when there's reuse or the element has its own visual identity |
