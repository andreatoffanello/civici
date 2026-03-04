# DoVe — Status

> Ultimo aggiornamento: 2026-03-04

## Stato generale

```
iOS     ████████████████████ 100%  → In review App Store
Android ██████████████████░░  90%  → APK debug compilato, da rifinire e rilasciare
Web     ████████████████░░░░  80%  → Sito Nuxt 4 con landing page, ricerca, mappa
```

---

## iOS

### Completati
- [x] Masterplan redatto
- [x] Riorganizzazione cartelle (legacy/ separato, data/ condiviso)
- [x] Nome scelto: **DoVe**
- [x] Research API Liquid Glass
- [x] Progetto Xcode con xcodegen (project.yml)
- [x] Data models: `Sestiere`, `Civico`, `ZonaNormale`
- [x] `DataLoader`: carica civici.json bundled, ricerca, filtro
- [x] `SearchViewModel`: stato app con @Observable
- [x] **SestieriView**: griglia sestieri con silhouette geografiche
- [x] **SearchView**: ricerca civico con campo numerico, filtro live, glass effect
- [x] **ResultView**: mappa MapKit 3D con pin custom, navigazione Apple Maps, condivisione
- [x] **InfoView**: storia toponomastica veneziana, spiegazione nizioleti, firma autore
- [x] **ContentView**: TabView con Cerca + Info
- [x] **SettingsView**: impostazioni app
- [x] **SplashScreenView**: splash screen animata
- [x] **StreetListView** + **StreetNumbersView**: navigazione per vie
- [x] Silhouette geografiche sestieri (SestiereShape da GeoJSON semplificato)
- [x] Font custom CCXLKSNizioleti-Regular per nomi sestieri
- [x] Renaming completo Niziol → DoVe
- [x] Silhouette sestieri originali da SVG progetto iZioleti (PNG croppate con trasparenza)
- [x] Asset catalog: AppIcon, AccentColor rosso veneziano
- [x] SearchView header: silhouette sestiere + nome in font nizioleti
- [x] CivicoRow: numeri civici stile targa veneziana
- [x] Zone normali (isole): ZonaNormale model + ZonaNormaleCard
- [x] LocationManager, NotificationManager, GlassCompat, L10n (localizzazione)
- [x] Build + run su iOS 26 Simulator
- [x] **Submission App Store** — in review

### Prossimi
- [ ] Cronologia ricerche (UserDefaults)
- [ ] Preferiti
- [ ] Haptic feedback su selezioni

---

## Android

### Completati
- [x] Progetto Android Studio con Kotlin + Jetpack Compose
- [x] Data models: `Sestiere`, `Civico`, `ZonaNormale`
- [x] `CiviciRepository` + `ZonaNormaleRepository`: caricamento JSON con coroutine
- [x] `SearchViewModel` + `ZonaNormaleViewModel`: StateFlow, filtro real-time
- [x] Theme Material 3: light + dark + Dynamic Color (Android 12+)
- [x] Font nizioleti custom
- [x] Navigazione: Navigation Compose con 6+ route
- [x] **SplashScreen**: fade in/out animato
- [x] **SestieriScreen**: griglia sestieri + sezione isole
- [x] **SearchScreen**: TextField numerico + LazyColumn filtrato
- [x] **ResultScreen**: MapLibre + OpenFreeMap + bottoni Maps/Waze/Share
- [x] **InfoScreen**: spiegazione civici veneziani + credits
- [x] **SettingsScreen**: tema (system/light/dark) + lingua (IT/EN)
- [x] **StreetListScreen** + **StreetNumbersScreen**: navigazione per vie
- [x] Stringhe localizzate IT + EN
- [x] AppPrefs: preferenze persistenti
- [x] APK debug compilato (~99MB debug, ~20MB release stimato)

### Prossimi (Fase 6-7)
- [ ] Icona app adaptive (mipmap-*) definitiva
- [ ] Silhouette sestieri come VectorDrawable
- [ ] Marker mappa custom con colore sestiere
- [ ] Animazioni transizione tra schermate
- [ ] Dark mode: verifica contrasti
- [ ] Test su emulatori vari (phone + tablet)
- [ ] Firma AAB + release Google Play

---

## Web

