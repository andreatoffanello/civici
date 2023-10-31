<script setup>

import { useStore } from '../stores/store'

const store = useStore()


</script>

<template>
    <div class="page">
        <Map/>
        <SestieriSelector/>

        <p v-for="(civico, i) in store.filteredNumbers" :key="i">
            {{ civico }}
        </p>

    </div>
</template>

<style lang="scss" scoped>

</style>