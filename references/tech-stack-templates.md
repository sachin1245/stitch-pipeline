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
import {Name}Content from './components/{Name}Content'

export default function {Name}Page() {
  return <{Name}Content />
}
```

**Layout** (`app/{route}/layout.tsx`):
```tsx
export default function {Name}Layout({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex h-screen bg-background">
      <SideNav />
      <div className="flex-1 flex flex-col overflow-hidden">
        <TopNav />
        <main className="flex-1 overflow-y-auto p-14">
          {children}
        </main>
      </div>
    </div>
  )
}
```

**Client component** (`app/{route}/components/{Name}Content.tsx`):
```tsx
'use client'
// Interactive components must opt in to client rendering
export default function {Name}Content() {
  return (
    <div className="grid grid-cols-12 gap-8">
      {/* Screen-specific organisms */}
    </div>
  )
}
```

**Responsive strategy**: Use CSS-only approach with Tailwind:
```tsx
// Desktop layout visible at lg+, mobile layout visible below lg
<div className="hidden lg:block"><DesktopContent /></div>
<div className="lg:hidden"><MobileContent /></div>
```

**Shared component** (`components/{name}.tsx`):
```tsx
// Server Component by default — add 'use client' only if it uses hooks/state/events
export default function {Name}() {
  return <div className="bg-surface-container rounded-2xl p-6">{/* ... */}</div>
}
```

**Key differences from react-vite:**
- File-based routing (`app/{route}/page.tsx`) instead of `src/App.tsx` route registration
- Server Components by default — only add `'use client'` for interactive organisms
- Use `next/image` for images, `next/font` for custom fonts
- Layouts are nested via `layout.tsx` files, not composed in page components
- No `useMediaQuery` — use CSS `hidden lg:block` or a client wrapper

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

**Desktop layout** (`src/layouts/Desktop{Name}.vue`):
```vue
<script setup lang="ts">
import SideNav from '../components/SideNav.vue'
import TopNav from '../components/TopNav.vue'
// Import screen-specific organisms
</script>

<template>
  <div class="flex h-screen bg-background">
    <SideNav />
    <div class="flex-1 flex flex-col overflow-hidden">
      <TopNav />
      <main class="flex-1 overflow-y-auto p-14">
        <!-- Arrange organisms in grid -->
      </main>
    </div>
  </div>
</template>
```

**Mobile layout** (`src/layouts/Mobile{Name}.vue`):
```vue
<script setup lang="ts">
import TopAppBar from '../components/TopAppBar.vue'
import BottomNav from '../components/BottomNav.vue'
import FAB from '../components/FAB.vue'
</script>

<template>
  <div class="flex flex-col h-screen bg-background">
    <TopAppBar title="{Name}" />
    <main class="flex-1 overflow-y-auto px-5 pt-4 pb-24">
      <!-- Stack organisms vertically -->
    </main>
    <FAB />
    <BottomNav />
  </div>
</template>
```

**Shared component** (`src/components/{Name}.vue`):
```vue
<script setup lang="ts">
// Props via defineProps, emits via defineEmits
const props = defineProps<{ title: string }>()
</script>

<template>
  <div class="bg-surface-container rounded-2xl p-6">
    <h2 class="font-headline text-lg">{{ props.title }}</h2>
    <slot />
  </div>
</template>
```

**useMediaQuery composable** (`src/composables/useMediaQuery.ts`):
```ts
import { ref, onMounted, onUnmounted } from 'vue'
export function useMediaQuery(query: string) {
  const matches = ref(false)
  let mql: MediaQueryList
  onMounted(() => {
    mql = window.matchMedia(query)
    matches.value = mql.matches
    const handler = (e: MediaQueryListEvent) => { matches.value = e.matches }
    mql.addEventListener('change', handler)
    onUnmounted(() => mql.removeEventListener('change', handler))
  })
  return matches
}
```

**Route registration** (`src/router/index.ts`):
```ts
import { createRouter, createWebHistory } from 'vue-router'
const routes = [
  { path: '/{route}', component: () => import('../pages/{Name}.vue') }
]
```

**Key differences from react-vite:**
- `.vue` SFC files with `<script setup>` + `<template>` blocks
- Props via `defineProps<T>()`, events via `defineEmits<T>()`
- Reactive state via `ref()` / `computed()`, not `useState`
- Vue Router for routing, not React Router
- Use `class` not `className` in templates

### vue-nuxt

**Page** (`pages/{route}.vue`):
```vue
<script setup lang="ts">
import Desktop{Name} from '~/layouts/Desktop{Name}.vue'
import Mobile{Name} from '~/layouts/Mobile{Name}.vue'
import { useMediaQuery } from '~/composables/useMediaQuery'

