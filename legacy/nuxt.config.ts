// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  devtools: { enabled: false },
  modules: [
    '@pinia/nuxt',
    '@vite-pwa/nuxt'
  ],
  pwa: {
    manifest: {
      name: 'La Mia Web App',
      short_name: 'WebApp',
      /* altre opzioni */
    },
    workbox: {
      /* configurazione workbox */
    }
  }
})
