# Tech Stack Detection & Framework Templates

## Detection Heuristics

Run these checks in order. First match wins.

| Check | Tech Stack | Details |
|-------|-----------|---------|
| `next.config.ts` or `next.config.js` or `next.config.mjs` exists | `react-nextjs` | Next.js App Router (16+) |
| `nuxt.config.ts` or `nuxt.config.js` exists | `vue-nuxt` | Nuxt 3 |
| `svelte.config.js` or `svelte.config.ts` exists | `svelte-kit` | SvelteKit |
| `vite.config.*` exists + `vue` in package.json deps | `vue-vite` | Vue + Vite SPA |
| `vite.config.*` exists + `react` in package.json deps | `react-vite` | React + Vite SPA |
| `vite.config.*` exists + `svelte` in package.json deps | `svelte-vite` | Svelte + Vite SPA |
| None of the above | `static` | Plain HTML/CSS/JS |

### Secondary Detection (within package.json)

| Dependency | Adds to metadata |
|-----------|-----------------|
| `tailwindcss` | CSS: Tailwind CSS |
| `react-router-dom` | Router: React Router |
| `vue-router` | Router: Vue Router |
| `@tanstack/react-query` | Data: TanStack Query |
| `prisma` or `@prisma/client` | ORM: Prisma |
| `drizzle-orm` | ORM: Drizzle |

---

## Per-Framework Component Patterns

### react-vite

**Page component** (`src/pages/{Name}Page.tsx`):
```tsx
import { useMediaQuery } from '../hooks/useMediaQuery'
import Desktop{Name} from '../layouts/Desktop{Name}'
import Mobile{Name} from '../layouts/Mobile{Name}'

export default function {Name}Page() {
  const isDesktop = useMediaQuery('(min-width: 1024px)')
  return isDesktop ? <Desktop{Name} /> : <Mobile{Name} />
}
```

**Layout component** (`src/layouts/Desktop{Name}.tsx`):
```tsx
import SideNav from '../components/SideNav'
import TopNav from '../components/TopNav'

export default function Desktop{Name}() {
  return (
    <div className="flex h-screen bg-background">
      <SideNav />
      <div className="flex-1 flex flex-col overflow-hidden">
        <TopNav />
        <main className="flex-1 overflow-y-auto p-14">
          {/* Screen content */}
        </main>
      </div>
    </div>
  )
}
```

**Mobile layout** (`src/layouts/Mobile{Name}.tsx`):
```tsx
import TopAppBar from '../components/TopAppBar'
import BottomNav from '../components/BottomNav'
import FAB from '../components/FAB'

export default function Mobile{Name}() {
  return (
    <div className="flex flex-col h-screen bg-background">
      <TopAppBar title="{Name}" />
      <main className="flex-1 overflow-y-auto px-5 pt-4 pb-24">
        {/* Screen content */}
      </main>
      <FAB />
      <BottomNav />
    </div>
  )
}
```

**Shared component** (`src/components/{Name}.tsx`):
```tsx
export default function {Name}() {
  return (
    <div className="bg-surface-container rounded-2xl p-6">
      {/* Component content */}
    </div>
  )
}
```

**Route registration** (`src/App.tsx`):
```tsx
<Route path="/{route}" element={<{Name}Page />} />
```

### react-nextjs

**Page** (`app/{route}/page.tsx`):
```tsx
export default function {Name}Page() {
  return <{Name}Content />
}
```

**Layout** (`app/{route}/layout.tsx`):
```tsx
export default function {Name}Layout({ children }: { children: React.ReactNode }) {
  return <div className="...">{children}</div>
}
```

**Client component** (`components/{name}.tsx`):
```tsx
'use client'
export default function {Name}() { ... }
```

### vue-vite

**Page** (`src/pages/{Name}.vue`):
```vue
<script setup lang="ts">
import Desktop{Name} from '../layouts/Desktop{Name}.vue'
import Mobile{Name} from '../layouts/Mobile{Name}.vue'
import { useMediaQuery } from '../composables/useMediaQuery'

const isDesktop = useMediaQuery('(min-width: 1024px)')
</script>

<template>
  <Desktop{Name} v-if="isDesktop" />
  <Mobile{Name} v-else />
</template>
```

### vue-nuxt

**Page** (`pages/{route}.vue`):
```vue
<script setup lang="ts">
definePageMeta({ layout: 'default' })
</script>

<template>
  <div>...</div>
</template>
```

### svelte-kit

**Page** (`src/routes/{route}/+page.svelte`):
```svelte
<script lang="ts">
  import { mediaQuery } from '$lib/stores/mediaQuery'
</script>

{#if $mediaQuery.desktop}
  <Desktop{Name} />
{:else}
  <Mobile{Name} />
{/if}
```

---

## Responsive Strategy Per Framework

| Framework | Breakpoint | Strategy |
|-----------|-----------|----------|
| react-vite | 1024px | `useMediaQuery` hook → render different layout components |
| react-nextjs | 1024px | `useMediaQuery` client hook or CSS-only with `hidden lg:block` |
| vue-vite | 1024px | `useMediaQuery` composable → `v-if`/`v-else` |
| vue-nuxt | 1024px | Same as vue-vite or CSS-only |
| svelte-kit | 1024px | Svelte store + `{#if}` blocks |

---

## Naming Conventions

| Entity | Pattern | Example |
|--------|---------|---------|
| Page component | `{Name}Page` | `HomePage`, `MarketsPage` |
| Desktop layout | `Desktop{Name}` | `DesktopHome`, `DesktopMarkets` |
| Mobile layout | `Mobile{Name}` | `MobileHome`, `MobileMarkets` |
| Shared component | `{Name}` | `MarketWatch`, `SideNav` |
| Route | `/{kebab-case}` | `/home`, `/advanced-insights` |
| Screen name (tracking) | `kebab-case` | `home`, `advanced-insights` |
| Stitch asset | `{project}-{screen}-{variant}` | `kinetic-home-desktop` |
