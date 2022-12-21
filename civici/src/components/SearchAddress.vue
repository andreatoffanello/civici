<script setup>
import { useStore } from '../stores/Store';
import { gsap } from "gsap";
import { Draggable } from "gsap/Draggable";
import { InertiaPlugin } from "gsap/InertiaPlugin";
import { onMounted } from '@vue/runtime-core';

gsap.registerPlugin(Draggable, InertiaPlugin);

const store = useStore()

onMounted(() => {
    var listHeight = 120

    Draggable.create(".blocks", {
        type: "scroll",
        throwProps: true,
        
        snap: function (endValue) {
            return -Math.round(endValue / listHeight) * listHeight;
        }
    });
})

</script>

<template>

    <div class="search_block" v-if="!store.selectedNum">

        <div class="blocks">

            <template v-for="(block, i) in store.blocks" :key="i">

                <div class="block" @click="store.selectBlock(i)">
                    <span>{{ block.name }}</span>
                </div>

            </template>

        </div>

        <!-- <input type="text" v-model="store.searchedNum">

        <div class="numbers" v-if="store.filteredNumbers">

            <template v-for="(number, i) in store.filteredNumbers" :key="i">

                <div class="number" @click="store.selectNumber(number)">
                    <span>{{ number.id }}</span>
                </div>

            </template>

        </div> -->

    </div>

</template>

<style lang="scss">
.search_block {
    height: 100%;
    background: black;
    position: relative;
    z-index: 2;
}

.blocks {
    color: white;
    position: relative;
    top: 30vh;
    height: 36rem;
    overflow: visible;
}

.block {
    height: 12rem;
    font-size: 6.4rem;
}

.numbers {
    color: white;
}
</style>