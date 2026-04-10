# Hardening Checklist

Condensed accessibility, interactivity, and semantic HTML checklist for the `stitch-harden` skill. Organized by audit pass.

---

## Pass 1: Quick Wins (~80% of issues)

These five checks cover the vast majority of gaps in AI-generated components.

### 1. Icon-only buttons need `aria-label`
```tsx
<button aria-label="Notifications" className="... focus-visible:ring-2 focus-visible:ring-primary/50 focus-visible:outline-none">
  <Icon name="notifications" />
</button>
```

### 2. Every interactive element needs `focus-visible`
```tsx
className="hover:bg-surface-container focus-visible:ring-2 focus-visible:ring-primary/50 focus-visible:outline-none active:scale-95"
```
Apply to: buttons, links, inputs, clickable cards, tabs, toggles.

### 3. Multiple `<nav>` elements need unique `aria-label`
```tsx
<nav aria-label="Main navigation">   {/* sidebar */}
<nav aria-label="Bottom navigation">  {/* bottom bar */}
```

### 4. Repeating items need `<ul>/<li>` with `role="list"`
Tailwind's list reset strips VoiceOver semantics. Always add `role="list"`.
```tsx
<ul role="list" className="space-y-4">
  {items.map(item => <li key={item.id}>...</li>)}
</ul>
```

### 5. Status indicators need `sr-only` text
Colored dots, trend arrows, badges carry meaning screen readers can't see.
```tsx
<span className="w-1.5 h-1.5 bg-tertiary rounded-full" aria-hidden="true" />
<span className="sr-only">Trending down</span>
```

---

## Pass 2: Widget Patterns

### Toggle Switches
```tsx
<button
  role="switch"
  aria-checked={enabled}
  aria-label="Two-Factor Authentication"
  onClick={() => setEnabled(!enabled)}
  className="relative inline-flex h-7 w-12 rounded-full transition-colors
    focus-visible:ring-2 focus-visible:ring-primary/50 focus-visible:outline-none"
>
  <span aria-hidden="true" className="..." />
</button>
```

### Tab Interfaces
```tsx
<div role="tablist" aria-label="Portfolio views">
  <button role="tab" aria-selected={active} aria-controls="panel-id" tabIndex={active ? 0 : -1}>
    Tab Label
  </button>
</div>
<div role="tabpanel" id="panel-id" aria-labelledby="tab-id">
  {/* content */}
</div>
```

### Radio Groups (Theme selectors, filters)
```tsx
<fieldset>
  <legend className="sr-only">Theme</legend>
  <div role="radiogroup" aria-label="Theme selection">
    <label>
      <input type="radio" name="theme" value="dark" className="sr-only" />
      Dark
    </label>
  </div>
</fieldset>
```

### Dangerous Action Buttons
```tsx
<button aria-describedby="delete-warning">Delete Account</button>
<p id="delete-warning">This action cannot be undone.</p>
```

---

## Pass 3: Full Checklist

### Interactive Elements
- [ ] Every `<button>` with only icon/SVG has `aria-label`
- [ ] Toggle buttons use `aria-pressed` or `aria-expanded`
- [ ] Close/dismiss buttons use `aria-label="Close"` or `"Dismiss"`
- [ ] FAB has `aria-label` describing the action
- [ ] Destructive buttons link to warning via `aria-describedby`

### Focus & Interactive States
- [ ] Every `<button>` has `focus-visible:ring-2 focus-visible:ring-primary/50 focus-visible:outline-none`
- [ ] Every `<a>` / `<NavLink>` has `focus-visible` styles
- [ ] Every `<input>`, `<select>`, `<textarea>` has `focus-visible` styles
- [ ] Custom interactives (clickable cards, tabs) have `focus-visible`
- [ ] Focus ring uses design system tokens (not browser default blue)
- [ ] Destructive elements use `focus-visible:ring-tertiary/50`
- [ ] All interactives have: `hover:`, `focus-visible:`, `active:` states

### Navigation
- [ ] Multiple `<nav>` elements have unique `aria-label`
- [ ] Active item uses `aria-current="page"`
- [ ] Nav links use `<ul role="list"><li><a>` structure
- [ ] `<main>` wraps primary content
- [ ] `<header>` and `<footer>` at page level

### Forms
- [ ] Every `<input>` has a `<label>` (visible or `sr-only`) linked by `htmlFor`/`id`
- [ ] Search inputs wrapped in `<search>` or `role="search"`
- [ ] Required fields use `aria-required="true"`
- [ ] Error messages linked with `aria-describedby`

### Sections & Headings
- [ ] `<section>` with visible heading uses `aria-labelledby`
- [ ] Sections without heading use `aria-label`
- [ ] One `<h1>` per page
- [ ] Headings follow hierarchy (h1→h2→h3, no skipping)

### Lists
- [ ] Repeating items (3+) use `<ul>`/`<ol>` with `<li>`
- [ ] Tailwind-styled lists have `role="list"` (VoiceOver fix)

### Data Visualizations
- [ ] Decorative SVGs: `aria-hidden="true"`
- [ ] Charts: wrapped in `<div role="img" aria-label="...">`
- [ ] Progress rings: `role="progressbar"` + `aria-valuenow/min/max`

### Status Indicators
- [ ] Colored dots/badges: `aria-hidden="true"` + `sr-only` text
- [ ] Trend arrows: `aria-hidden="true"` on icon + `sr-only` direction
- [ ] Decorative heading icons: `aria-hidden="true"`

### Touch Targets (Mobile)
- [ ] Every tappable element ≥ 44×44px (use padding if icon is smaller)

### Images
- [ ] Every `<img>` has `alt` attribute
- [ ] Decorative images: `alt=""` (optionally `aria-hidden="true"`)
- [ ] Convert Stitch `data-alt` to proper `alt`

---

## What NOT to Do

- Don't add `aria-label` to elements with visible text (double-announcement)
- Don't add `role="button"` to `<button>` (already implicit)
- Don't wrap everything in landmarks (too many is as bad as none)
- Don't add `tabIndex={0}` to non-interactive elements
- Don't change visual design or layout (hardening is the invisible layer)
