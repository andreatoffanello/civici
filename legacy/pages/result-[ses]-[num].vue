<script setup>
import { useStore } from '@/stores/store'
const store = useStore()
const route = useRoute()
const ses = route.params.ses
const num = route.params.num

const handleClick = () => {
    window.open(`https://www.google.com/maps?q=${store.civici[ses][num].lat},${store.civici[ses][num].lng}`, '_blank')
}

onMounted(() => {
    store.selectedAddress = {
        label: `${store.sestieri[ses].name} ${num}`,
        coordinates: {
            lat: store.civici[ses][num].lat,
            lng: store.civici[ses][num].lng
        }
    }
})

</script>

<template>
    <div>
        <div class="heading">
            <h1 class="venice text-xlarge align-center color-main">{{ store.selectedAddress?.label.toLowerCase() }}</h1>
        </div>

        <div class="bottom">
            <div class="button" @click="handleClick()">
                <span class="text-regular bold">Apri sulla tua mappa</span>
                <span class=""></span>
            </div>
        </div>
        
    </div>
</template>

<style lang="scss" scoped>
.heading {
    padding: var(--space-md);
}

.bottom {
    position: fixed;
    bottom: 0;
    left: 0;
    right: 0;
    padding: var(--space-md);
    background-color: var(--color-main);
    color: var(--color-white);
    display: flex;
    justify-content: center;
    align-items: center;
}
</style>