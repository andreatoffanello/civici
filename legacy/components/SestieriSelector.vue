<script setup>
import { ref, onMounted, watch } from 'vue'
import { useStore } from '../stores/store'

const store = useStore()

const handleClick = (i) => {
    store.selectSestiere(i)
    navigateTo(`/sestiere-${i}`)
}

</script>

<template>
    <div ref="sestieri" class="sestieri">
        <div v-for="(sestiere, i) in store.sestieri" :key="sestiere.id" class="sestiere" @click="handleClick(i)">
            <span class="venice text-xlarge">{{ sestiere.name }}</span>
        </div>
    </div>
</template>
s
<style lang="scss" scoped>
.carousel-wrapper {
    overflow: hidden;
    width: 100%; // Assuming each child is 100px
}

.sestieri {
    position: relative;
    overflow: auto;
}

.sestiere {
    text-align: center;
    padding: var(--space-md) var(--space-md);
    box-sizing: border-box;
    white-space: nowrap;
}

.active {
    background-color: #f0f0f0;
}
</style>
