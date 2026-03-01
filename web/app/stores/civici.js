import { defineStore } from 'pinia'

const SESTIERI = {
  CN: { name: 'Cannaregio', color: '#4A90B8', range: '1 – 6420' },
  CS: { name: 'Castello', color: '#5BA86B', range: '1 – 6828' },
  DD: { name: 'Dorsoduro', color: '#D4A843', range: '1 – 3901' },
  GD: { name: 'Giudecca', color: '#8B7BB8', range: '1 – 907' },
  SC: { name: 'Santa Croce', color: '#C76B7A', range: '1 – 2362' },
  SM: { name: 'San Marco', color: '#D4885A', range: '1 – 5562' },
  SP: { name: 'San Polo', color: '#5AACAC', range: '1 – 3144' },
}

const ZONE_NORMALI = {
  MU: { name: 'Murano', color: '#B85A8A' },
  BU: { name: 'Burano', color: '#E06B45' },
  TO: { name: 'Torcello', color: '#6B8E5A' },
  MZ: { name: 'Mazzorbo', color: '#C4956A' },
  LI: { name: 'Lido', color: '#4A90B8' },
  PE: { name: 'Pellestrina', color: '#5AACAC' },
  SR: { name: "Sant'Erasmo", color: '#8B9E5A' },
  VI: { name: 'Vignole', color: '#7AAA6B' },
  CE: { name: 'Certosa', color: '#5A8A7A' },
  SE: { name: "Sant'Elena", color: '#5BA86B' },
  SF: { name: 'Sacca Fisola', color: '#8B7BB8' },
}

