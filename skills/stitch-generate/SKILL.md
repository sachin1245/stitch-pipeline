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

Always use `generate_screen_from_text` — **never** use `batch_generate_screens`.

> **Why not batch?** The `batch_generate_screens` tool has critical limitations:
> no model selection (stuck on backend default), fewer deviceType options
> (no AGNOSTIC), and a timeout risk — the backend processes screens
> sequentially, so 5+ screens at 30-60s each exceeds the 3-minute MCP timeout.
> Parallel subagents calling the single-screen tool are faster, more reliable,
> and give full control over model and device type per screen.

**For a single screen (1-2 screens):**

Call `generate_screen_from_text` directly in the main conversation:
- `projectId`: from `.stitch-claude/project.md` (numeric ID only, no `projects/` prefix)
- `prompt`: constructed prompt from Step 3
- `modelId`: chosen model (default: `GEMINI_3_FLASH`)
- `deviceType`: `DESKTOP` or `MOBILE`

**For multiple screens (3+) — parallel subagent strategy:**

Spawn one Agent per screen (or per desktop+mobile pair) to generate in parallel.
All agents call `generate_screen_from_text` independently — no batch API needed.

```
Agent(
  model: "sonnet",
  description: "Generate {screen-name} screens",
  prompt: """
    You are generating screens in Google Stitch. Call `generate_screen_from_text`
    for each screen below. Wait for each call to complete before starting the next.
    Generation takes 30-60 seconds per screen — be patient and DO NOT RETRY on timeout.

    Project ID: {projectId}
    Model: {modelId}

    Screens to generate:
    1. Screen: {screen-name} — desktop
       deviceType: DESKTOP
       prompt: |
         {full prompt from Step 3}

    2. Screen: {screen-name} — mobile
       deviceType: MOBILE
       prompt: |
         {full prompt from Step 3}

    After each generation completes, report back:
    - Screen name and variant
    - Stitch screen ID from the response
    - Whether output_components contained any suggestions (quote them)

    If a call fails with a connection error, note the failure — the generation
    may still succeed server-side. Report the failure so we can check with
    get_screen or list_screens later.
  """
)
```

**Parallelization guidance:**

| Screens to generate | Strategy |
|---------------------|----------|
| 1-2 screens | Direct calls in main conversation |
| 3-6 screens | 2-3 parallel agents (1-2 screens each) |
| 7-12 screens | 4-6 parallel agents (2 screens each) |
| 13+ screens | 6-8 parallel agents (2-3 screens each), wave-based |

For 13+ screens, use **wave-based generation**: launch the first wave of 6-8 agents,
collect results, then launch the next wave. This avoids overwhelming the Stitch API
and keeps error recovery manageable.

**For responsive variants:**
After generating the desktop version, use `generate_responsive_variant` to create the mobile version (or vice versa), passing the original screen ID. Alternatively, generate both variants explicitly with separate `generate_screen_from_text` calls (gives more control over the mobile prompt).

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

## Parallel Generation Strategy

| Screens | Strategy |
|---------|----------|
| 1-2 | Direct `generate_screen_from_text` calls in main conversation |
| 3-6 | 2-3 parallel subagents, each generating 1-2 screens |
| 7-12 | 4-6 parallel subagents, each generating 2 screens |
| 13+ | Wave-based: 6-8 parallel subagents per wave, collect results between waves |
| Variant pairs | Generate desktop first, then `generate_responsive_variant` for mobile, OR two explicit calls with tailored prompts |

> **Do not use `batch_generate_screens`.** It lacks model selection, has fewer
> deviceType options, and times out on 5+ screens. Parallel subagents using
> `generate_screen_from_text` are faster and more reliable.

---

## Error Handling

- **MCP timeout / connection error**: Generation takes 30-60s per screen. If the call fails with a connection error, **do not retry immediately** — the generation may still succeed server-side. Wait 30s, then call `list_screens` or `get_screen` to check if the screen was created.
- **Generation failure**: Note in screens.md with status `planned` and a comment about the failure. The user can retry with `/stitch-generate` targeting the failed screen.
- **Subagent failure**: If a parallel subagent fails, set affected screens to `failed_generate` with the error message. Other agents' results are still valid. Report which screens failed so they can be retried.
- **Partial success**: If a subagent generates 1 of 2 screens successfully, advance the successful screen to `generated_in_stitch` and set the failed screen to `failed_generate`. Never leave both at `planned` when one succeeded.
- **Design system not found**: Run `stitch-init` to create one first.
- **Rate limiting**: If generating 13+ screens, use wave-based strategy (6-8 parallel agents per wave) to avoid API throttling. Wait for each wave to complete before starting the next.
