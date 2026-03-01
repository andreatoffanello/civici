<template>
  <footer class="border-t" :style="{ borderColor: 'var(--dove-border)' }">
    <div class="max-w-6xl mx-auto px-4 py-12">
      <div class="flex flex-col md:flex-row md:items-center md:justify-between gap-6">
        <div>
          <img src="/img/logo-orizz@2x.png" alt="DoVe" class="h-6" style="width: auto;" />
          <p class="text-sm mt-1" :style="{ color: 'var(--dove-muted)' }">
            {{ t('footer.madeWith') }}
          </p>
        </div>

        <nav class="flex flex-wrap gap-6">
          <NuxtLink
            v-for="item in navItems"
            :key="item.to"
            :to="localePath(item.to)"
            class="text-sm no-underline transition-colors"
            :style="{ color: 'var(--dove-muted)' }"
          >
            {{ item.label }}
          </NuxtLink>
        </nav>
      </div>

      <div class="mt-8 pt-6 border-t flex flex-col sm:flex-row sm:items-center sm:justify-between gap-2" :style="{ borderColor: 'var(--dove-border)' }">
        <p class="text-xs" :style="{ color: 'var(--dove-muted)' }">
          &copy; {{ new Date().getFullYear() }} DoVe Venezia
        </p>
        <div class="flex gap-4">
          <NuxtLink :to="localePath('/privacy')" class="text-xs no-underline" :style="{ color: 'var(--dove-muted)' }">
            {{ t('footer.privacy') }}
          </NuxtLink>
          <NuxtLink :to="localePath('/supporto')" class="text-xs no-underline" :style="{ color: 'var(--dove-muted)' }">
            {{ t('support.title') }}
          </NuxtLink>
        </div>
      </div>
    </div>
  </footer>
</template>

<script setup>
const { t } = useI18n()
const localePath = useLocalePath()

const navItems = computed(() => [
  { to: '/come-funziona', label: t('nav.howItWorks') },
  { to: '/about', label: t('nav.about') },
  { to: '/contatti', label: t('nav.contact') },
])
</script>
