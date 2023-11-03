<script setup>

import { useStore } from '../stores/store'

const store = useStore()

const handleClick = () => {
    navigateTo('/sestieri')
}

</script>

<template>
    <div class="page">
        <div class="heading align-center">
            <h1 class="color-accent-2 text-xxxlarge bold">Find in Venice</h1>
            
            <p class="text-large bold">Trova la posizione reale dei numeri civici nei sestieri di Venezia.</p>
        </div>

        <div class="button" @click="handleClick()">
            <span class="venice text-large">Inizia la ricerca</span>
            <span class="text-xlarge">➵</span>
        </div>
    </div>
</template>

<style lang="scss" scoped>

.heading {
    padding: 8rem var(--space-large);
}

.button {
    display: flex;
    justify-content: center;
    align-items: center;
    gap: var(--space-sm);
    border: .2rem solid var(--color-accent-2);
}

</style>