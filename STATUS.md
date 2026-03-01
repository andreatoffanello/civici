# DoVe — Status

> Ultimo aggiornamento: 2026-02-28

## Stato attuale: MVP iOS funzionante

L'app compila e gira su iOS 26 Simulator (iPhone 17 Pro).

### Completati
- [x] Masterplan redatto
- [x] Riorganizzazione cartelle (legacy/ separato, data/ condiviso)
- [x] Nome scelto: **DoVe**
- [x] Research API Liquid Glass
- [x] Progetto Xcode con xcodegen (project.yml)
- [x] Data models: `Sestiere` (enum 7 sestieri), `Civico` (numero + coordinate)
- [x] `DataLoader`: carica civici.json bundled, ricerca, filtro
- [x] `SearchViewModel`: stato app con @Observable
- [x] **SestieriView**: lista sestieri con silhouette geografiche
- [x] **SearchView**: ricerca civico con campo numerico, filtro live, glass effect
- [x] **ResultView**: mappa MapKit 3D con pin custom, navigazione Apple Maps, condivisione
- [x] **InfoView**: spiegazione nizioleti, sistema civici, lista sestieri in glass
- [x] **ContentView**: TabView con Cerca + Info
- [x] Build + run su iOS 26.2 Simulator (Xcode 26.3)
- [x] Silhouette geografiche sestieri (SestiereShape da GeoJSON semplificato)
- [x] Font custom CCXLKSNizioleti-Regular per nomi sestieri
- [x] Renaming completo Niziol → DoVe
- [x] Silhouette sestieri originali da SVG progetto iZioleti (PNG croppate con trasparenza)
- [x] Asset catalog: AppIcon placeholder, AccentColor rosso veneziano
- [x] SearchView header: silhouette sestiere + nome in font nizioleti
- [x] CivicoRow: numeri civici stile targa veneziana (serif rosso terracotta su crema)

### Prossimi
- [ ] Raffinare design: spaziature, transizioni, animazioni spring
- [ ] Aggiungere sfondo mappa/immagine alla home per far brillare il Liquid Glass
- [ ] Test con dati reali (spot check civici noti)
- [ ] Dark mode verification
- [ ] Haptic feedback su selezioni
- [ ] Cronologia ricerche (UserDefaults)
- [ ] Preferiti

---

## Decisioni di progetto

| Data | Decisione | Motivazione |
|------|-----------|-------------|
| 2026-02-28 | Nome: DoVe | "Dove?" è la domanda che l'app risponde, la V maiuscola richiama Venezia |
| 2026-02-28 | iOS-first, nativo Swift/SwiftUI | Massimo controllo su UX, performance, API native |
| 2026-02-28 | Android dopo | Port con Kotlin/Compose quando iOS è validato |
| 2026-02-28 | iOS 26+ / Liquid Glass | Design premium, app che sembra nata per iOS 26 |
| 2026-02-28 | MapKit (non Mapbox) | Gratuito, integrazione nativa perfetta, stile mappa custom |
| 2026-02-28 | Offline-first, no backend | Dati ~3MB bundled, zero dipendenze server |
| 2026-02-28 | MVVM con @Observable | Pattern moderno SwiftUI, niente Combine esplicito |
| 2026-02-28 | xcodegen per project | Evita conflitti pbxproj, project.yml versionabile |
| 2026-02-28 | Swift 6 strict concurrency | Future-proof, DataLoader è Sendable |
| 2026-02-28 | Silhouette sestieri da GeoJSON | Forme geografiche reali semplificate con Ramer-Douglas-Peucker |
| 2026-02-28 | Font nizioleti per nomi sestieri | CCXLKSNizioleti-Regular dal progetto originale, font subset (solo minuscole) |
| 2026-02-28 | Rename Niziol → DoVe | Nuova identità, bundle ID com.dovevenezia.app |
| 2026-02-28 | Silhouette originali iZioleti | PNG croppate da SVG originali, template rendering per colori sestiere |
| 2026-02-28 | Numeri civici stile targa | Font serif rosso terracotta su sfondo crema, forma nizioleto |

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
    │   └── Civico.swift           # Struct civico con coordinate
    ├── ViewModels/
    │   └── SearchViewModel.swift  # Stato app: selezione, ricerca, filtro
    ├── Views/
    │   ├── ContentView.swift      # TabView root
    │   ├── SearchFlowView.swift   # Router: sestieri → ricerca → risultato
    │   ├── SestieriView.swift     # Griglia selezione sestiere
    │   ├── SearchView.swift       # Ricerca numero civico
    │   ├── ResultView.swift       # Mappa con pin e azioni
    │   └── InfoView.swift         # About e spiegazioni
    ├── Components/
    │   ├── SestiereCard.swift     # Card sestiere con font nizioleti + silhouette
    │   ├── SestiereShape.swift    # Shape geografica da sestieri_shapes.json
    │   ├── NiziolettoShape.swift  # Forma nizioleto (rettangolo arrotondato)
    │   └── CivicoRow.swift        # Riga risultato ricerca
    ├── Utilities/
    │   ├── DataLoader.swift       # Caricamento e query dati JSON
    │   └── ColorExtension.swift   # Color(hex:) extension
    └── Resources/
        ├── Assets.xcassets/             # Asset catalog
        │   ├── AppIcon
        │   ├── AccentColor (#C2452D)
        │   └── sestiere-*.imageset     # 7 silhouette PNG (template mode)
        ├── Fonts/
        │   └── CCXLKSNizioleti-Regular.ttf  # Font nizioleti veneziani
        └── Data/
            ├── civici.json              # Dataset completo (~3MB)
            └── sestieri_shapes.json     # Forme geografiche semplificate
```