definePageMeta({ layout: false }) // opt out of default layout

const isDesktop = useMediaQuery('(min-width: 1024px)')
</script>

<template>
  <Desktop{Name} v-if="isDesktop" />
  <Mobile{Name} v-else />
</template>
```

**Shared component** (`components/{Name}.vue`):
```vue
<script setup lang="ts">
// Auto-imported — no need to import ref, computed, etc.
const props = defineProps<{ title: string }>()
</script>

<template>
  <div class="bg-surface-container rounded-2xl p-6">
    <h2 class="font-headline text-lg">{{ props.title }}</h2>
    <slot />
  </div>
</template>
```

**Key differences from vue-vite:**
- File-based routing (`pages/` directory) — no router config needed
- Auto-imports for Vue APIs and components in `components/`
- Use `~/` alias for project root imports
- `definePageMeta()` for route metadata
- Layouts via `layouts/` directory or inline with `layout: false`

### svelte-kit

**Page** (`src/routes/{route}/+page.svelte`):
```svelte
<script lang="ts">
  import { browser } from '$app/environment'
  import { mediaQuery } from '$lib/stores/mediaQuery'
  import Desktop{Name} from '$lib/layouts/Desktop{Name}.svelte'
  import Mobile{Name} from '$lib/layouts/Mobile{Name}.svelte'
</script>

{#if $mediaQuery.desktop}
  <Desktop{Name} />
{:else}
  <Mobile{Name} />
{/if}
```

**Desktop layout** (`src/lib/layouts/Desktop{Name}.svelte`):
```svelte
<script lang="ts">
  import SideNav from '$lib/components/SideNav.svelte'
  import TopNav from '$lib/components/TopNav.svelte'
</script>

<div class="flex h-screen bg-background">
  <SideNav />
  <div class="flex-1 flex flex-col overflow-hidden">
    <TopNav />
    <main class="flex-1 overflow-y-auto p-14">
      <!-- Screen organisms -->
    </main>
  </div>
</div>
```

**Shared component** (`src/lib/components/{Name}.svelte`):
```svelte
<script lang="ts">
  // Props via export let (Svelte 4) or $props() (Svelte 5)
  let { title } = $props<{ title: string }>()
</script>

<div class="bg-surface-container rounded-2xl p-6">
  <h2 class="font-headline text-lg">{title}</h2>
  <slot />
</div>
```

**Media query store** (`src/lib/stores/mediaQuery.ts`):
```ts
import { readable } from 'svelte/store'
import { browser } from '$app/environment'
export const mediaQuery = readable({ desktop: true }, (set) => {
  if (!browser) return
  const mql = window.matchMedia('(min-width: 1024px)')
  const handler = () => set({ desktop: mql.matches })
  handler()
  mql.addEventListener('change', handler)
  return () => mql.removeEventListener('change', handler)
})
```

**Key differences from react-vite:**
- File-based routing (`src/routes/`) with `+page.svelte`, `+layout.svelte`, `+page.ts`
- Components in `src/lib/` (accessible via `$lib/` alias)
- Reactive declarations with `$:` (Svelte 4) or runes `$state`, `$derived` (Svelte 5)
- No JSX — use Svelte template syntax (`{#if}`, `{#each}`, `<slot />`)
- Props via `export let` (Svelte 4) or `$props()` (Svelte 5)
- Stores for shared state (`readable`, `writable` from `svelte/store`)

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
