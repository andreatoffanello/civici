<script setup>
import { useStore } from '@/stores/store'
const store = useStore()

onMounted(() => {
    store.selectedSestiere = null
})
</script>

<template>
    <div class="page">
        <div class="heading">
            <h1>Scegli il sestiere</h1>
        </div>
        <SestieriSelector/>
    </div>
</template>

<style lang="scss" scoped>
.page {
    display: grid;
    grid-template: auto 1fr;
    height: 100dvh;
    overflow: hidden;
}
</style>