export const useCiviciStore = defineStore('civici', () => {
  // Data
  const data = ref(null)
  const zoneData = ref(null)
  const loading = ref(false)

  // Search mode: 'sestieri' or 'zone'
  const searchMode = ref('sestieri')

  // Sestieri search state
  const selectedSestiere = ref(null)
  const searchNumber = ref('')
  const selectedResult = ref(null)

  // Zone normali search state
  const selectedZona = ref(null)
  const streetSearchText = ref('')
  const selectedStreet = ref(null)
  const zonaNumberSearch = ref('')

  // Computed
  const sestieri = computed(() => SESTIERI)
  const zoneNormali = computed(() => ZONE_NORMALI)

  const sestieriList = computed(() =>
    Object.entries(SESTIERI).map(([code, info]) => ({ code, ...info }))
  )

  const zoneList = computed(() =>
    Object.entries(ZONE_NORMALI).map(([code, info]) => ({ code, ...info }))
  )

  // Sestieri filtered numbers (prefix match)
  const filteredNumbers = computed(() => {
    if (!data.value || !selectedSestiere.value || !searchNumber.value) return []
    const sestiere = data.value[selectedSestiere.value]
    if (!sestiere) return []
    const query = searchNumber.value.toString()
    return Object.keys(sestiere)
      .filter((num) => num.startsWith(query))
      .sort((a, b) => parseInt(a) - parseInt(b))
      .slice(0, 20)
  })

  // Zone normali streets (substring match)
  const filteredStreets = computed(() => {
    if (!zoneData.value || !selectedZona.value) return []
    const zona = zoneData.value[selectedZona.value]
    if (!zona) return []
    const allStreets = Object.keys(zona).sort()
    if (!streetSearchText.value) return allStreets
    const query = streetSearchText.value.toLowerCase()
    return allStreets.filter((s) => s.toLowerCase().includes(query))
  })

  // Numbers for selected street in zone
  const streetNumbers = computed(() => {
    if (!zoneData.value || !selectedZona.value || !selectedStreet.value) return []
    const nums = zoneData.value[selectedZona.value]?.[selectedStreet.value]
    if (!nums) return []
    return Object.keys(nums).sort((a, b) => {
      const numA = parseInt(a.split('/')[0]) || 0
      const numB = parseInt(b.split('/')[0]) || 0
      if (numA !== numB) return numA - numB
      return a.localeCompare(b)
    })
  })

  const filteredStreetNumbers = computed(() => {
    if (!zonaNumberSearch.value) return streetNumbers.value
    const query = zonaNumberSearch.value.toString()
    return streetNumbers.value.filter((n) => n.startsWith(query))
  })

  // Total civici count for a sestiere
  function sestiereCount(code) {
    if (!data.value || !data.value[code]) return 0
    return Object.keys(data.value[code]).length
  }

  // Total civici count for a zona
  function zonaCount(code) {
    if (!zoneData.value || !zoneData.value[code]) return 0
    return Object.values(zoneData.value[code]).reduce(
      (sum, street) => sum + Object.keys(street).length, 0
    )
  }

  // Street count for a zona
  function zonaStreetCount(code) {
    if (!zoneData.value || !zoneData.value[code]) return 0
    return Object.keys(zoneData.value[code]).length
  }

  // Load both datasets
  async function loadData() {
    if ((data.value && zoneData.value) || loading.value) return
    loading.value = true
    try {
      const [civiciRes, zoneRes] = await Promise.all([
        fetch('/data/civici.json'),
        fetch('/data/zone_normali.json'),
      ])
      data.value = await civiciRes.json()
      zoneData.value = await zoneRes.json()
    } catch (e) {
      console.error('Failed to load data:', e)
    } finally {
      loading.value = false
    }
  }

  // Sestieri actions
  function selectSestiere(code) {
    selectedSestiere.value = code
    searchNumber.value = ''
    selectedResult.value = null
  }

  function searchCivico(number) {
    searchNumber.value = number
    if (!data.value || !selectedSestiere.value) return
    const sestiere = data.value[selectedSestiere.value]
    if (!sestiere) return
    const result = sestiere[number]
    if (result) {
      selectedResult.value = {
        type: 'sestiere',
        sestiere: selectedSestiere.value,
        number,
        lat: result.lat,
        lng: result.lng,
        via: result.via || null,
      }
    } else {
      selectedResult.value = null
    }
  }

  // Zone normali actions
  function selectZona(code) {
    selectedZona.value = code
    selectedStreet.value = null
    streetSearchText.value = ''
    zonaNumberSearch.value = ''
    selectedResult.value = null
  }

  function selectStreet(street) {
    selectedStreet.value = street
    zonaNumberSearch.value = ''
    selectedResult.value = null
  }

  function searchZonaCivico(number) {
    if (!zoneData.value || !selectedZona.value || !selectedStreet.value) return
    const coord = zoneData.value[selectedZona.value]?.[selectedStreet.value]?.[number]
    if (coord) {
      selectedResult.value = {
        type: 'zona',
        zona: selectedZona.value,
        street: selectedStreet.value,
        number,
        lat: coord.lat,
        lng: coord.lng,
      }
    } else {
      selectedResult.value = null
    }
  }

  function setSearchMode(mode) {
    searchMode.value = mode
    clear()
  }

  function clear() {
    selectedSestiere.value = null
    selectedZona.value = null
    selectedStreet.value = null
    searchNumber.value = ''
    streetSearchText.value = ''
    zonaNumberSearch.value = ''
    selectedResult.value = null
  }

  return {
    data,
    zoneData,
    loading,
    searchMode,
    selectedSestiere,
    searchNumber,
    selectedResult,
    selectedZona,
    streetSearchText,
    selectedStreet,
    zonaNumberSearch,
    sestieri,
    zoneNormali,
    sestieriList,
    zoneList,
    filteredNumbers,
    filteredStreets,
    streetNumbers,
    filteredStreetNumbers,
    sestiereCount,
    zonaCount,
    zonaStreetCount,
    loadData,
    selectSestiere,
    searchCivico,
    selectZona,
    selectStreet,
    searchZonaCivico,
    setSearchMode,
    clear,
  }
})
