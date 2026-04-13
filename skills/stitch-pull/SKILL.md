---
name: stitch-pull
description: Pull HTML and PNG assets from Stitch to the local project — fetches screen code and images, optionally runs component extraction and accessibility pre-analysis. Use after generating screens in Stitch, when assets need to be fetched locally, or when screens.md shows screens at "generated_in_stitch" status.
metadata:
  filePattern:
    - "stitch-assets/html/*"
    - "stitch-assets/screenshots/*"
    - ".stitch-claude/screens.md"
  bashPattern:
    - "stitch.pull|stitch-pull"
  priority: 70
  tags:
    - stitch
    - pull
    - assets
---

# stitch-pull — Asset Pull from Stitch

Fetch HTML and PNG assets from Stitch to the local `stitch-assets/` directory.

**Performance note:** This skill is a pure data-transfer operation — no design intelligence needed. Use **haiku subagents** to keep fetched content (10-20k tokens per screen) out of the main context window.

---

## Pre-flight

1. **Verify `.stitch-claude/` exists** — if not, run `stitch-init` first
2. **Read `.stitch-claude/screens.md`** — identify screens at `generated_in_stitch` status
3. **Verify `stitch-assets/html/` and `stitch-assets/screenshots/` exist** — create if missing

---

## Workflow

### Step 1: Identify Screens to Pull

Read `screens.md` and filter for screens with status `generated_in_stitch`.

If the user specifies particular screens, pull only those. Otherwise, pull all unpulled screens.

If no screens are at `generated_in_stitch`, inform the user:
- "No screens to pull. Run /stitch-generate first, or check /stitch-status for current state."

### Step 2: Delegate Fetch+Write to Haiku Subagents

**CRITICAL — Context Window Optimization:**
Do NOT call `fetch_screen_code` or `fetch_screen_image` directly in the main conversation. The HTML responses are 10-20k tokens each and will bloat the context window.

Instead, spawn **one haiku Agent per screen** (or batch 2-3 screens per agent) to do the fetch+write. The subagent handles the large content internally and returns only a brief summary.

**For each screen (or batch), launch an Agent with `model: "haiku"`:**

```
Agent(
  model: "haiku",
  description: "Pull assets for {screen-name}",
  prompt: """
    You are pulling Stitch assets to local files. This is a pure data-transfer task.

    For each screen below, do these steps IN ORDER:

    1. Call `fetch_screen_code` with the screen's Stitch ID → Write the FULL response to the HTML path using the Write tool
    2. Call `fetch_screen_image` with the screen's Stitch ID → Write the image to the PNG path using the Write tool
    3. **Extract embedded images** from the HTML you just wrote:
       - Read the HTML file
       - Find all <img> tags whose src starts with "https://lh3.googleusercontent.com/aida-public/"
       - Also find CSS background-image: url(...) values with those same URLs
       - For each URL found:
         a. Download it using the Bash tool: `curl -sL "{url}" -o "public/images/stitch/{screen-name}-img-{N}.jpg"`
            (replace {N} with 1, 2, 3… for each image found)
         b. Note the data-alt attribute (if present) — this is the image description
       - Create a JSON image map file at `stitch-assets/images/{screen-name}-image-map.json`:
         ```json
         {
           "https://lh3.googleusercontent.com/...full-url...": {
             "local": "/images/stitch/{screen-name}-img-1.jpg",
             "alt": "value from data-alt attribute, or empty string if absent"
           }
         }
         ```
       - If no embedded image URLs are found, skip this step (do NOT create an empty map file)
       - Ensure `public/images/stitch/` directory exists before writing (use `mkdir -p`)

    Screens to pull:
    - Screen: {screen-name}, Variant: {variant}
      Stitch ID: {stitch-id}
      HTML path: stitch-assets/html/{project}-{screen}-{variant}.html
      PNG path: stitch-assets/screenshots/{project}-{screen}-{variant}.png

    After completing all steps, report back ONLY:
    - Filename
    - File size (line count for HTML, or "image saved" for PNG)
    - Whether HTML is rich (200+ lines) or stub (<50 lines)
    - Number of embedded images downloaded (e.g., "2 images saved to public/images/stitch/")

    Do NOT include the file contents in your response.

    If ANY step fails for a screen (fetch fails, write fails, image download fails):
    - Report the failure clearly: "FAILED: {screen-name} — {error message}"
    - Do NOT stop processing other screens in your batch
    - Continue with the next screen
  """
)
```

