<template>
  <div>
    <HeroSection />

    <!-- Features -->
    <section class="section-spacing">
      <div class="max-w-5xl mx-auto">
        <h2
          class="font-display text-2xl md:text-3xl font-bold text-center mb-12"
          :style="{ color: 'var(--dove-text)' }"
        >
          {{ t('features.title') }}
        </h2>
        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
          <FeatureCard
            :title="t('features.offline.title')"
            :description="t('features.offline.description')"
          >
            <template #icon>
              <svg width="20" height="20" viewBox="0 0 20 20" fill="none" stroke="var(--dove-accent)" stroke-width="1.5">
                <path d="M3 10a7 7 0 0 1 14 0" />
                <path d="M6 10a4 4 0 0 1 8 0" />
                <circle cx="10" cy="10" r="1.5" fill="var(--dove-accent)" stroke="none" />
              </svg>
            </template>
          </FeatureCard>
          <FeatureCard
            :title="t('features.sestieri.title')"
            :description="t('features.sestieri.description')"
          >
            <template #icon>
              <svg width="20" height="20" viewBox="0 0 20 20" fill="none" stroke="var(--dove-accent)" stroke-width="1.5">
                <rect x="2" y="2" width="7" height="7" rx="1.5" />
                <rect x="11" y="2" width="7" height="7" rx="1.5" />
                <rect x="2" y="11" width="7" height="7" rx="1.5" />
                <rect x="11" y="11" width="7" height="7" rx="1.5" />
              </svg>
            </template>
          </FeatureCard>
          <FeatureCard
            :title="t('features.precise.title')"
            :description="t('features.precise.description')"
          >
            <template #icon>
              <svg width="20" height="20" viewBox="0 0 20 20" fill="none" stroke="var(--dove-accent)" stroke-width="1.5">
                <path d="M10 2a6 6 0 0 1 6 6c0 4.5-6 10-6 10S4 12.5 4 8a6 6 0 0 1 6-6z" />
                <circle cx="10" cy="8" r="2" />
              </svg>
            </template>
          </FeatureCard>
          <FeatureCard
            :title="t('features.free.title')"
            :description="t('features.free.description')"
          >
            <template #icon>
              <svg width="20" height="20" viewBox="0 0 20 20" fill="none" stroke="var(--dove-accent)" stroke-width="1.5">
                <path d="M10 2l8 4-8 4-8-4z" />
                <path d="M2 10l8 4 8-4" />
              </svg>
            </template>
          </FeatureCard>
        </div>
      </div>
    </section>

    <SestieriGrid />
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
