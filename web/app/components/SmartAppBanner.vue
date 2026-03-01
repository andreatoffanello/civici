<template>
  <Transition name="slide-down">
    <div
      v-if="visible"
      class="md:hidden flex items-center gap-3 px-4 py-3 border-b"
      :style="{ backgroundColor: 'var(--dove-surface-solid)', borderColor: 'var(--dove-border)' }"
    >
      <button
        class="shrink-0 text-lg leading-none"
        :style="{ color: 'var(--dove-muted)' }"
        @click="dismiss"
        aria-label="Chiudi"
      >
        &times;
      </button>

      <!-- App icon placeholder -->
      <div
        class="shrink-0 w-10 h-10 rounded-xl flex items-center justify-center font-venice text-sm"
        :style="{ backgroundColor: 'var(--dove-accent)', color: 'white' }"
      >
        DV
      </div>

      <div class="flex-1 min-w-0">
        <p class="text-sm font-semibold truncate" :style="{ color: 'var(--dove-text)' }">DoVe</p>
        <p class="text-xs" :style="{ color: 'var(--dove-muted)' }">{{ t('banner.free') }}</p>
      </div>

      <a
        :href="storeUrl"
        target="_blank"
        rel="noopener"
        class="shrink-0 px-4 py-1.5 rounded-full text-sm font-semibold no-underline"
        :style="{ backgroundColor: 'var(--dove-accent)', color: 'white' }"
      >
        {{ t('banner.open') }}
      </a>
    </div>
  </Transition>
</template>

<script setup>
const { t } = useI18n()

const APP_STORE_URL = 'https://apps.apple.com/app/dove-venezia/id0000000000'
const PLAY_STORE_URL = 'https://play.google.com/store/apps/details?id=com.dovevenezia.app'
const DISMISS_KEY = 'dove_banner_dismissed'
const DISMISS_DAYS = 7

const visible = ref(false)
const isIOS = ref(false)

const storeUrl = computed(() => isIOS.value ? APP_STORE_URL : PLAY_STORE_URL)

function dismiss() {
  visible.value = false
  if (import.meta.client) {
    localStorage.setItem(DISMISS_KEY, Date.now().toString())
  }
}

onMounted(() => {
  const ua = navigator.userAgent
  const isMobile = /iPhone|iPad|iPod|Android/i.test(ua)
  isIOS.value = /iPhone|iPad|iPod/i.test(ua)

  if (!isMobile) return

  const dismissed = localStorage.getItem(DISMISS_KEY)
  if (dismissed) {
    const daysAgo = (Date.now() - parseInt(dismissed)) / (1000 * 60 * 60 * 24)
    if (daysAgo < DISMISS_DAYS) return
  }

  visible.value = true
})
</script>

<style scoped>
.slide-down-enter-active,
.slide-down-leave-active {
  transition: all 0.3s ease;
}

.slide-down-enter-from,
.slide-down-leave-to {
  opacity: 0;
  transform: translateY(-100%);
}
</style>
