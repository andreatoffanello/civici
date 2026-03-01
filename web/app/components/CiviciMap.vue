<template>
  <div
    class="rounded-2xl overflow-hidden shadow-sm border"
    :style="{ borderColor: 'var(--dove-border)', minHeight: '400px' }"
  >
    <div ref="mapContainer" class="w-full h-full" style="min-height: 400px" />
  </div>
</template>

<script setup>
const store = useCiviciStore()
const mapContainer = ref(null)

let map = null
let marker = null
let L = null

const VENICE_CENTER = [45.4371, 12.3358]
const TILE_URL = 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png'
const TILE_ATTRIBUTION = '&copy; <a href="https://www.openstreetmap.org/copyright">OSM</a> &copy; <a href="https://carto.com/">CARTO</a>'

onMounted(async () => {
  if (!import.meta.client) return

  L = await import('leaflet')
  await import('leaflet/dist/leaflet.css')

  map = L.map(mapContainer.value, {
    center: VENICE_CENTER,
    zoom: 14,
    zoomControl: false,
    attributionControl: true,
  })

  L.control.zoom({ position: 'bottomright' }).addTo(map)

  L.tileLayer(TILE_URL, {
    attribution: TILE_ATTRIBUTION,
    maxZoom: 19,
    subdomains: 'abcd',
  }).addTo(map)

  loadSestieriOverlays()
})

async function loadSestieriOverlays() {
  const codes = ['cannaregio', 'castello', 'dorsoduro', 'giudecca', 'sanmarco', 'sanpolo', 'santacroce']
  const codeMap = {
    cannaregio: '#4A90B8',
    castello: '#5BA86B',
    dorsoduro: '#D4A843',
    giudecca: '#8B7BB8',
    sanmarco: '#D4885A',
    sanpolo: '#5AACAC',
    santacroce: '#C76B7A',
  }

  for (const code of codes) {
    try {
      const res = await fetch(`/data/sestieri/${code}.json`)
      const geojson = await res.json()
      L.geoJSON(geojson, {
        style: {
          color: codeMap[code],
          weight: 1.5,
          opacity: 0.4,
          fillColor: codeMap[code],
          fillOpacity: 0.06,
        },
      }).addTo(map)
    } catch (e) {
      // Skip if file doesn't exist
    }
  }
}

function getResultColor(result) {
  if (!result) return '#C2452D'
  if (result.type === 'sestiere') {
    return store.sestieri[result.sestiere]?.color || '#C2452D'
  }
  return store.zoneNormali[result.zona]?.color || '#C2452D'
}

function getResultLabel(result) {
  if (!result) return ''
  if (result.type === 'sestiere') {
    return store.sestieri[result.sestiere]?.name || result.sestiere
  }
  return store.zoneNormali[result.zona]?.name || result.zona
}

function createCustomIcon(color) {
  return L.divIcon({
    className: 'custom-marker',
    html: `<div style="
      width: 28px;
      height: 28px;
      background: ${color};
      border: 3px solid white;
      border-radius: 50%;
      box-shadow: 0 2px 8px rgba(0,0,0,0.25);
    "></div>`,
    iconSize: [28, 28],
    iconAnchor: [14, 14],
  })
}

watch(
  () => store.selectedResult,
  (result) => {
    if (!map || !L || !result) return

    if (marker) {
      map.removeLayer(marker)
    }

    const color = getResultColor(result)
    const label = getResultLabel(result)
    const streetLine = result.via || result.street
      ? `<br/><span style="font-size: 11px; color: #2A2520;">${result.via || result.street}</span>`
      : ''

    marker = L.marker([result.lat, result.lng], {
      icon: createCustomIcon(color),
    })
      .addTo(map)
      .bindPopup(
        `<div style="font-family: var(--font-body); text-align: center;">
          <strong style="font-size: 18px; color: ${color};">${result.number}</strong>
          <br/>
          <span style="font-size: 12px; color: #8A8078;">${label}</span>
          ${streetLine}
        </div>`,
        { closeButton: false, offset: [0, -10] }
      )
      .openPopup()

    const zoom = result.type === 'zona' ? 16 : 17

    map.flyTo([result.lat, result.lng], zoom, {
      duration: 1.5,
    })
  }
)

onUnmounted(() => {
  if (map) {
    map.remove()
    map = null
  }
})
</script>

<style>
.leaflet-control-attribution {
  font-size: 10px !important;
  opacity: 0.6;
}

.custom-marker {
  background: none !important;
  border: none !important;
}
</style>
