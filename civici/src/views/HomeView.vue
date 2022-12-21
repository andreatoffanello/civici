<script setup>
import { RouterLink } from 'vue-router'
</script>

<template>
	<div>

		<router-link 
			class="button"
			:to="{name: 'search'}">

			<span>Cerca</span>
		
		</router-link>

	</div>

</template>

<style scoped>

</style>
