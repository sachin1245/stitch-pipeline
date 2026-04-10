---
name: stitch-generate
description: Generate new UI screens in Google Stitch from text descriptions — creates desktop and mobile variants, tracks generation in screens.md. Use when the user wants to create new screen designs, add pages to the project, or generate responsive variants of existing screens.
metadata:
  filePattern:
    - ".stitch-claude/screens.md"
  bashPattern:
    - "stitch.generate|stitch-generate"
  priority: 70
  tags:
    - stitch
    - generate
    - design
---

# stitch-generate — Screen Generation in Stitch

Generate new UI screens via Stitch MCP tools, creating both desktop and mobile variants with design system context.

---

## Pre-flight

1. **Verify `.stitch-claude/` exists** — if not, run `stitch-init` first
2. **Read `.stitch-claude/project.md`** — get project vision, design system ID, tech stack
3. **Read `.stitch-claude/screens.md`** — know what screens already exist
4. **Read `design.md`** — understand the design system for prompt context

---

## Workflow

### Step 1: Plan Screens

Accept the user's product vision, spec, or screen descriptions. Plan a screen list with:
- Screen name (kebab-case)
- Desktop variant description
- Mobile variant description
- Priority/order

**If the user provides a high-level vision** (e.g., "crypto analytics dashboard"):
- Propose a screen list based on common patterns for that domain
- Confirm with the user before generating

**If the user provides specific screens** (e.g., "add a swap page"):
- Plan desktop + mobile variants for each requested screen

### Step 2: Choose Generation Model

| Model | Use When |
|-------|----------|
| `GEMINI_3_FLASH` (default) | Fast iteration, simpler screens, initial exploration |
| `GEMINI_3_1_PRO` | Complex layouts, high-fidelity designs, final versions |

Let the user override. Default to Flash for speed.

### Step 3: Build Prompts

For each screen, construct a generation prompt that includes:

1. **Project context**: Project name, domain, overall vision
2. **Design system**: Key design tokens (colors, typography, surfaces) from `design.md`
3. **Screen description**: What this specific screen shows
4. **Variant**: Desktop (sidebar + multi-column) or Mobile (stacked + bottom nav)
5. **Existing screens**: Reference names of already-generated screens for visual consistency

**Prompt template:**
```
Project: {project name}
Design System: {brief design system summary — background color, primary/secondary/tertiary colors, typography, surface hierarchy}
Screen: {screen name} — {variant} variant

{detailed screen description}

Design rules:
- Background: {background color}
- Surface hierarchy: Use tonal layering for depth
- No 1px borders for sectioning — use color shifts
- Typography: {headline font} for headlines, {body font} for body
- {any project-specific rules from design.md}
```

### Step 4: Generate Screens

**For single screens:**
Use `generate_screen_from_text` with:
- `projectId`: from `.stitch-claude/project.md`
- `prompt`: constructed prompt from Step 3
- `model`: chosen model (default: `GEMINI_3_FLASH`)

**For batch generation (3+ screens):**
Use `batch_generate_screens` with an array of prompts.

**For responsive variants:**
After generating the desktop version, use `generate_responsive_variant` to create the mobile version (or vice versa), passing the original screen ID.

### Step 5: Record Results

For each generated screen:

1. **Capture the Stitch screen ID** from the API response
2. **Update `screens.md`** — add a new row:

```
| {screen} | {variant} | {stitch-id} | generated_in_stitch | - | - | - | {today} |
```

3. If both desktop and mobile are generated, add two rows.

### Step 6: Summary

Present what was generated:
- Number of screens created
- Screen names and variants
- Model used
- Recommended next step: "Run /stitch-pull to fetch HTML and PNG assets to local"

---

## Naming Convention

Screen names follow the pattern: `{project}-{screen}-{variant}`

| Part | Format | Example |
|------|--------|---------|
| Project | lowercase | `kinetic` |
| Screen | kebab-case | `home`, `advanced-insights`, `yield` |
| Variant | `desktop` or `mobile` | `desktop` |
| Full | hyphen-joined | `kinetic-home-desktop` |

The `Screen` column in `screens.md` uses just the screen name without project prefix (e.g., `home`, not `kinetic-home`).

---

## Design System Context

When generating screens, always include design system context from `design.md`. Key elements to include in prompts:

- **Background color** and surface hierarchy
- **Primary/Secondary/Tertiary** colors and their semantic meanings
- **Typography** families and their roles
- **Component patterns** (no borders, tonal layering, generous spacing)
- **Navigation pattern** (sidebar for desktop, bottom nav for mobile)

This ensures Stitch generates screens that align with the project's established design language.

---

## Batch vs Sequential

| Screens | Strategy |
|---------|----------|
| 1-2 | Sequential `generate_screen_from_text` |
| 3+ | `batch_generate_screens` for parallel generation |
| Variant pairs | Generate primary, then `generate_responsive_variant` |

---

## Error Handling

- **MCP timeout**: Stitch generation can take 30-60s. If timeout, retry once.
- **Generation failure**: Note in screens.md with status `planned` and a comment about the failure.
- **Design system not found**: Run `stitch-init` to create one first.
