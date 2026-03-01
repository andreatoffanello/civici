export default defineNuxtConfig({
  compatibilityDate: '2025-07-15',
  devtools: { enabled: true },

  modules: [
    '@nuxt/ui',
    '@nuxt/content',
    '@nuxtjs/i18n',
    '@pinia/nuxt',
    '@nuxtjs/sitemap',
  ],

  site: {
    url: 'https://dovevenezia.com',
  },

  i18n: {
    locales: [
      { code: 'it', language: 'it-IT', name: 'Italiano', file: 'it.json' },
      { code: 'en', language: 'en-US', name: 'English', file: 'en.json' },
      { code: 'de', language: 'de-DE', name: 'Deutsch', file: 'de.json' },
      { code: 'fr', language: 'fr-FR', name: 'Français', file: 'fr.json' },
    ],
    defaultLocale: 'it',
    strategy: 'prefix_except_default',
    langDir: '../i18n/locales',
    lazy: true,
    detectBrowserLanguage: {
      useCookie: true,
      cookieKey: 'dove_lang',
      redirectOn: 'root',
    },
  },

  app: {
    head: {
      htmlAttrs: { lang: 'it' },
      link: [
        { rel: 'icon', type: 'image/png', sizes: '32x32', href: '/favicon-32x32.png' },
        { rel: 'icon', type: 'image/png', sizes: '16x16', href: '/favicon-16x16.png' },
        { rel: 'apple-touch-icon', sizes: '180x180', href: '/apple-touch-icon.png' },
        { rel: 'preconnect', href: 'https://fonts.googleapis.com' },
        { rel: 'preconnect', href: 'https://fonts.gstatic.com', crossorigin: '' },
        {
          rel: 'stylesheet',
          href: 'https://fonts.googleapis.com/css2?family=Playfair+Display:wght@400;700;900&family=Inter:wght@400;500;600;700&display=swap',
        },
      ],
      meta: [
        { name: 'theme-color', content: '#FAF6F1' },
        { property: 'og:image', content: 'https://dovevenezia.com/img/og-image.png' },
        { property: 'og:type', content: 'website' },
        { name: 'twitter:card', content: 'summary_large_image' },
        { name: 'twitter:image', content: 'https://dovevenezia.com/img/og-image.png' },
      ],
    },
  },

  css: [
    '~/assets/css/main.css',
  ],

  nitro: {
    prerender: {
      routes: ['/'],
      crawlLinks: true,
    },
  },

  routeRules: {
    '/**': { prerender: true },
  },
})
