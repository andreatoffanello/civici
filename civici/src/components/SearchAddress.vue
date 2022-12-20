<script setup>
import { useStore } from '../stores/Store';

const store = useStore()

</script>

<template>

    <div class="search_wrapper">

        <div class="blocks">

            <template v-for="(block, i) in store.blocks" :key="i">

                <div class="block" @click="store.selectBlock(i)">
                    <span>{{ block.name }}</span>
                </div>

            </template>

        </div>

        <input type="text" v-model="store.searchedNum">

        <div class="numbers" v-if="store.filteredNumbers">
            
            <template v-for="(number, i) in store.filteredNumbers" :key="i">

                <div class="number" @click="store.selectNumber(number)">
                    <span>{{ number.id }}</span>
                </div>
                
            </template>

        </div>

    </div>

    

    
    
</template>

<style lang="scss">

.search_wrapper {
    height: 100%;
    background: black;
    position: relative;
    z-index: 2;
}

.blocks {
    color: white;
}

.numbers {
    color: white;
}



</style>