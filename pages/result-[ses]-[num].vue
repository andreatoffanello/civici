<script setup>
import { useStore } from '@/stores/store'
const store = useStore()
const route = useRoute()
const ses = route.params.ses
const num = route.params.num

onMounted(() => {
    
    store.selectedAddress = {
        label: `${ses} ${num}`,
        coordinates: {
            lat: store.civici[ses][num].lat,
            lng: store.civici[ses][num].lng
        }
    }
    
})

</script>

<template>
    <div>
        
    </div>
</template>