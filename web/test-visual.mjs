import { chromium } from '@playwright/test'

const browser = await chromium.launch()
const context = await browser.newContext({ viewport: { width: 1440, height: 900 } })
const page = await context.newPage()

// Desktop tests
const pages = [
  { url: '/', name: 'home-desktop' },
  { url: '/come-funziona', name: 'come-funziona-desktop' },
  { url: '/about', name: 'about-desktop' },
  { url: '/contatti', name: 'contatti-desktop' },
  { url: '/en', name: 'home-en' },
]

for (const p of pages) {
  await page.goto(`http://localhost:3000${p.url}`, { waitUntil: 'networkidle' })
  await page.screenshot({ path: `screenshots/${p.name}.png`, fullPage: true })
  console.log(`  ${p.name} OK`)
}

// Mobile tests
await page.setViewportSize({ width: 375, height: 812 })
await page.goto('http://localhost:3000/', { waitUntil: 'networkidle' })
await page.screenshot({ path: 'screenshots/home-mobile.png', fullPage: true })
console.log('  home-mobile OK')

await page.goto('http://localhost:3000/come-funziona', { waitUntil: 'networkidle' })
await page.screenshot({ path: 'screenshots/come-funziona-mobile.png', fullPage: true })
console.log('  come-funziona-mobile OK')

await browser.close()
console.log('\nAll screenshots saved in screenshots/')
