<template>
  <div>
    <!-- Intro section -->
    <section class="section-spacing">
      <div class="max-w-6xl mx-auto">
        <h1
          class="font-display text-3xl md:text-5xl font-bold text-center mb-4"
          :style="{ color: 'var(--dove-text)' }"
        >
          {{ t('howItWorks.title') }}
        </h1>
        <p
          class="text-center text-base md:text-lg max-w-2xl mx-auto mb-16 leading-relaxed"
          :style="{ color: 'var(--dove-muted)' }"
        >
          {{ t('howItWorks.intro') }}
        </p>

        <!-- Two numbering systems explanation -->
        <div class="grid grid-cols-1 md:grid-cols-2 gap-8 mb-16">
          <!-- Sestieri system -->
          <div class="glass rounded-2xl p-6 md:p-8">
            <div
              class="w-10 h-10 rounded-xl flex items-center justify-center mb-4"
              :style="{ backgroundColor: 'rgba(194, 69, 45, 0.12)' }"
            >
              <svg width="20" height="20" viewBox="0 0 20 20" fill="none" stroke="var(--dove-accent)" stroke-width="1.5">
                <rect x="2" y="2" width="7" height="7" rx="1.5" />
                <rect x="11" y="2" width="7" height="7" rx="1.5" />
                <rect x="2" y="11" width="7" height="7" rx="1.5" />
              </svg>
            </div>
            <h3 class="font-display text-xl font-bold mb-2" :style="{ color: 'var(--dove-text)' }">
              {{ t('howItWorks.sestieriSystem.title') }}
            </h3>
            <p class="text-sm leading-relaxed mb-4" :style="{ color: 'var(--dove-muted)' }">
              {{ t('howItWorks.sestieriSystem.description') }}
            </p>
            <div class="rounded-xl p-4" :style="{ backgroundColor: 'var(--dove-accent)' + '08' }">
              <p class="text-xs font-semibold uppercase tracking-wider mb-1" :style="{ color: 'var(--dove-muted)' }">
                {{ t('howItWorks.example') }}
              </p>
              <p class="font-venice text-lg" :style="{ color: 'var(--dove-accent)' }">
                San Marco 3456
              </p>
              <p class="text-xs mt-1" :style="{ color: 'var(--dove-muted)' }">
                {{ t('howItWorks.sestieriSystem.exampleDesc') }}
              </p>
            </div>
          </div>

          <!-- Zone normali system -->
          <div class="glass rounded-2xl p-6 md:p-8">
            <div
              class="w-10 h-10 rounded-xl flex items-center justify-center mb-4"
              :style="{ backgroundColor: 'rgba(75, 144, 184, 0.12)' }"
            >
              <svg width="20" height="20" viewBox="0 0 20 20" fill="none" stroke="#4A90B8" stroke-width="1.5">
                <path d="M2 6h16M2 10h16M2 14h10" />
              </svg>
            </div>
            <h3 class="font-display text-xl font-bold mb-2" :style="{ color: 'var(--dove-text)' }">
              {{ t('howItWorks.zoneSystem.title') }}
            </h3>
            <p class="text-sm leading-relaxed mb-4" :style="{ color: 'var(--dove-muted)' }">
              {{ t('howItWorks.zoneSystem.description') }}
            </p>
            <div class="rounded-xl p-4" :style="{ backgroundColor: '#4A90B8' + '08' }">
              <p class="text-xs font-semibold uppercase tracking-wider mb-1" :style="{ color: 'var(--dove-muted)' }">
                {{ t('howItWorks.example') }}
              </p>
              <p class="font-venice text-lg" :style="{ color: '#4A90B8' }">
                Via Garibaldi 84, Lido
              </p>
              <p class="text-xs mt-1" :style="{ color: 'var(--dove-muted)' }">
                {{ t('howItWorks.zoneSystem.exampleDesc') }}
              </p>
            </div>
          </div>
        </div>

        <!-- Stats bar -->
        <div class="grid grid-cols-2 md:grid-cols-4 gap-4 mb-16">
          <div v-for="stat in stats" :key="stat.label" class="text-center">
            <div class="font-venice text-3xl md:text-4xl" :style="{ color: 'var(--dove-accent)' }">
              {{ stat.value }}
            </div>
            <div class="text-xs mt-1" :style="{ color: 'var(--dove-muted)' }">
              {{ stat.label }}
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- Demo section -->
    <section class="section-spacing" :style="{ backgroundColor: 'var(--dove-surface)' }">
      <div class="max-w-6xl mx-auto">
        <h2
          class="font-display text-2xl md:text-3xl font-bold text-center mb-3"
          :style="{ color: 'var(--dove-text)' }"
        >
          {{ t('search.title') }}
        </h2>
        <p
          class="text-center text-sm max-w-lg mx-auto mb-10"
          :style="{ color: 'var(--dove-muted)' }"
        >
          {{ t('howItWorks.demoSubtitle') }}
        </p>

        <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
          <CiviciSearch />
          <CiviciMap />
        </div>
      </div>
    </section>
  </div>
</template>

<script setup>
const { t } = useI18n()

const stats = computed(() => [
  { value: '47.261', label: t('howItWorks.stats.civici') },
  { value: '7', label: t('howItWorks.stats.sestieri') },
  { value: '11', label: t('howItWorks.stats.zone') },
  { value: '508', label: t('howItWorks.stats.streets') },
])

useSeoMeta({
  title: () => t('nav.howItWorks'),
  description: () => t('meta.description'),
})
</script>
