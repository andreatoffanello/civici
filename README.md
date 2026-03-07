# DoVe

Trova la posizione reale di ogni numero civico nei sestieri di Venezia. Orari vaporetti ACTV e Alilaguna. Farmacie di turno.

Venezia ha un sistema di numerazione civica unico al mondo: i numeri non seguono le strade ma i **sestieri**. DoVe ti mostra esattamente dove si trova ogni civico sulla mappa — e molto altro.

## Stato

| Piattaforma | Stack | Stato |
|-------------|-------|-------|
| **iOS** | Swift 6, SwiftUI, MapKit | v1.0 su App Store |
| **Android** | Kotlin, Jetpack Compose, Material 3, MapLibre | APK debug, da rilasciare |
| **Web** | Nuxt 4, Vue 3, multilingua (IT/EN/FR/DE) | Sito funzionante |

## Funzionalita iOS

- **Civici** — ricerca per sestiere/numero/via, mappa con pin, navigazione multi-app
- **Vaporetti** — GTFS ACTV + Alilaguna, fermate mappa/lista, partenze live, dettaglio corsa, coincidenze, preferiti
- **Farmacie** — 42 farmacie con turni, stato aperta/chiusa, mappa, dettaglio con chiamata

## Struttura

```
civici/
├── data/          # Dataset civici e confini sestieri (JSON)
├── scripts/       # Script Python per arricchimento dati
├── ios/           # App iOS (SwiftUI)
├── android/       # App Android (Compose, Material 3)
├── web/           # Sito web (Nuxt 4)
├── design/        # Asset di design
└── legacy/        # Vecchio progetto Nuxt (archivio)
```

## Documentazione

- [MASTERPLAN.md](./MASTERPLAN.md) — Piano completo del progetto
- [STATUS.md](./STATUS.md) — Stato avanzamento dettagliato
- [android/ANDROID_PLAN.md](./android/ANDROID_PLAN.md) — Piano sviluppo Android
