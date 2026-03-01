<template>
  <div class="glass rounded-2xl p-6 flex flex-col gap-5">
    <!-- Mode tabs -->
    <div class="flex gap-1 p-1 rounded-xl" :style="{ backgroundColor: 'var(--dove-border)' }">
      <button
        class="flex-1 px-4 py-2.5 rounded-lg text-sm font-semibold transition-all"
        :style="{
          backgroundColor: store.searchMode === 'sestieri' ? 'var(--dove-surface-solid)' : 'transparent',
          color: store.searchMode === 'sestieri' ? 'var(--dove-text)' : 'var(--dove-muted)',
          boxShadow: store.searchMode === 'sestieri' ? '0 1px 3px rgba(0,0,0,0.08)' : 'none',
        }"
        @click="store.setSearchMode('sestieri')"
      >
        {{ t('search.modeSestieri') }}
      </button>
      <button
        class="flex-1 px-4 py-2.5 rounded-lg text-sm font-semibold transition-all"
        :style="{
          backgroundColor: store.searchMode === 'zone' ? 'var(--dove-surface-solid)' : 'transparent',
          color: store.searchMode === 'zone' ? 'var(--dove-text)' : 'var(--dove-muted)',
          boxShadow: store.searchMode === 'zone' ? '0 1px 3px rgba(0,0,0,0.08)' : 'none',
        }"
        @click="store.setSearchMode('zone')"
      >
        {{ t('search.modeZone') }}
      </button>
    </div>

    <!-- Mode description -->
    <p class="text-xs leading-relaxed" :style="{ color: 'var(--dove-muted)' }">
      {{ store.searchMode === 'sestieri' ? t('search.sestieriDesc') : t('search.zoneDesc') }}
    </p>

    <!-- SESTIERI MODE -->
    <template v-if="store.searchMode === 'sestieri'">
      <!-- Sestiere selector -->
      <div>
        <label class="text-xs font-semibold uppercase tracking-wider mb-2 block" :style="{ color: 'var(--dove-muted)' }">
          {{ t('search.selectSestiere') }}
        </label>
        <div class="grid grid-cols-2 gap-2">
          <button
            v-for="s in store.sestieriList"
            :key="s.code"
            class="flex items-center gap-2 px-3 py-2.5 rounded-xl text-sm font-medium transition-all border"
            :style="{
              backgroundColor: store.selectedSestiere === s.code ? s.color + '18' : 'transparent',
              borderColor: store.selectedSestiere === s.code ? s.color : 'var(--dove-border)',
              color: store.selectedSestiere === s.code ? s.color : 'var(--dove-text)',
            }"
            @click="store.selectSestiere(s.code)"
          >
            <span class="w-2.5 h-2.5 rounded-full shrink-0" :style="{ backgroundColor: s.color }" />
            {{ t(`sestieri.${s.code}`) }}
          </button>
        </div>
      </div>

      <!-- Number input -->
      <div v-if="store.selectedSestiere">
        <label class="text-xs font-semibold uppercase tracking-wider mb-2 block" :style="{ color: 'var(--dove-muted)' }">
          {{ t('search.inputNumber') }}
        </label>
        <div class="flex gap-2">
          <input
            v-model="sestiereInput"
            type="number"
            inputmode="numeric"
            min="1"
            class="flex-1 px-4 py-3 rounded-xl border text-base focus:outline-none focus:ring-2 transition-shadow"
            :style="{
              backgroundColor: 'var(--dove-surface-solid)',
              borderColor: 'var(--dove-border)',
              color: 'var(--dove-text)',
            }"
            :placeholder="t('search.inputNumber')"
            @input="onSestiereInput"
            @keyup.enter="onSestiereSearch"
          />
          <button
            class="px-5 py-3 rounded-xl text-sm font-semibold transition-transform hover:scale-105"
            :style="{ backgroundColor: 'var(--dove-accent)', color: 'white' }"
            @click="onSestiereSearch"
          >
            {{ t('search.search') }}
          </button>
        </div>

        <!-- Quick results -->
        <div v-if="store.filteredNumbers.length" class="mt-3 flex flex-wrap gap-1.5">
          <button
            v-for="num in store.filteredNumbers.slice(0, 12)"
            :key="num"
            class="px-3 py-1 rounded-lg text-xs border transition-colors hover:bg-white/50"
            :style="{ borderColor: 'var(--dove-border)', color: 'var(--dove-text)' }"
            @click="onSelectSestiereNumber(num)"
          >
            {{ num }}
          </button>
          <span v-if="store.filteredNumbers.length > 12" class="px-2 py-1 text-xs" :style="{ color: 'var(--dove-muted)' }">
            +{{ store.filteredNumbers.length - 12 }}
          </span>
        </div>
      </div>
    </template>

    <!-- ZONE NORMALI MODE -->
    <template v-else>
      <!-- Zona selector -->
      <div>
        <label class="text-xs font-semibold uppercase tracking-wider mb-2 block" :style="{ color: 'var(--dove-muted)' }">
          {{ t('search.selectZona') }}
        </label>
        <div class="grid grid-cols-2 gap-2">
          <button
            v-for="z in store.zoneList"
            :key="z.code"
            class="flex items-center gap-2 px-3 py-2 rounded-xl text-sm font-medium transition-all border"
            :style="{
              backgroundColor: store.selectedZona === z.code ? z.color + '18' : 'transparent',
              borderColor: store.selectedZona === z.code ? z.color : 'var(--dove-border)',
              color: store.selectedZona === z.code ? z.color : 'var(--dove-text)',
            }"
            @click="store.selectZona(z.code)"
          >
            <span class="w-2.5 h-2.5 rounded-full shrink-0" :style="{ backgroundColor: z.color }" />
            {{ z.name }}
          </button>
        </div>
      </div>

      <!-- Street search -->
      <div v-if="store.selectedZona">
        <label class="text-xs font-semibold uppercase tracking-wider mb-2 block" :style="{ color: 'var(--dove-muted)' }">
          {{ t('search.searchStreet') }}
        </label>
        <input
          v-model="store.streetSearchText"
          type="text"
          class="w-full px-4 py-3 rounded-xl border text-base focus:outline-none focus:ring-2 transition-shadow"
          :style="{
            backgroundColor: 'var(--dove-surface-solid)',
            borderColor: 'var(--dove-border)',
            color: 'var(--dove-text)',
          }"
          :placeholder="t('search.streetPlaceholder')"
        />

        <!-- Street list -->
        <div
          v-if="store.filteredStreets.length"
          class="mt-3 max-h-40 overflow-y-auto rounded-xl border"
          :style="{ borderColor: 'var(--dove-border)' }"
        >
          <button
            v-for="street in store.filteredStreets.slice(0, 30)"
            :key="street"
            class="w-full text-left px-3 py-2 text-sm border-b last:border-b-0 transition-colors hover:bg-white/50"
            :style="{
              borderColor: 'var(--dove-border)',
              color: store.selectedStreet === street ? zonaColor : 'var(--dove-text)',
              backgroundColor: store.selectedStreet === street ? zonaColor + '10' : 'transparent',
              fontWeight: store.selectedStreet === street ? '600' : '400',
            }"
            @click="store.selectStreet(street)"
          >
            {{ street }}
          </button>
        </div>
        <p v-else-if="store.streetSearchText" class="mt-2 text-xs" :style="{ color: 'var(--dove-muted)' }">
          {{ t('search.noStreets') }}
        </p>
      </div>

      <!-- Number selection for street -->
      <div v-if="store.selectedStreet">
        <label class="text-xs font-semibold uppercase tracking-wider mb-2 block" :style="{ color: 'var(--dove-muted)' }">
          {{ t('search.selectNumber') }}
        </label>
        <div class="flex flex-wrap gap-1.5">
          <button
            v-for="num in store.filteredStreetNumbers.slice(0, 24)"
            :key="num"
            class="px-3 py-1.5 rounded-lg text-xs border transition-colors hover:bg-white/50"
            :style="{
              borderColor: store.selectedResult?.number === num ? zonaColor : 'var(--dove-border)',
              color: store.selectedResult?.number === num ? zonaColor : 'var(--dove-text)',
              backgroundColor: store.selectedResult?.number === num ? zonaColor + '10' : 'transparent',
              fontWeight: store.selectedResult?.number === num ? '600' : '400',
            }"
            @click="store.searchZonaCivico(num)"
          >
            {{ num }}
          </button>
          <span v-if="store.filteredStreetNumbers.length > 24" class="px-2 py-1.5 text-xs" :style="{ color: 'var(--dove-muted)' }">
            +{{ store.filteredStreetNumbers.length - 24 }}
          </span>
        </div>
      </div>
    </template>

    <!-- Result card (shared) -->
    <div
      v-if="store.selectedResult"
      class="rounded-xl p-4 border"
      :style="{
        backgroundColor: resultColor + '10',
        borderColor: resultColor + '30',
      }"
    >
      <div class="flex items-baseline gap-2 mb-1">
        <span class="font-venice text-2xl" :style="{ color: resultColor }">
          {{ store.selectedResult.number }}
        </span>
        <span class="text-sm font-medium" :style="{ color: 'var(--dove-muted)' }">
          {{ resultLabel }}
        </span>
      </div>
      <div v-if="store.selectedResult.via || store.selectedResult.street" class="text-sm mb-2" :style="{ color: 'var(--dove-text)' }">
        {{ store.selectedResult.via || store.selectedResult.street }}
      </div>
      <div class="flex gap-4 text-xs" :style="{ color: 'var(--dove-muted)' }">
        <span>{{ store.selectedResult.lat.toFixed(6) }}, {{ store.selectedResult.lng.toFixed(6) }}</span>
      </div>
      <a
        :href="`https://maps.google.com/?q=${store.selectedResult.lat},${store.selectedResult.lng}`"
        target="_blank"
        rel="noopener"
        class="inline-flex items-center gap-1 mt-3 text-sm font-medium no-underline"
        :style="{ color: 'var(--dove-accent)' }"
      >
        {{ t('search.openMaps') }}
        <svg width="14" height="14" viewBox="0 0 14 14" fill="none" stroke="currentColor" stroke-width="1.5">
          <path d="M5 2h7v7M12 2L5 9" />
        </svg>
      </a>
    </div>
  </div>
