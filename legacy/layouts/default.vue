<script setup>
</script>

<template>
    <div class="wrapper">
        <Map/>
        <slot />
    </div>
</template>

<style scoped>
.wrapper {
    position: relative;
    width: 100%;
    height: 100dvh;
}
</style>