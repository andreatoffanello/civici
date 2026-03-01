<template>
  <section class="section-spacing relative overflow-hidden">
    <div class="max-w-6xl mx-auto">
      <div class="flex flex-col lg:flex-row items-center gap-12 lg:gap-16">
        <!-- Left: logo + text -->
        <div class="flex-1 text-center lg:text-left">
          <img
            src="/img/logo-alt.svg"
            alt="DoVe"
            class="w-48 md:w-64 lg:w-72 mx-auto lg:mx-0"
            style="height: auto;"
          />
          <p
            class="font-display text-lg md:text-xl max-w-md mt-8 mx-auto lg:mx-0"
            :style="{ color: 'var(--dove-muted)', lineHeight: '1.6' }"
          >
            {{ t('hero.subtitle') }}
          </p>
          <div class="flex flex-col sm:flex-row items-center lg:items-start gap-4 mt-10">
            <NuxtLink
              :to="localePath('/come-funziona')"
              class="inline-flex items-center gap-2 px-6 py-3 rounded-full text-sm font-semibold no-underline transition-transform hover:scale-105"
              :style="{ backgroundColor: 'var(--dove-accent)', color: 'white' }"
            >
              {{ t('hero.cta') }}
              <svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M3 8h10M9 4l4 4-4 4" />
              </svg>
            </NuxtLink>
            <a
              href="#download"
              class="inline-flex items-center gap-2 px-6 py-3 rounded-full text-sm font-medium no-underline glass transition-transform hover:scale-105"
              :style="{ color: 'var(--dove-text)' }"
            >
              {{ t('hero.download') }}
            </a>
          </div>
        </div>

        <!-- Right: interactive Venice map -->
        <div class="flex-1 flex justify-center">
          <VeniceMap @select="onSestiereSelect" />
        </div>
      </div>
    </div>
  </section>
</template>

<script setup>
const { t } = useI18n()
const localePath = useLocalePath()
const router = useRouter()

function onSestiereSelect(code) {
  router.push(localePath('/come-funziona'))
}
</script>
