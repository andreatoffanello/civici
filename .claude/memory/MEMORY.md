# DoVe — Memoria Progetto

## Struttura
- `ios/` — App SwiftUI (iOS)
- `web/` — Sito Nuxt.js
- App: trova civici veneziani (sestieri + isole)

## iOS App — Architettura
- Target: iOS, SwiftUI, `@Observable` ViewModel
- `SearchViewModel` — stato ricerca centrale
- `LocationManager`, `NotificationManager` — environment objects
- Routing tramite `SearchFlowView` che legge il viewModel
- Animazioni entrance con `appeared` @State pattern

## Localizzazione (implementata)
- Approccio: `L10n.Strings` struct custom (non .strings files)
- File: `ios/DoVe/Utilities/L10n.swift`
- IT e EN definiti come `static let it` e `static let en`
- Iniettato in `DoVeApp.swift` via `.environment(\.strings, L10n.strings(for: appLanguage))`
- Preferenza salvata in `@AppStorage("appLanguage")` — "it" o "en"
- `AppStringsKey` custom `EnvironmentKey` — accesso con `@Environment(\.strings)`
- Cambio lingua **istantaneo** (SwiftUI re-renders automaticamente)
- Le chiusure per plurali: `civiciLabel`, `streetsLabel`, `resultsLabel`
- Enums `PreferredNavApp`, `AppColorScheme` usano `displayName(strings:)` (non computed property)

## Dati
- `civici.json` — tutti i civici veneziani
- `zone_normali.json` — isole e zone fuori dal sistema sestieri
- Font custom: Sotoportego (per "nizioleto" style)

## Preferenze utente (@AppStorage)
- `appLanguage`: "it" / "en"
- `appColorScheme`: "light" / "dark" / "system"
- `preferredNavApp`: "ask" / "apple" / "google" / "waze"
- `defaultMapView`: "3d" / "2d"
