<template>
  <section class="section-spacing">
    <div class="max-w-5xl mx-auto">
      <div class="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-3">
        <NuxtLink
          v-for="s in sestieri"
          :key="s.code"
          :to="localePath('/come-funziona')"
          class="rounded-2xl p-5 flex flex-col gap-1 transition-all hover:scale-[1.02] no-underline border"
          :style="{
            borderColor: 'var(--dove-border)',
            backgroundColor: 'var(--dove-surface-solid)',
          }"
        >
          <span
            class="text-xs font-semibold uppercase tracking-wider"
            :style="{ color: s.color }"
          >
            {{ s.code }}
          </span>
          <span class="font-venice text-base" :style="{ color: 'var(--dove-text)' }">
            {{ t(`sestieri.${s.code}`) }}
          </span>
          <span class="text-xs" :style="{ color: 'var(--dove-muted)' }">
            {{ s.range }}
          </span>
        </NuxtLink>
      </div>
    </div>
  </section>
</template>

<script setup>
const { t } = useI18n()
const localePath = useLocalePath()

const sestieri = [
  { code: 'CN', color: '#4A90B8', range: '1 – 6.420' },
  { code: 'CS', color: '#5BA86B', range: '1 – 6.828' },
  { code: 'DD', color: '#D4A843', range: '1 – 3.901' },
  { code: 'GD', color: '#8B7BB8', range: '1 – 907' },
  { code: 'SM', color: '#D4885A', range: '1 – 5.562' },
  { code: 'SP', color: '#5AACAC', range: '1 – 3.144' },
  { code: 'SC', color: '#C76B7A', range: '1 – 2.362' },
]
</script>
