# DoVe — Status

> Ultimo aggiornamento: 2026-03-07

## Stato generale

```
iOS     ████████████████████ 100%  → v1.0 pubblicata su App Store
Android ██████████████████░░  90%  → APK debug compilato, da rifinire e rilasciare
Web     ████████████████░░░░  80%  → Sito Nuxt 4 con landing page, ricerca, mappa
```

---

## iOS — Funzionalita

### Civici (tab Civici)
- [x] Ricerca civico per sestiere + numero
- [x] Griglia sestieri con silhouette geografiche
- [x] Navigazione per vie (StreetListView + StreetNumbersView)
- [x] Mappa MapKit 3D con pin custom
- [x] Navigazione verso Apple Maps / Google Maps / Waze
- [x] Condivisione posizione

### Vaporetti (tab Vaporetti)
- [x] Dati GTFS ACTV (22 linee, 149 fermate, ~87k stop_times) + Alilaguna
- [x] Vista mappa e lista fermate con toggle
- [x] Ricerca fermate e linee (diacritic-insensitive)
- [x] Vista linee con sezioni ACTV/Alilaguna e loghi operatore
- [x] Dettaglio fermata: mappa + bottom sheet con prossime partenze
- [x] Prossime partenze con countdown live (departureTick timer)
- [x] Badge linea colorati (LineBadge) con colori GTFS
- [x] Badge imbarcadero (DockBadge) stile segnaletica veneziana
- [x] Dock di partenza nelle righe partenze (da dati GTFS trip)
- [x] Dettaglio corsa: trip integrato nella mappa di sfondo (no doppia mappa)
- [x] Trip sheet: header fisso + timeline scrollabile + auto-scroll a fermata corrente
- [x] Coincidenze: badge linee di collegamento per ogni fermata
- [x] Tutti gli orari: tabellone completo con filtro per linea
- [x] Fermate preferite con bookmark (salvate in UserDefaults)
- [x] Card fermate preferite in Home con prossime partenze live
- [x] Dock pin sulla mappa raggruppati per imbarcadero
- [x] Rilevamento linee circolari (es. "Murano (circolare)")
- [x] Loghi ACTV/Alilaguna con sfondo bianco (OperatorLogo) per dark mode
- [x] Linea 1 (bianca): badge forzato bianco con testo nero

### Farmacie (tab Servizi)
- [x] 42 farmacie centro storico con coordinate geocodificate
- [x] Stato aperta/chiusa con turni aggiornati (pipeline GitHub Actions)
- [x] Vista mappa e lista con toggle
- [x] Dettaglio farmacia: mappa, orari, telefono, navigazione
- [x] Badge stato aperta/chiusa con colore adattivo

### Home
- [x] Logo DoVe + tagline
- [x] Card colorate per sezioni (Civici, Vaporetti, Servizi)
- [x] Card fermate preferite con partenze live
- [x] Accesso impostazioni
- [x] Credits e versione

### Design System
- [x] Colori adattivi light/dark mode (WCAG AA compliant)
  - doVeAccent (coral): #C2452D / #E06D51
  - doVeNavigation (blue): #416E9E / #6E9DCA
  - doVeServices (green): #15803D / #50BD88
  - doVeSoon (green countdown): #15803D / #50BD88
  - niziolettoBackground/Text per card civici
- [x] Componenti condivisi: LineBadge, DockBadge, OperatorLogo, GroupedLineBadges, FlowLayout, PulseModifier
- [x] Back button solo chevron (.toolbarRole(.editor))
- [x] Icone Phosphor (duotone) + SF Symbols per sistema
- [x] Deep linking: dove://tab/, dove://stop/, dove://line/, dove://view/

### Infrastruttura
- [x] Localizzazione IT/EN via L10n.swift
- [x] LocationManager con distanza formattata
- [x] Navigazione multi-app (Apple Maps, Google Maps, Waze) con preferenza salvata
- [x] Splash screen animata
- [x] Impostazioni: lingua, navigazione preferita

### Prossimi (iOS)
- [ ] Bagni pubblici (16 Veritas, dato quasi statico)
- [ ] Fontanelle (~140, mappa Veritas)
- [ ] Notifiche partenze vaporetti
- [ ] Widget iOS per fermate preferite
- [ ] Haptic feedback su selezioni

---

## Android

### Completati
- [x] Progetto Kotlin + Jetpack Compose + Material 3
- [x] Ricerca civici con tutti i sestieri
- [x] MapLibre + OpenFreeMap
- [x] Navigazione per vie
- [x] Impostazioni tema + lingua
- [x] APK debug compilato

### Prossimi
- [ ] Icona app adaptive definitiva
- [ ] Port funzionalita vaporetti
- [ ] Port funzionalita farmacie
- [ ] Dark mode: verifica contrasti
- [ ] Firma AAB + release Google Play

