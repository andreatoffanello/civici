import civici from '@/assets/civici.json' 

import cannaregio from '@/assets/sestieri/cannaregio.json'
import castello from '@/assets/sestieri/castello.json'
import dorsoduro from '@/assets/sestieri/dorsoduro.json'
import giudecca from '@/assets/sestieri/giudecca.json'
import sanmarco from '@/assets/sestieri/sanmarco.json'
import sanpolo from '@/assets/sestieri/sanpolo.json'
import santacroce from '@/assets/sestieri/santacroce.json'

export const useStore = defineStore('store', () => {

    const sestieri = ref({
        'CN': {
            id: 1,
            name: 'Cannaregio',
            coordinates: [12.330761624263857, 45.443476037980645],
            color: '#87CEFA',
            geojson: cannaregio
        },
        'CS': {
            id: 2,
            name: 'Castello',
            coordinates: [12.349181480979382, 45.43326696574735],
            color: '#98FF98',
            geojson: castello
        },
        'DD': {
            id: 3,
            name: 'Dorsoduro',
            coordinates: [12.3256588355151, 45.430826868741406],
            color: '#FFFF99',
            geojson: dorsoduro
        },
        'GD': {
            id: 4,
            name: 'Giudecca',
            coordinates: [12.325256777527102, 45.426553166266984],
            color: '#E6E6FA',
            geojson: giudecca
        },
        'SC': {
            id: 5,
            name: 'Santa Croce',
            coordinates: [12.327118521964422, 45.43961713874836],
            color: '#FFC0CB',
            geojson: santacroce
        },
        'SM': {
            id: 6,
            name: 'San Marco',
            coordinates: [12.334118514259586, 45.433904312380264],
            color: '#FFDAB9',
            geojson: sanmarco
        },
        'SP': {
            id: 7,
            name: 'San Polo',
            coordinates: [12.32998686649168, 45.43752612341751],
            color: '#AFEEEE',
            geojson: sanpolo
        },

    })

    // const cleanCivici = () => {
    //     const newCivici = {}
    //     Object.keys(civici).forEach(sestiere => {
    //         Object.keys(civici[sestiere]).forEach(civico => {

    //             newCivici[sestiere] = newCivici[sestiere] || {}
                
    //             Object.keys(civici[sestiere][civico]).forEach(alt => {

    //                 let index = Number(civico) + (alt == '_' ? '' : alt)
                    
    //                 newCivici[sestiere][index] = {
    //                     lat: civici[sestiere][civico][alt].lat,
    //                     lng: civici[sestiere][civico][alt].lng
    //                 }
    //             })
    //         })
    //     })

    //     console.log(newCivici)
    //     return newCivici
    // }

    const selectedSestiere = ref(null)

    const selectSestiere = (sestiere) => {
        selectedSestiere.value = sestiere
    }

    const filterNumber = ref(null)

    const filteredNumbers = computed(() => {
        // trova tutti gli oggetti figli di civici[selectedSestiere.value] che hanno come chiave un numero che contiene la stringa filterNumber

        if (!civici[selectedSestiere.value]) return []
        let filtered = Object.keys(civici[selectedSestiere.value])

        if (filterNumber.value) {
            filtered = filtered.filter(key => key.includes(filterNumber.value))
        }

        return filtered.map(key => civici[selectedSestiere.value][key])
    })

    
    onMounted(async () => {
        // cleanCivici()
    })

    return {
        civici,
        sestieri,
        selectedSestiere,
        selectSestiere,
        filteredNumbers
    }
})