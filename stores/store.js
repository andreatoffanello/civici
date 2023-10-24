import civici from '@/assets/civici.json' 

export const useStore = defineStore('store', () => {
    
    onMounted(async () => {
        console.log(civici)
    })

    return {

    }
})