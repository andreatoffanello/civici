<template>
  <section class="section-spacing overflow-hidden">
    <div class="max-w-5xl mx-auto">

      <h2
        class="font-display text-3xl md:text-4xl font-bold text-center mb-4"
        :style="{ color: 'var(--dove-text)' }"
      >
        {{ t('showcase.title') }}
      </h2>

      <!-- Features -->
      <div class="flex flex-col sm:flex-row justify-center gap-8 sm:gap-16 mb-14">
        <div
          v-for="feature in features"
          :key="feature.key"
          class="flex flex-col items-center text-center sm:items-start sm:text-left max-w-[200px] mx-auto sm:mx-0"
        >
          <div
            class="w-9 h-9 rounded-lg flex items-center justify-center mb-2"
            :style="{ backgroundColor: feature.bg }"
          >
            <component :is="feature.icon" />
          </div>
          <p class="text-sm font-semibold mb-0.5" :style="{ color: 'var(--dove-text)' }">
            {{ t(`showcase.${feature.key}Title`) }}
          </p>
          <p class="text-xs leading-relaxed" :style="{ color: 'var(--dove-muted)' }">
            {{ t(`showcase.${feature.key}Desc`) }}
          </p>
        </div>
      </div>

      <!-- Three phones -->
      <div class="phones-row">
        <div
          v-for="(screen, i) in screens"
          :key="i"
          class="phone-wrap"
          :class="`phone-${i}`"
        >
          <div class="step-badge">{{ i + 1 }}</div>
          <div class="phone-frame">
            <img
              :src="`/img/screens/${screen.file}`"
              :alt="screen.label"
              class="phone-screen"
            />
          </div>
          <p class="step-label">{{ screen.label }}</p>
        </div>
      </div>

    </div>
  </section>
</template>

<script setup>
import { h } from 'vue'

const { t } = useI18n()

const IconOffline = () => h('svg', { width: 18, height: 18, viewBox: '0 0 20 20', fill: 'none', stroke: 'var(--dove-accent)', 'stroke-width': 1.5 }, [
  h('path', { d: 'M3 10a7 7 0 0 1 14 0' }),
  h('path', { d: 'M6 10a4 4 0 0 1 8 0' }),
  h('circle', { cx: 10, cy: 10, r: 1.5, fill: 'var(--dove-accent)', stroke: 'none' }),
])

const IconPin = () => h('svg', { width: 18, height: 18, viewBox: '0 0 20 20', fill: 'none', stroke: '#4A90B8', 'stroke-width': 1.5 }, [
  h('path', { d: 'M10 2a5 5 0 0 1 5 5c0 4-5 9-5 9S5 11 5 7a5 5 0 0 1 5-5z' }),
  h('circle', { cx: 10, cy: 7, r: 1.8 }),
])

const IconFree = () => h('svg', { width: 18, height: 18, viewBox: '0 0 20 20', fill: 'none', stroke: '#5BA86B', 'stroke-width': 1.5 }, [
  h('path', { d: 'M10 2l2.5 5 5.5.8-4 3.9.95 5.5L10 14.7l-4.95 2.5.95-5.5-4-3.9 5.5-.8z' }),
])

const features = [
  { key: 'feature1', bg: 'rgba(194, 69, 45, 0.1)', icon: IconOffline },
  { key: 'feature2', bg: 'rgba(74, 144, 184, 0.1)', icon: IconPin },
  { key: 'feature3', bg: 'rgba(91, 168, 107, 0.1)', icon: IconFree },
]

const screens = computed(() => [
  { file: '1-home.png', label: t('search.selectSestiere') },
  { file: '2-ricerca.png', label: t('search.inputNumber') },
  { file: '3-mappa.png', label: t('search.openMaps') },
])
</script>

<style scoped>
.phones-row {
  display: flex;
  justify-content: center;
  align-items: flex-end;
  gap: 1rem;
  padding: 2rem 0 1rem;
}

.phone-wrap {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.75rem;
  position: relative;
  flex: 1;
  max-width: 200px;
}

/* middle phone slightly larger and raised */
.phone-0 { transform: translateY(24px) rotate(-3deg); }
.phone-1 { transform: translateY(0px) scale(1.04); z-index: 2; }
.phone-2 { transform: translateY(24px) rotate(3deg); }

.phone-frame {
  width: 100%;
  background: #1c1c1e;
  border-radius: 40px;
  padding: 9px;
  box-shadow:
    0 0 0 1.5px #3a3a3c,
    0 24px 48px rgba(0, 0, 0, 0.18),
    0 8px 24px rgba(0, 0, 0, 0.1);
}

.phone-screen {
  border-radius: 32px;
  width: 100%;
  display: block;
}

.step-badge {
  width: 24px;
  height: 24px;
  border-radius: 50%;
  background-color: var(--dove-accent);
  color: white;
  font-size: 11px;
  font-weight: 700;
  display: flex;
  align-items: center;
  justify-content: center;
  position: absolute;
  top: -10px;
  right: -4px;
  z-index: 3;
}

.step-label {
  font-size: 11px;
  color: var(--dove-muted);
  text-align: center;
  letter-spacing: 0.02em;
}

@media (max-width: 480px) {
  .phones-row {
    gap: 0.5rem;
  }
  .phone-0, .phone-2 {
    transform: translateY(16px) rotate(-2deg);
  }
  .phone-0 { rotate: -2deg; }
  .phone-2 { rotate: 2deg; }
}
</style>
