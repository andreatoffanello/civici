<script setup>
import mapboxgl from 'mapbox-gl' 
import { useStore } from '../stores/store'


const store = useStore()

mapboxgl.accessToken = 'pk.eyJ1IjoiYW5kcmVhdG9mZmFuZWxsbyIsImEiOiJjbG80Ym9sMGowMGYwMmtxdjhzbnV2ZXBlIn0.bS2_WoqZTKhaZ44fCZvUYg'

const mapContainer = ref(null)

let map

const initialPitch = 55

const initMap = () => {
    map = new mapboxgl.Map({
        container: mapContainer.value,
        style: 'mapbox://styles/andreatoffanello/clo4nfb7v00f901qxfr1c87kv',
        center: [12.335931181402884, 45.438053730947416],
        zoom: 13,
        pitch: initialPitch,
    })

    map.on('load', () => {
        // Aggiungi il layer per gli edifici in 3D
        map.addLayer({
            'id': '3d-buildings',
            'source': 'composite',
            'source-layer': 'building',
            'filter': ['==', 'extrude', 'true'],
            'type': 'fill-extrusion',
            'minzoom': 16, // Imposta il livello di zoom minimo
            'paint': {
                'fill-extrusion-color': '#aaa',
                'fill-extrusion-height': [
                    "interpolate", ["linear"], ["zoom"],
                    15, 0,
                    15.05, ["get", "height"]
                ],
                'fill-extrusion-base': [
                    "interpolate", ["linear"], ["zoom"],
                    15, 0,
                    15.05, ["get", "min_height"]
                ],
                'fill-extrusion-opacity': .4
            }
        })
    })
}


const flyToSestiere = (id) => {
    if (!map) return

    // rimuovi il vecchio layer con id 'sestiere'
    if (map.getLayer('sestiere')) {
        map.removeLayer('sestiere')
    }
    
    // rimuovi tutti i source
    Object.keys(map.getStyle().sources).forEach((source) => {
        if (source !== 'composite') {
            map.removeSource(source)
        }
    })

    // aggiungi il layer per il sestiere selezionato
    map.addSource(id, {
        type: 'geojson',
        data: store.sestieri[id].geojson
    })

    map.addLayer({
        'id': 'sestiere',
        'type': 'fill',
        'source': id,
        'layout': {},
        'paint': {
            'fill-color': store.sestieri[id].color,
            'fill-opacity': .4
        }
    })


    // muoviti e zoomma fino a comprendere store.sestieri[id].geojson nel viewport
    let bounds = new mapboxgl.LngLatBounds()

    store.sestieri[id].geojson.features.forEach((feature) => {
        if (feature.geometry.type === 'Polygon' || feature.geometry.type === 'MultiPolygon') {
            let coordinates = feature.geometry.coordinates
            coordinates.forEach(coordArray => {
                coordArray.forEach(coord => {
                    bounds.extend(coord)
                })
            })
        }
        // Aggiungi qui altri tipi di geometria se necessario
    })

    map.fitBounds(bounds, {
        padding: 50,
        pitch: initialPitch,
        bearing: 0,
        speed: 0.5,
        easing(t) {
            return t < 0.5 ? 4 * t * t * t : 1 - Math.pow(1 - t, 3) * 4
        }
    })
}

const populateSestiere = (id) => {
    if (!map) return
    // rimuovi tutti i marker
    document.querySelectorAll('.marker').forEach((marker) => marker.remove())
    // aggiungi alla mappa un marker html per ogni elemento in store.filteredNumbers
    store.filteredNumbers.slice(0,10).forEach((civico) => {
              
            const el = document.createElement('div')
            el.className = 'marker'
            el.style.backgroundColor = 'red'
            el.style.width = '20px'
            el.style.height = '20px'
            el.style.borderRadius = '50%'
            new mapboxgl.Marker(el)
                .setLngLat({ lng: civico.lng, lat: civico.lat })
                .addTo(map) 
    })
}


onMounted(() => {
    initMap()
})

watchEffect(() => {
    flyToSestiere(store.selectedSestiere)
})

</script>

<template>
    <div ref="mapContainer" id="mapContainer"></div>
    <!-- <div class="sestieri">
        <div v-for="sestiere in sestieri" :key="sestiere.id" class="sestiere" @click="flyToSestiere(sestiere)">
            {{ sestiere.name }}
        </div>
    </div> -->
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