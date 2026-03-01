<template>
  <section class="hero-section relative overflow-hidden">
    <!-- WebGL shader background -->
    <ClientOnly>
      <HeroShader />
    </ClientOnly>

    <!-- Content overlay -->
    <div class="relative z-10 max-w-6xl mx-auto flex flex-col items-center text-center">
      <img
        src="/img/logo-alt.svg"
        alt="DoVe"
        class="hero-logo w-56 md:w-72 lg:w-80"
        style="height: auto;"
      />
      <p
        class="font-display text-lg md:text-xl max-w-lg mt-6 leading-relaxed"
        :style="{ color: 'var(--dove-muted)' }"
      >
        {{ t('hero.subtitle') }}
      </p>
      <div class="flex flex-col sm:flex-row items-center gap-4 mt-10">
        <a
          href="#search"
          class="inline-flex items-center gap-2 px-7 py-3.5 rounded-full text-sm font-semibold no-underline transition-all hover:scale-105 hover:shadow-lg"
          :style="{ backgroundColor: 'var(--dove-accent)', color: 'white' }"
        >
          {{ t('hero.cta') }}
          <svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M3 8h10M9 4l4 4-4 4" />
          </svg>
        </a>
        <a
          href="#download"
          class="inline-flex items-center gap-2 px-7 py-3.5 rounded-full text-sm font-medium no-underline transition-all hover:scale-105"
          :style="{
            color: 'var(--dove-text)',
            backgroundColor: 'rgba(255,255,255,0.7)',
            backdropFilter: 'blur(12px)',
            border: '1px solid var(--dove-border)',
          }"
        >
          {{ t('hero.download') }}
        </a>
      </div>
    </div>
  </section>
</template>

<script setup>
const { t } = useI18n()
const localePath = useLocalePath()
</script>

<style scoped>
.hero-section {
  min-height: 85vh;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 6rem 1.5rem 5rem;
}

@media (min-width: 768px) {
  .hero-section {
    min-height: 90vh;
    padding: 8rem 2rem 6rem;
  }
}

.hero-logo {
  filter: drop-shadow(0 2px 12px rgba(42, 37, 32, 0.06));
}
</style>
