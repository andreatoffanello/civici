<template>
  <div class="section-spacing">
    <div class="max-w-2xl mx-auto">
      <h1
        class="font-display text-3xl md:text-5xl font-bold mb-8"
        :style="{ color: 'var(--dove-text)' }"
      >
        {{ t('contact.title') }}
      </h1>
      <ContentRenderer v-if="page" :value="page" class="prose" />
    </div>
  </div>
</template>

<script setup>
const { t, locale } = useI18n()

const { data: page } = await useAsyncData(`contatti-${locale.value}`, () =>
  queryCollection('content').path(`/${locale.value}/contatti`).first()
)

useSeoMeta({
  title: () => t('contact.title'),
})
</script>
