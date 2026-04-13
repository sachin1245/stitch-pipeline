# Screen Inventory

| Screen | Variant | Stitch ID | Status | HTML Asset | PNG Asset | Component | Error | Retries | Updated |
|--------|---------|-----------|--------|------------|-----------|-----------|-------|---------|---------|
| home | desktop | abc123 | hardened | html/test-home-desktop.html | screenshots/test-home-desktop.png | layouts/DesktopHome.tsx | - | 0 | 2026-04-01 |
| markets | desktop | ghi789 | failed_pull | - | - | - | MCP timeout after 180s | 1 | 2026-04-01 |
| settings | desktop | jkl012 | failed_convert | html/test-settings-desktop.html | screenshots/test-settings-desktop.png | - | TypeScript compile error: missing SideNav import | 0 | 2026-04-01 |

## Status Lifecycle
planned → generated_in_stitch → assets_pulled → component_converted → hardened

## Failure Statuses
- **failed_generate**: Generation failed in Stitch
- **failed_pull**: Asset fetch failed
- **failed_convert**: Component conversion failed
- **failed_harden**: Accessibility hardening failed
