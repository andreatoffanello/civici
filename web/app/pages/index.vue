<template>
  <div>
    <HeroSection />
    <ProblemSection />
    <AppShowcase />

    <!-- Search demo -->
    <section id="search" class="section-spacing" :style="{ backgroundColor: 'var(--dove-surface)' }">
      <div class="max-w-6xl mx-auto">
        <h2
          class="font-display text-2xl md:text-3xl font-bold text-center mb-3"
          :style="{ color: 'var(--dove-text)' }"
        >
          {{ t('searchDemo.title') }}
        </h2>
        <p
          class="text-center text-sm max-w-lg mx-auto mb-10"
          :style="{ color: 'var(--dove-muted)' }"
        >
          {{ t('searchDemo.subtitle') }}
        </p>
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
          <CiviciSearch />
          <CiviciMap />
        </div>
      </div>
    </section>

    <DownloadCta />
  </div>
</template>

<script setup>
const { t } = useI18n()

useSeoMeta({
  title: () => t('meta.title'),
  ogTitle: () => t('meta.title'),
  description: () => t('meta.description'),
  ogDescription: () => t('meta.description'),
})
</script>