**Parallelization:** Launch multiple haiku agents in parallel (one per screen or batched 2-3 screens each) to maximize throughput. All agents can run concurrently since they write to different files.

### Step 3: Collect Results

Each haiku agent returns a brief summary like:
```
kinetic-landing-desktop.html: 347 lines (rich HTML)
kinetic-landing-desktop.png: image saved
```

Collect these summaries — they are the only content that enters the main context.

### Step 4: Optional — Component Extraction Analysis

If the user requests deeper analysis (or by default for complex screens):

1. Call `extract_components` with the screen's Stitch ID
2. This returns a breakdown of detected UI components in the screen
3. Note the extracted components for use during `stitch-convert`
4. Update `components.md` with any newly detected atomic components

### Step 5: Optional — Accessibility Pre-Analysis

If available and the user opts in:

1. Call `analyze_accessibility` with the screen's Stitch ID
2. This pre-flags potential accessibility issues in the design
3. Record findings in `.stitch-claude/hardening-log.md` as pre-analysis notes
4. These will be addressed during `stitch-harden`

### Step 6: Update Tracking

For each successfully pulled screen:

1. **Update `screens.md`**:
   - Set `Status` to `assets_pulled`
   - Set `HTML Asset` to the relative path (e.g., `html/kinetic-home-desktop.html`)
   - Set `PNG Asset` to the relative path (e.g., `screenshots/kinetic-home-desktop.png`)
   - Update the `Updated` column to today's date

2. If component extraction was run, **update `components.md`** with any new entries.

For each **failed** screen:
1. **Update `screens.md`**:
   - Set `Status` to `failed_pull`
   - Set `Error` to a concise error message (e.g., "MCP timeout", "fetch returned empty")
   - Increment `Retries` if this is a retry attempt
   - Update the `Updated` column to today's date

### Step 7: Summary

Present results:
- Number of screens pulled
- Screens with full HTML vs. stub HTML
- Any accessibility pre-analysis findings
- Recommended next step: "Run /stitch-convert to create framework components from these assets"

---

## Pulling Specific Screens

The user can request specific screens:
- "Pull the home screen" → pull `home-desktop` and `home-mobile`
- "Pull the desktop variant of markets" → pull only `markets-desktop`
- "Pull all unpulled screens" → pull everything at `generated_in_stitch`

### Handling Missing Screens

If a requested screen doesn't have a Stitch ID:
- Check if it's at `planned` status → "This screen needs to be generated first. Run /stitch-generate."
- Check if it's already at `assets_pulled` or later → "This screen's assets are already pulled."

---

## HTML Quality Variance

Stitch HTML quality varies. Expect two types:

| Type | Characteristics | Conversion Strategy |
|------|----------------|-------------------|
| **Rich HTML** | 200-500+ lines, full Tailwind classes, complete structure | Parse and adapt — use as structural reference |
| **Stub HTML** | 10-30 lines, screen ID, minimal content, "see screenshot" | Rely primarily on PNG for visual reference |

Both are valid — the `stitch-convert` skill handles both types. Always pull both HTML and PNG regardless of HTML quality.

---

## Error Handling

- **Screen not found in Stitch**: Set status to `failed_pull` with error "Screen not found — may have been deleted". Do not set to `skipped` automatically.
- **Fetch timeout**: Set status to `failed_pull` with error "MCP timeout after 180s". The orchestrator will offer retry on next run.
- **Image too large**: PNG files can be several MB. This is normal — not a failure.
- **HTML is empty**: Write an empty file, set status to `assets_pulled` (empty HTML is valid — PNG is primary reference). Note "stub HTML" in summary.
- **Image extraction fails**: Set HTML/PNG status to `assets_pulled` (core assets succeeded), note image extraction failure in summary. This is non-blocking.
