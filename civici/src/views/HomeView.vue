<script setup>
import { onMounted } from '@vue/runtime-core';
import mapboxgl from 'mapbox-gl'; // or "const mapboxgl = require('mapbox-gl');"
import SearchAddress from '../components/SearchAddress.vue';

const initMap = () => {
  mapboxgl.accessToken = 'pk.eyJ1IjoiYW5kcmVhdG9mZmFuZWxsbyIsImEiOiJjajNweWwxdnYwMDNxMndxZHkwNTBieHJzIn0.5ZJqJs29sA9UNOxNr0Fq_A';
  const map = new mapboxgl.Map({
    container: 'map', // container ID
    style: 'mapbox://styles/mapbox/streets-v12', // style URL
    center: [12.335890866252527,45.43778525602261], // starting position [lng, lat]
    zoom: 9 // starting zoom
  });
}

onMounted(()=>{
  initMap()
})

</script>

<template>
  <div id="map"></div>

  <SearchAddress />

</template>

<style scoped>
#map {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
}
</style>>
