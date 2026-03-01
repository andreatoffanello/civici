<template>
  <div class="glass rounded-2xl p-6 flex flex-col gap-3">
    <div
      class="w-10 h-10 rounded-xl flex items-center justify-center"
      :style="{ backgroundColor: iconBg }"
    >
      <slot name="icon" />
    </div>
    <h3 class="font-display text-lg font-bold" :style="{ color: 'var(--dove-text)' }">
      {{ title }}
    </h3>
    <p class="text-sm leading-relaxed" :style="{ color: 'var(--dove-muted)' }">
      {{ description }}
    </p>
  </div>
</template>

<script setup>
defineProps({
  title: String,
  description: String,
  iconBg: {
    type: String,
    default: 'rgba(194, 69, 45, 0.12)',
  },
})
</script>