### Completati
- [x] Progetto Nuxt 4 con Vue 3
- [x] Landing page con hero section e shader animato
- [x] Ricerca civici integrata (CiviciSearch + CiviciMap)
- [x] Griglia sestieri (SestieriGrid)
- [x] Mappa Venezia (VeniceMap)
- [x] Sezione problema/soluzione (ProblemSection)
- [x] Showcase app (AppShowcase) con link download
- [x] DownloadCta + SmartAppBanner
- [x] Header + Footer
- [x] LangSwitcher (multilingua)
- [x] Pagine: home, about, come-funziona, contatti, privacy, supporto
- [x] Contenuti multilingua (IT, EN, FR, DE)

---

## Decisioni di progetto

| Data | Decisione | Motivazione |
|------|-----------|-------------|
| 2026-02-28 | Nome: DoVe | "Dove?" è la domanda che l'app risponde, la V maiuscola richiama Venezia |
| 2026-02-28 | iOS-first, nativo Swift/SwiftUI | Massimo controllo su UX, performance, API native |
| 2026-02-28 | iOS 26+ / Liquid Glass | Design premium, app che sembra nata per iOS 26 |
| 2026-02-28 | MapKit per iOS | Gratuito, integrazione nativa perfetta |
| 2026-02-28 | Offline-first, no backend | Dati ~3MB bundled, zero dipendenze server |
| 2026-02-28 | MVVM con @Observable | Pattern moderno SwiftUI, niente Combine esplicito |
| 2026-02-28 | xcodegen per project | Evita conflitti pbxproj, project.yml versionabile |
| 2026-02-28 | Font nizioleti per nomi sestieri | CCXLKSNizioleti-Regular dal progetto originale |
| 2026-03-01 | MapLibre + OpenFreeMap per Android | Gratuito senza API key, equivalente di MapKit su Android |
| 2026-03-01 | Material 3 per Android | Nativo, Dynamic Color su Android 12+ |

---

## Struttura file iOS

```
ios/
├── project.yml                    # xcodegen spec
├── DoVe.xcodeproj/                # generato da xcodegen
└── DoVe/
    ├── App/
    │   └── DoVeApp.swift          # Entry point
    ├── Models/
    │   ├── Sestiere.swift         # Enum 7 sestieri con colori, coordinate, simboli
    │   ├── Civico.swift           # Struct civico con coordinate
    │   └── ZonaNormale.swift      # Isole e zone normali
    ├── ViewModels/
    │   └── SearchViewModel.swift  # Stato app: selezione, ricerca, filtro
    ├── Views/
    │   ├── ContentView.swift      # TabView root
    │   ├── SearchFlowView.swift   # Router: sestieri → ricerca → risultato
    │   ├── SestieriView.swift     # Griglia selezione sestiere
    │   ├── SearchView.swift       # Ricerca numero civico
    │   ├── ResultView.swift       # Mappa con pin e azioni
    │   ├── InfoView.swift         # About e spiegazioni
    │   ├── SettingsView.swift     # Impostazioni
    │   ├── SplashScreenView.swift # Splash screen animata
    │   ├── StreetListView.swift   # Lista vie per sestiere
    │   └── StreetNumbersView.swift # Numeri civici per via
    ├── Components/
    │   ├── SestiereCard.swift     # Card sestiere con font nizioleti + silhouette
    │   ├── ZonaNormaleCard.swift  # Card zona normale/isola
    │   ├── SestiereShape.swift    # Shape geografica da sestieri_shapes.json
    │   ├── NiziolettoShape.swift  # Forma nizioleto (rettangolo arrotondato)
    │   └── CivicoRow.swift        # Riga risultato ricerca
    ├── Utilities/
    │   ├── DataLoader.swift       # Caricamento e query dati JSON
    │   ├── ColorExtension.swift   # Color(hex:) extension
    │   ├── GlassCompat.swift      # Compatibilità Liquid Glass
    │   ├── LocationManager.swift  # Gestione posizione GPS
    │   ├── NotificationManager.swift # Notifiche
    │   └── L10n.swift             # Localizzazione stringhe
    └── Resources/
        ├── Assets.xcassets/
        ├── Fonts/
        │   └── CCXLKSNizioleti-Regular.ttf
        └── Data/
            ├── civici.json
            ├── sestieri_shapes.json
            └── zone_normali.json
```
