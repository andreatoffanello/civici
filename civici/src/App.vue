<script setup>
import { onMounted } from '@vue/runtime-core';
import { RouterLink, RouterView } from 'vue-router'
import { useStore } from './stores/Store';

const store = useStore()

onMounted( async () => {
  await store.loadAddresses()
})
</script>

<template>

<RouterView />

</template>

<style scoped>

</style>
