<template>
  <div class="relative">
    <button
      class="flex items-center gap-1 text-sm font-medium px-2 py-1 rounded-lg transition-colors"
      :style="{ color: 'var(--dove-muted)' }"
      @click="open = !open"
    >
      {{ currentLocale?.code?.toUpperCase() }}
      <svg width="12" height="12" viewBox="0 0 12 12" fill="currentColor">
        <path d="M3 5l3 3 3-3" stroke="currentColor" stroke-width="1.5" fill="none" />
      </svg>
    </button>

    <Transition name="fade">
      <div
        v-if="open"
        class="absolute right-0 top-full mt-2 py-1 rounded-xl glass shadow-lg min-w-[120px]"
      >
        <button
          v-for="loc in locales"
          :key="loc.code"
          class="w-full text-left px-3 py-2 text-sm transition-colors hover:bg-black/5"
          :class="{ 'font-semibold': loc.code === locale }"
          :style="{ color: loc.code === locale ? 'var(--dove-accent)' : 'var(--dove-text)' }"
          @click="switchTo(loc.code)"
        >
          {{ loc.name }}
        </button>
      </div>
    </Transition>
  </div>
</template>

<script setup>
const { locale, locales: availableLocales } = useI18n()
const switchLocalePath = useSwitchLocalePath()
const router = useRouter()
const open = ref(false)

const currentLocale = computed(() =>
  availableLocales.value.find((l) => l.code === locale.value)
)

const locales = computed(() => availableLocales.value)

function switchTo(code) {
  open.value = false
  navigateTo(switchLocalePath(code))
}

// Close on click outside
if (import.meta.client) {
  const handler = (e) => {
    if (!e.target.closest('.relative')) open.value = false
  }
  onMounted(() => document.addEventListener('click', handler))
  onUnmounted(() => document.removeEventListener('click', handler))
}
</script>

<style scoped>
.fade-enter-active,
.fade-leave-active {
  transition: all 0.15s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
  transform: translateY(-4px);
}
</style>
