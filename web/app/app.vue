<template>
  <NuxtLayout>
    <NuxtPage />
  </NuxtLayout>
</template>

<script setup>
const { t } = useI18n()

useHead({
  titleTemplate: (titleChunk) => {
    return titleChunk ? `${titleChunk} — DoVe` : t('meta.title')
  },
})

useSeoMeta({
  ogSiteName: 'DoVe',
  ogType: 'website',
  twitterCard: 'summary_large_image',
})
</script>
