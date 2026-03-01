# DoVe Android — Piano di sviluppo

> Piano operativo per il porting dell'app DoVe su Android.
> Aggiornare questo file a ogni sessione di lavoro con stato avanzamento e note.

---

## Stato generale

```
iOS     ████████████████████ 100%  → In review App Store
Android ██████████████████░░  90%  → APK debug compilato ✓ — da rifinire e rilasciare
Web     ░░░░░░░░░░░░░░░░░░░░   0%  → In attesa
```

---

## Stack tecnico scelto

| Componente     | Scelta                          | Note                                      |
|---------------|----------------------------------|-------------------------------------------|
| Linguaggio    | Kotlin                           |                                           |
| UI            | Jetpack Compose                  |                                           |
| Architettura  | MVVM + StateFlow                 |                                           |
| Mappe         | **MapLibre Native Android**      | Free, no API key, tile vettoriali         |
| Tile server   | **OpenFreeMap** (openmaptiles)   | 100% gratuito, nessun limite, no key      |
| Navigazione   | Navigation Compose               |                                           |
| Design        | Material 3                       | Adattamento identity iOS, nativo Android  |
| JSON parsing  | kotlinx.serialization            |                                           |
| Target min    | Android 10 (API 29)              |                                           |
| Target SDK    | Android 15 (API 35)              |                                           |