</template>

<script setup>
const { t } = useI18n()
const store = useCiviciStore()

const sestiereInput = ref('')

onMounted(() => {
  store.loadData()
})

const zonaColor = computed(() => {
  if (!store.selectedZona) return 'var(--dove-accent)'
  return store.zoneNormali[store.selectedZona]?.color || 'var(--dove-accent)'
})

const resultColor = computed(() => {
  if (!store.selectedResult) return 'var(--dove-accent)'
  if (store.selectedResult.type === 'sestiere') {
    return store.sestieri[store.selectedResult.sestiere]?.color || 'var(--dove-accent)'
  }
  return store.zoneNormali[store.selectedResult.zona]?.color || 'var(--dove-accent)'
})

const resultLabel = computed(() => {
  if (!store.selectedResult) return ''
  if (store.selectedResult.type === 'sestiere') {
    return t(`sestieri.${store.selectedResult.sestiere}`)
  }
  return store.zoneNormali[store.selectedResult.zona]?.name || ''
})

function onSestiereInput() {
  store.searchNumber = sestiereInput.value
}

function onSestiereSearch() {
  if (sestiereInput.value) {
    store.searchCivico(sestiereInput.value)
  }
}

function onSelectSestiereNumber(num) {
  sestiereInput.value = num
  store.searchCivico(num)
}
</script>
