<template>
  <header class="fixed top-0 left-0 right-0 z-50 glass">
    <div class="max-w-6xl mx-auto px-4 h-16 flex items-center justify-between">
      <NuxtLink :to="localePath('/')" class="flex items-center no-underline">
        <img
          src="/img/logo-orizz@2x.png"
          alt="DoVe"
          class="h-7"
          style="width: auto;"
        />
      </NuxtLink>

      <!-- Desktop nav -->
      <nav class="hidden md:flex items-center gap-8">
        <NuxtLink
          v-for="item in navItems"
          :key="item.to"
          :to="localePath(item.to)"
          class="text-sm font-medium no-underline transition-colors hover:opacity-70"
          :style="{ color: $route.path === localePath(item.to) ? 'var(--dove-text)' : 'var(--dove-muted)' }"
        >
          {{ item.label }}
        </NuxtLink>
        <LangSwitcher />
      </nav>

      <!-- Mobile hamburger -->
      <button
        class="md:hidden p-2 -mr-2"
        @click="mobileOpen = !mobileOpen"
        :aria-label="mobileOpen ? 'Chiudi menu' : 'Apri menu'"
      >
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <template v-if="!mobileOpen">
            <line x1="4" y1="7" x2="20" y2="7" />
            <line x1="4" y1="12" x2="20" y2="12" />
            <line x1="4" y1="17" x2="20" y2="17" />
          </template>
          <template v-else>
            <line x1="6" y1="6" x2="18" y2="18" />
            <line x1="6" y1="18" x2="18" y2="6" />
          </template>
        </svg>
      </button>
    </div>

    <!-- Mobile menu -->
    <Transition name="slide">
      <div v-if="mobileOpen" class="md:hidden glass border-t border-[var(--dove-border)]">
        <nav class="flex flex-col p-4 gap-4">
          <NuxtLink
            v-for="item in navItems"
            :key="item.to"
            :to="localePath(item.to)"
            class="text-base font-medium no-underline py-2"
            :style="{ color: 'var(--dove-text)' }"
            @click="mobileOpen = false"
          >
            {{ item.label }}
          </NuxtLink>
          <LangSwitcher />
        </nav>
      </div>
    </Transition>
  </header>
  <!-- Spacer for fixed header -->
  <div class="h-16" />
</template>

<script setup>
const { t } = useI18n()
const localePath = useLocalePath()
const mobileOpen = ref(false)

const navItems = computed(() => [
  { to: '/', label: t('nav.home') },
  { to: '/about', label: t('nav.about') },
  { to: '/contatti', label: t('nav.contact') },
])
</script>

<style scoped>
.slide-enter-active,
.slide-leave-active {
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

.slide-enter-from,
.slide-leave-to {
  opacity: 0;
  transform: translateY(-8px);
}
</style>
