<script setup>
import { ref, onMounted, watch } from 'vue'
import { useStore } from '../stores/store'

const store = useStore()

</script>

<template>
    <div ref="sestieri" class="sestieri">
        <div v-for="(sestiere, i) in store.sestieri" :key="sestiere.id" class="sestiere" @click="store.selectSestiere(i)">
            {{ sestiere.name }}
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
    display: flex;
    flex-direction: column;
}

.sestiere {
    text-align: center;
    padding: 2rem;
    box-sizing: border-box;
    font-size: 2rem;
    white-space: nowrap;
}

.active {
    background-color: #f0f0f0;
}
</style>
