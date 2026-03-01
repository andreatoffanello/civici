<template>
  <div class="section-spacing">
    <div class="max-w-2xl mx-auto">
      <h1
        class="font-display text-3xl md:text-5xl font-bold mb-8"
        :style="{ color: 'var(--dove-text)' }"
      >
        {{ t('support.title') }}
      </h1>
      <ContentRenderer v-if="page" :value="page" class="prose" />
    </div>
  </div>
</template>

<script setup>
const { t, locale } = useI18n()

const { data: page } = await useAsyncData(`supporto-${locale.value}`, () =>
  queryCollection('content').path(`/${locale.value}/supporto`).first()
)

useSeoMeta({
  title: () => t('support.title'),
})
</script>
