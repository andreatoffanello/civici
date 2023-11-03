<script setup>
import mapboxgl from 'mapbox-gl' 
import { useStore } from '../stores/store'


const store = useStore()

mapboxgl.accessToken = 'pk.eyJ1IjoiYW5kcmVhdG9mZmFuZWxsbyIsImEiOiJjbG80Ym9sMGowMGYwMmtxdjhzbnV2ZXBlIn0.bS2_WoqZTKhaZ44fCZvUYg'

const mapContainer = ref(null)

let map

const initialPitch = 55
const initialZoom = 13

const initMap = () => {
    map = new mapboxgl.Map({
        container: mapContainer.value,
        style: 'mapbox://styles/andreatoffanello/clo4nfb7v00f901qxfr1c87kv',
        // center: [12.335931181402884, 45.438053730947416],
        // zoom: 0,
        // bearing: 200,
        antialias: true,
        // opacity 0
        fadeDuration: 1000,
    })

    // set map initial properties
    
    map.on('load', () => {
        map.setZoom(0)
        map.setBearing(200)
        map.setPitch(0)

        if (!map.isStyleLoaded()) {
            return
        }

        mapContainer.value.style.opacity = 1

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

        if (store.selectedAddress) return
        

        map.flyTo({
            center: [12.335931181402884, 45.438053730947416],
            zoom: initialZoom,
            pitch: initialPitch,
            bearing: 0,
            duration: 10000,
            easing(t) {
                return t < 0.5 ? 4 * t * t * t : 1 - Math.pow(1 - t, 3) * 4
            }
        })
    })
}

const resetMap = () => {
    if (!map) return
    // rimuovi il vecchio layer con id 'sestiere'
    if (map.getLayer('sestiere')) {
        map.removeLayer('sestiere')
    }

    document.querySelectorAll('.marker').forEach((marker) => {
        marker.remove()
    })

    map.flyTo({
        center: [12.335931181402884, 45.438053730947416],
        zoom: initialZoom,
        pitch: initialPitch,
        bearing: 0,
        duration: 2000,
        easing(t) {
            return t < 0.5 ? 4 * t * t * t : 1 - Math.pow(1 - t, 3) * 4
        }
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
        padding: 24,
        pitch: initialPitch,
        bearing: 0,
        // duration 5s
        duration: 2000,
        // actual bearing + 360
        bearing: map.getBearing() + 30,
        easing(t) {
            return t < 0.5 ? 4 * t * t * t : 1 - Math.pow(1 - t, 3) * 4
        }
    })
}


const placeMarker = (address) => {
    if (!map) return

    // remove any other marker before placing a new one
    document.querySelectorAll('.marker').forEach((marker) => {
        marker.remove()
    })

    const el = document.createElement('div')
    el.className = 'marker'
    el.style.width = '40px'
    el.style.height = '40px'
    el.style.backgroundImage = 'url("/pin.png")'
    el.style.backgroundSize = 'contain'
    el.style.backgroundRepeat = 'no-repeat'
    el.style.backgroundPosition = 'center'
    // el.style.background = 'red'

    // place marker with html element and text label
    const marker = new mapboxgl.Marker({
        element: el,
        anchor: 'bottom'
    })
        .setLngLat([address.coordinates.lng, address.coordinates.lat])
        .addTo(map)

    // fly to marker
    console.log('fly to marker')
    setTimeout(() => {
        
        map.flyTo({
            center: [address.coordinates.lng, address.coordinates.lat],
            zoom: 17,
            pitch: 0,
            bearing: 0,
            duration: 10000,
            easing(t) {
                return t < 0.5 ? 4 * t * t * t : 1 - Math.pow(1 - t, 3) * 4
            }
        })
    }, 1000)
}




onMounted(() => {

})

watchEffect(() => {
    if (!mapContainer.value) {
        return
    }
    setTimeout(() => {
        initMap()
    }, 1000)
})

watchEffect(() => {
    if (!store.selectedSestiere) {
        resetMap()
        return
    }
    flyToSestiere(store.selectedSestiere)
})

watchEffect(() => {
    if (!store.selectedAddress) {
        return
    }
    setTimeout(() => {
        placeMarker(store.selectedAddress)
    }, 1000)
    
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
    mask-image: radial-gradient(ellipse 90% 80% at center, black 20%, transparent 70%);
    opacity: 0;
    transition: opacity 1s ease-in-out;
}
    
</style>