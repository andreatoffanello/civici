<template>
  <section class="section-spacing">
    <div class="max-w-4xl mx-auto">

      <!-- Headline -->
      <div class="text-center mb-12 md:mb-16">
        <h2
          class="font-display text-3xl md:text-5xl font-bold leading-tight mb-6"
          :style="{ color: 'var(--dove-text)' }"
        >
          {{ t('problem.headline') }}
        </h2>
        <p
          class="text-base md:text-lg max-w-2xl mx-auto leading-relaxed"
          :style="{ color: 'var(--dove-muted)' }"
        >
          {{ t('problem.body') }}
        </p>
      </div>

      <!-- Two systems -->
      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">

        <!-- Sestieri -->
        <div
          class="glass rounded-2xl p-6 md:p-8"
        >
          <div
            class="w-10 h-10 rounded-xl flex items-center justify-center mb-5"
            :style="{ backgroundColor: 'rgba(194, 69, 45, 0.12)' }"
          >
            <svg width="20" height="20" viewBox="0 0 20 20" fill="none" stroke="var(--dove-accent)" stroke-width="1.5">
              <rect x="2" y="2" width="7" height="7" rx="1.5" />
              <rect x="11" y="2" width="7" height="7" rx="1.5" />
              <rect x="2" y="11" width="7" height="7" rx="1.5" />
              <rect x="11" y="11" width="7" height="7" rx="1.5" />
            </svg>
          </div>
          <h3
            class="font-display text-lg font-bold mb-2"
            :style="{ color: 'var(--dove-text)' }"
          >
            {{ t('problem.sestieriTitle') }}
          </h3>
          <p
            class="text-sm leading-relaxed mb-5"
            :style="{ color: 'var(--dove-muted)' }"
          >
            {{ t('problem.sestieriDesc') }}
          </p>
          <div
            class="rounded-xl px-4 py-3"
            :style="{ backgroundColor: 'rgba(194, 69, 45, 0.06)' }"
          >
            <p
              class="text-xs font-semibold uppercase tracking-wider mb-1"
              :style="{ color: 'var(--dove-muted)' }"
            >
              {{ t('howItWorks.example') }}
            </p>
            <p class="font-venice text-xl" :style="{ color: 'var(--dove-accent)' }">
              San Marco 3456
            </p>
            <p class="text-xs mt-1" :style="{ color: 'var(--dove-muted)' }">
              {{ t('howItWorks.sestieriSystem.exampleDesc') }}
            </p>
          </div>
        </div>

        <!-- Isole -->
        <div class="glass rounded-2xl p-6 md:p-8">
          <div
            class="w-10 h-10 rounded-xl flex items-center justify-center mb-5"
            :style="{ backgroundColor: 'rgba(74, 144, 184, 0.12)' }"
          >
            <svg width="20" height="20" viewBox="0 0 20 20" fill="none" stroke="#4A90B8" stroke-width="1.5">
              <path d="M10 2a6 6 0 0 1 6 6c0 4.5-6 10-6 10S4 12.5 4 8a6 6 0 0 1 6-6z" />
              <circle cx="10" cy="8" r="2" />
            </svg>
          </div>
          <h3
            class="font-display text-lg font-bold mb-2"
            :style="{ color: 'var(--dove-text)' }"
          >
            {{ t('problem.isoleTitle') }}
          </h3>
          <p
            class="text-sm leading-relaxed mb-5"
            :style="{ color: 'var(--dove-muted)' }"
          >
            {{ t('problem.isoleDesc') }}
          </p>
          <div
            class="rounded-xl px-4 py-3"
            :style="{ backgroundColor: 'rgba(74, 144, 184, 0.06)' }"
          >
            <p
              class="text-xs font-semibold uppercase tracking-wider mb-1"
              :style="{ color: 'var(--dove-muted)' }"
            >
              {{ t('howItWorks.example') }}
            </p>
            <p class="font-venice text-xl" style="color: #4A90B8;">
              Via Garibaldi 84, Lido
            </p>
            <p class="text-xs mt-1" :style="{ color: 'var(--dove-muted)' }">
              {{ t('howItWorks.zoneSystem.exampleDesc') }}
            </p>
          </div>
        </div>

      </div>
    </div>
  </section>
</template>

<script setup>
const { t } = useI18n()
</script>
