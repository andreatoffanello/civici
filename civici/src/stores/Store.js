import { ref, reactive, computed } from 'vue'
import { defineStore } from 'pinia'

export const useStore = defineStore('store', () => {
	const civici = reactive({})
	const selectedBlock = ref(null)
	const searchedNum = ref(null)
	const selectedNum = ref(0)

	const blocks = ref({
		cannaregio: {
			name: 'Cannaregio',
			img: '',
		},
		castello: {
			name: 'Castello',
			img: '',
		},
		dorsoduro: {
			name: 'Dorsoduro',
			img: '',
		},
		giudecca: {
			name: 'Giudecca',
			img: '',
		},
		sanmarco: {
			name: 'San Marco',
			img: '',
		},
		sanpolo: {
			name: 'San Polo',
			img: '',
		},
		santacroce: {
			name: 'Santa Croce',
			img: '',
		}
	})


	const cleanupNumbers = (block) => {
		let numbers = []

		for (const i in block) {

			for (const n in block[i]) {

				let id = (parseFloat(i) + n).split('_')[0]

				let num = {
					id: id,
					lat: block[i][n].lat,
					lng: block[i][n].lng
				}

				numbers.push(num)

			}
		}

		return numbers

	}

	const loadAddresses = async () => {
		const response = await fetch('civici.json')
		const data = await response.json()

		civici.cannaregio = cleanupNumbers(data.CN)
		civici.castello = cleanupNumbers(data.CS)
		civici.dorsoduro = cleanupNumbers(data.DD)
		civici.giudecca = cleanupNumbers(data.GD)
		civici.santacroce = cleanupNumbers(data.SC)
		civici.sanmarco = cleanupNumbers(data.SM)
		civici.sanpolo = cleanupNumbers(data.SP)
	}

	const selectBlock = (block) => {
		selectedBlock.value = block
	}

	const selectNumber = (num) => {
		selectedNum.value = num
	}

	const filteredNumbers = computed(() => {
		if (!searchedNum.value) {
			return null
		} else {
			console.lo
			let numberblock = civici[selectedBlock.value]

			numberblock = numberblock.filter(n => n.id.startsWith(searchedNum.value))

			return numberblock.splice(0, 6)
		}

	})

	return {
		blocks,
		filteredNumbers,
		searchedNum,
		selectedNum,
		selectNumber,
		selectedBlock,
		civici,
		loadAddresses,
		selectBlock
	}
})