### Perché MapLibre + OpenFreeMap invece di Google Maps
- Google Maps SDK richiede API key con billing attivato
- MapKit iOS è gratuito senza API key → MapLibre è l'equivalente Android
- OpenFreeMap (https://openfreemap.org) fornisce tile vettoriali OSM gratuitamente
- Nessun limite di chiamate, nessun account, zero costi
- MapLibre è open source (fork di Mapbox GL), qualità visiva ottima

---

## Struttura progetto

```
android/
├── ANDROID_PLAN.md                    ← questo file
├── app/
│   ├── build.gradle.kts
│   ├── src/main/
│   │   ├── AndroidManifest.xml
│   │   ├── java/app/dove/venezia/
│   │   │   ├── data/
│   │   │   │   ├── model/
│   │   │   │   │   ├── Sestiere.kt
│   │   │   │   │   ├── ZonaNormale.kt
│   │   │   │   │   └── Civico.kt
│   │   │   │   └── repository/
│   │   │   │       └── CiviciRepository.kt
│   │   │   ├── ui/
│   │   │   │   ├── theme/
│   │   │   │   │   ├── Color.kt
│   │   │   │   │   ├── Theme.kt
│   │   │   │   │   └── Type.kt
│   │   │   │   ├── components/
│   │   │   │   │   ├── SestiereCard.kt
│   │   │   │   │   └── CivicoRow.kt
│   │   │   │   └── screens/
│   │   │   │       ├── SplashScreen.kt
│   │   │   │       ├── SestieriScreen.kt
│   │   │   │       ├── SearchScreen.kt
│   │   │   │       ├── ResultScreen.kt
│   │   │   │       ├── SettingsScreen.kt
│   │   │   │       └── InfoScreen.kt
│   │   │   ├── viewmodel/
│   │   │   │   └── SearchViewModel.kt
│   │   │   └── MainActivity.kt
│   │   ├── assets/
│   │   │   └── civici.json              ← stesso file iOS, copiare da ../data/
│   │   └── res/
│   │       ├── drawable/                ← icone, logo, silhouette sestieri
│   │       ├── font/                    ← CCXLKSNizioleti-Regular (da iOS)
│   │       ├── mipmap-*/                ← icona app
│   │       └── values/
│   │           ├── strings.xml          ← IT (default)
│   │           └── strings-en.xml       ← EN
│   └── proguard-rules.pro
├── build.gradle.kts
├── gradle.properties
└── settings.gradle.kts
```

---

## Fasi e task

### FASE 1 — Setup progetto e dati
**Stato: `✅ COMPLETATA` — 2026-03-01**

- [x] `settings.gradle.kts`, `build.gradle.kts`, `gradle.properties`
- [x] `gradle/libs.versions.toml` — version catalog (AGP 8.7.3, Kotlin 2.1.0)
- [x] `gradle/wrapper/gradle-wrapper.properties` — Gradle 8.10.2
- [x] `app/build.gradle.kts` — tutte le dipendenze, minSdk 29, targetSdk 35
- [x] `app/src/main/AndroidManifest.xml` — permessi INTERNET + LOCATION
- [x] `app/proguard-rules.pro` — regole MapLibre + kotlinx.serialization
- [x] `data/model/Civico.kt` — CivicoCoordinate @Serializable + Civico
- [x] `data/model/Sestiere.kt` — enum con colori, coordinate, range numeri
- [x] `data/model/ZonaNormale.kt` — isole + zone centro, companion lists
- [x] `data/repository/CiviciRepository.kt` — carica JSON con Mutex, coroutine-safe
- [x] `assets/civici.json` — copiato con setup-assets.sh
- [x] `res/font/nizioleti_regular.ttf` — copiato con setup-assets.sh

---

### FASE 2 — Theme e componenti base
**Stato: `✅ COMPLETATA` — 2026-03-01**

- [x] `ui/theme/Color.kt` — palette sestieri (stessi hex iOS) + zone normali
- [x] `ui/theme/Theme.kt` — Material 3 theme, light + dark + Dynamic Color (Android 12+)
- [x] `ui/theme/Type.kt` — tipografia con NizioletiFontFamily custom
- [x] `ui/components/SestiereCard.kt` — card griglia + variante wide per isole
- [x] `ui/components/CivicoRow.kt` — riga lista con codice sestiere + divider

---

### FASE 3 — Navigazione e schermate core
**Stato: `✅ COMPLETATA` — 2026-03-01**

- [x] `viewmodel/SearchViewModel.kt` — SearchUiState sealed, StateFlow, filtro real-time
- [x] `ui/navigation/NavRoutes.kt` — route constants + helper functions
- [x] `MainActivity.kt` — NavHost con tutte le 6 route
- [x] `ui/screens/SplashScreen.kt` — fade in/out animato con logo nizioleti
- [x] `ui/screens/SestieriScreen.kt` — griglia 2col sestieri + sezione isole LazyColumn
- [x] `ui/screens/SearchScreen.kt` — TextField numerico + LazyColumn filtrato
- [x] `ui/screens/ResultScreen.kt` — MapLibre AndroidView + bottoni Maps/Waze/Share
- [x] `ui/screens/InfoScreen.kt` — spiegazione civici veneziani + nizioleti + credits
- [x] `ui/screens/SettingsScreen.kt` — tema (system/light/dark) + lingua (IT/EN)
- [x] `res/values/strings.xml` — stringhe IT complete
- [x] `res/values-en/strings.xml` — stringhe EN complete
- [x] `res/values/themes.xml` — tema XML base (NoActionBar)
- [x] `setup-assets.sh` — script copia civici.json + font da iOS

---

### FASE 4 — Mappa e schermata risultato
**Stato: `✅ INCLUSA IN FASE 3` — 2026-03-01**

MapLibre è già integrato in ResultScreen.kt. Vedere Fase 3.

**Note implementazione:**
- MapLibre SDK 11.5.2 via libs.versions.toml
- Style URL: `https://tiles.openfreemap.org/styles/liberty`
- Lifecycle gestito con DisposableEffect + LifecycleEventObserver
- Marker base con `MarkerOptions().position(LatLng(lat, lng))`
- Camera: `CameraPosition.Builder().target().zoom(17.0)`
- Geo intent con fallback browser se Google Maps non installato
- Waze intent con fallback web

---

### FASE 5 — Schermate secondarie
**Stato: `✅ INCLUSA IN FASE 3` — 2026-03-01**

InfoScreen e SettingsScreen già completate. Vedere Fase 3.

---

### FASE 6 — Icona, asset, rifinitura
**Stato: `⬜ TODO`**

- [ ] Icona app adaptive (mipmap-*) — adattare da iOS, serve layer foreground + background
- [ ] Silhouette sestieri: importare SVG da iOS come VectorDrawable (`res/drawable/`)
- [ ] Marker mappa custom con colore sestiere (ora marker generico)
- [ ] Animazioni transizione tra schermate (Navigation Compose `enterTransition`)
- [ ] Dark mode: verifica contrasti su tutti gli schermi
- [ ] Test su emulatori: Pixel 4 (360dp), Pixel 8 Pro (large), tablet (600dp+)
- [ ] Edge case: civico non trovato, sestiere vuoto, connessione assente (tiles offline?)
- [ ] Persistenza impostazioni tema/lingua con DataStore (ora solo stato locale)

---

### FASE 7 — Release Google Play
**Stato: `⬜ TODO`**

- [ ] Configurare firma AAB (keystore — non committare mai nel repo)
- [ ] Build release: `./gradlew bundleRelease`
- [ ] Google Play Console (developer account: $25 una tantum)
- [ ] Screenshots phone + tablet (min. 2 per form factor)
- [ ] Testi store IT + EN (riutilizzare da App Store)
- [ ] Privacy policy URL (stessa iOS — zero dati raccolti)
- [ ] Content rating questionnaire
- [ ] Submission review

---

## Equivalenze iOS → Android

| iOS (SwiftUI)                        | Android (Compose)                              |
|--------------------------------------|------------------------------------------------|
| `enum Sestiere`                      | `enum class Sestiere`                          |
| `Color(hex:)`                        | `Color(0xFF...)`                               |
| `@StateObject var vm`                | `val vm: SearchViewModel = viewModel()`        |
| `@Published var results`             | `StateFlow<List<Civico>>`                      |
| `NavigationStack`                    | `NavHost` + `NavController`                    |
| `List { ForEach }`                   | `LazyColumn { items() }`                       |
| `.glassEffect()`                     | `Card` con `surfaceVariant` semitrasparente    |
| `MapKit` / `Map()`                   | `MapLibre` / `MapView`                         |
| `CLLocationManager`                  | `FusedLocationProviderClient`                  |
| SF Symbols (`"building.2"`)          | Material Icons Extended                        |
| `Font.custom("CCXLKSNizioleti", ...)` | `FontFamily(Font(R.font.nizioleti))`          |
| `L10n.swift`                         | `strings.xml` / `stringResource()`            |
| `openURL` (Apple Maps)               | `Intent(Intent.ACTION_VIEW, Uri.parse("geo:"))` |

---

## Colori sestieri (Kotlin)

```kotlin
val Cannaregio = Color(0xFF4A90B8)
val Castello   = Color(0xFF5BA86B)
val Dorsoduro  = Color(0xFFD4A843)
val Giudecca   = Color(0xFF8B7BB8)
val SantaCroce = Color(0xFFC76B7A)
val SanMarco   = Color(0xFFD4885A)
val SanPolo    = Color(0xFF5AACAC)
```

---

## Note di sessione

### 2026-03-01 — Sessione 1: scaffold completo
- Stack definito: MapLibre 11.5.2 + OpenFreeMap (no API key, gratuito)
- iOS in review App Store
- Fasi 1, 2, 3 completate in un'unica sessione
- Tutti i file Kotlin scritti e pronti per Android Studio
- `setup-assets.sh` eseguito: civici.json + font nizioleti copiati
- **Prossimo passo**: Fase 6 — icona app definitiva, silhouette sestieri, marker mappa custom, DataStore per impostazioni

---

## Comandi utili

```bash
# Build debug
./gradlew assembleDebug

# Build release AAB per Play Store
./gradlew bundleRelease

# Linting
./gradlew lint

# Test
./gradlew test
```

---

## Risorse

- [MapLibre Android SDK](https://maplibre.org/maplibre-native/android/api/)
- [OpenFreeMap](https://openfreemap.org) — tile gratuiti senza API key
- [Jetpack Compose](https://developer.android.com/jetpack/compose)
- [Material 3](https://m3.material.io)
- [Navigation Compose](https://developer.android.com/guide/navigation/navigation-compose)
- [kotlinx.serialization](https://github.com/Kotlin/kotlinx.serialization)

### 2026-03-01 — Sessione 2: primo APK compilato
- Fix Theme.kt (bug `.let {}` su Color)
- Fix themes.xml (usato `android:Theme.DeviceDefault.NoActionBar`)
- Creato `gradlew` via `gradle wrapper` con Gradle 8.10.2 scaricato
- Creato `local.properties` con SDK path
- Installato Android SDK 35 via sdkmanager
- Icone launcher placeholder (rosso veneziano) generate con Python/PIL
- **BUILD SUCCESSFUL** — APK debug: 99MB (debug), in release sarà ~20MB
- **Prossimo passo**: Fase 6 — icona app definitiva, marker mappa custom, DataStore per persistere impostazioni, test su dispositivo fisico/emulatore
