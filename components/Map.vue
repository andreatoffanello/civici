<script setup>
import mapboxgl from 'mapbox-gl' 

mapboxgl.accessToken = 'pk.eyJ1IjoiYW5kcmVhdG9mZmFuZWxsbyIsImEiOiJjbG80Ym9sMGowMGYwMmtxdjhzbnV2ZXBlIn0.bS2_WoqZTKhaZ44fCZvUYg'

const mapContainer = ref(null)

let map

const initMap = () => {
    map = new mapboxgl.Map({
        container: mapContainer.value,
        style: 'mapbox://styles/andreatoffanello/clo4d9r1000m301qv3op614il',
        center: [12.335931181402884, 45.438053730947416],
        zoom: 13,
        pitch: 45,
    })
}


onMounted(() => {
    initMap()

    map.on('load', () => {
        // Usa la funzione 'queryRenderedFeatures' per ottenere le features del layer che ti interessa
        // const features = map.queryRenderedFeatures({ layers: ['nome_del_layer'] })

        // Ora 'features' contiene i dati delle aree o quartieri


        for (const layerId in map.style._layers) {
            console.log(layerId) // Questo sarà l'ID del layer
        }
    })
})

</script>

<template>
    <div ref="mapContainer" id="mapContainer"></div>
</template>

<style lang="scss" scoped>

#mapContainer {
    width: 100%;
    height: 100%;
    position: absolute;
    top: 0;
    left: 0;
}
    
</style>