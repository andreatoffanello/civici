<script setup>
import { useStore } from '@/stores/store'

const store = useStore()

const route = useRoute()

const id = route.params.id

onMounted(() => {
    store.selectedSestiere = id
    store.selectedAddress = null
})

const handleClick = (num) => {
    navigateTo(`/result-${id}-${num}`)
}

</script>

<template>
    <div>
        <div class="heading align-center">
            <span class="venice text-large">{{ store.sestieri[id].name }}</span>
        </div>
        
        <div class="input-wrapper align-center">
            <input class="align-center text-large venice" type="number" v-model="store.filterNumber" placeholder="Numero">
        </div>
        

        <div class="results align-center">
            <transition-group name="fadeUp" tag="div">

                <div class="result-single" v-for="(result, i) in store.filteredNumbers.slice(0,21)" :key="result" @click="handleClick(result)">
                <span class="venice color-accent-2 text-regular">{{ result  }}</span>
            </div>
            </transition-group>
        </div>
    </div>
</template>

<style lang="scss" scoped>
.fadeUp-move,
.fadeUp-enter-active,
.fadeUp-leave-active {
  transition: all 0.5s ease;
}
.fadeUp-enter-from,
.fadeUp-leave-to {
  opacity: 0;
}

.fadeUp-leave-active {
  position: absolute;
}

.heading {
    padding: var(--space-lg) var(--space-md);
}

.input-wrapper {
    padding: var(--space-md);

    input {
        border: 0;
        background: none;
        outline: none;
        border-bottom: .2rem solid var(--color-accent-2);
        text-align: center;
    }
}

.result-single {
    display: inline-block;
    padding: var(--space-sm) var(--space-md);
    background: var(--color-white);
    border: .2rem solid var(--color-accent-2);
    text-align: center;
    color: var(--color-white);
    margin: var(--space-sm);
    border-radius: .4rem;
}
</style>