---

## Web

### Completati
- [x] Nuxt 4 + Vue 3
- [x] Landing page con hero e shader animato
- [x] Ricerca civici + mappa
- [x] Multilingua (IT, EN, FR, DE)
- [x] Pagine: home, about, come-funziona, contatti, privacy, supporto

### Prossimi
- [ ] Deploy definitivo
- [ ] SEO ottimizzazione
- [ ] Sezione vaporetti web

---

## Decisioni di progetto

| Data | Decisione | Motivazione |
|------|-----------|-------------|
| 2026-02-28 | Nome: DoVe | "Dove?" e la domanda, V richiama Venezia |
| 2026-02-28 | iOS-first, Swift/SwiftUI | Massimo controllo UX, performance nativa |
| 2026-02-28 | Offline-first, no backend | Dati ~3MB bundled, zero dipendenze server |
| 2026-02-28 | MVVM con @Observable | Pattern moderno SwiftUI |
| 2026-03-01 | MapLibre per Android | Gratuito senza API key |
| 2026-03-04 | GTFS ufficiali per vaporetti | Dati ACTV + Alilaguna, pipeline GitHub Actions |
| 2026-03-04 | Tabellone partenze, no journey planner | Google Maps lo fa gia, DoVe = info locale |
| 2026-03-05 | Turni farmacie da Ordine Farmacisti | Pipeline scraping giornaliera |
| 2026-03-07 | Colori WCAG AA adattivi | #15803D light / #50BD88 dark per contrasto |
| 2026-03-07 | OperatorLogo con sfondo bianco | Loghi PNG trasparenti visibili in dark mode |
| 2026-03-07 | Bookmark al posto di star | Icona piu sobria e coerente col design |

---

## Struttura file iOS

```
ios/DoVe/
├── App/
│   └── DoVeApp.swift              # Entry point
├── Models/
│   ├── Civico.swift               # Struct civico con coordinate
│   ├── Sestiere.swift             # Enum 7 sestieri
│   ├── ZonaNormale.swift          # Isole e zone normali
│   ├── Pharmacy.swift             # Farmacia con turni e coordinate
│   └── WaterBus.swift             # Departure, WaterBusStop, WaterBusRoute, TripStop, TripNavigation
├── ViewModels/
│   ├── SearchViewModel.swift      # Ricerca civici
│   ├── WaterBusViewModel.swift    # GTFS, partenze, trip, coincidenze
│   └── PharmacyViewModel.swift    # Farmacie e turni
├── Views/
│   ├── ContentView.swift          # TabView root + deep link router
│   ├── HomeHubView.swift          # Home con card sezioni + preferiti
│   ├── SearchFlowView.swift       # Router civici
│   ├── SestieriView.swift         # Griglia sestieri
│   ├── SearchView.swift           # Ricerca civico
│   ├── ResultView.swift           # Mappa risultato
│   ├── WaterBusListView.swift     # Fermate/linee + componenti condivisi
│   ├── WaterBusStopDetailView.swift # Dettaglio fermata + trip integrato
│   ├── WaterBusLineDetailView.swift # Dettaglio linea con timeline fermate
│   ├── TripDetailView.swift       # Dettaglio corsa (standalone)
│   ├── PharmacyListView.swift     # Lista/mappa farmacie
│   ├── PharmacyDetailView.swift   # Dettaglio farmacia
│   ├── ServicesView.swift         # Hub servizi
│   ├── SettingsView.swift         # Impostazioni
│   ├── InfoView.swift             # About
│   ├── SplashScreenView.swift     # Splash
│   ├── StreetListView.swift       # Liste vie
│   └── StreetNumbersView.swift    # Numeri per via
├── Components/
│   ├── SestiereCard.swift         # Card sestiere
│   ├── ZonaNormaleCard.swift      # Card isola
│   ├── SestiereShape.swift        # Shape da GeoJSON
│   ├── NiziolettoShape.swift      # Forma nizioleto
│   └── CivicoRow.swift            # Riga risultato
├── Utilities/
│   ├── ColorExtension.swift       # Colori adattivi + PulseModifier
│   ├── DataLoader.swift           # Caricamento JSON civici
│   ├── LocationManager.swift      # GPS + distanza formattata
│   ├── NotificationManager.swift  # Notifiche
│   ├── GlassCompat.swift          # Compatibilita Liquid Glass
│   └── L10n.swift                 # Localizzazione IT/EN
└── Resources/
    ├── Assets.xcassets/           # Icone, loghi ACTV/Alilaguna
    ├── Fonts/                     # CCXLKSNizioleti-Regular
    └── Data/                      # civici.json, vaporetti.json, farmacie.json, turni, zone_normali
```
