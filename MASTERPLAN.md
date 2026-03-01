# DoVe — Masterplan

> La tua guida a Venezia: civici, servizi, eventi.

---

## 1. Il progetto

Venezia ha un sistema di numerazione civica unico al mondo: i numeri non seguono le strade ma i **sestieri**. Un indirizzo come "Cannaregio 2345" non dice nulla su quale calle, campo o fondamenta cercare. I veneziani lo sanno per esperienza, tutti gli altri si perdono.

**DoVe** nasce per risolvere questo problema — inserisci un sestiere e un numero, e l'app ti mostra esattamente dove si trova sulla mappa — ma diventa qualcosa di più: una guida utile per vivere e visitare Venezia, con servizi di pubblica utilità, eventi in città e altro.

---

## 2. Il nome

### Perché "DoVe"

- **È la domanda**: "dove?" è letteralmente quello che l'app risponde — dove sta quel civico?
- **La V maiuscola**: richiama Venezia senza doverlo dire
- **Per chiunque**: un italiano lo capisce al volo, un turista che sa due parole di italiano pure
- **Come brand**: 4 lettere, memorabile, pronunciabile in qualsiasi lingua
- **Tono**: diretto, moderno, con un tocco di spirito veneziano

### Domini e handle da verificare
- dovevenezia.app
- dove.venezia.it
- doveapp.it
- @dovevenezia (social)

---

## 3. Piattaforme

### 3.1 iOS (piattaforma primaria)
- **Linguaggio**: Swift
- **UI**: SwiftUI
- **Target**: iOS 17+
- **Mappe**: MapKit (nativo, gratuito, ottima integrazione)

### 3.2 Android
- **Linguaggio**: Kotlin
- **UI**: Jetpack Compose
- **Target**: Android 10+ (API 29)
- **Mappe**: Google Maps SDK

### 3.3 Web (companion)
- Versione leggera per chi non ha l'app
- Stack da definire
- Funzione primaria: landing page + ricerca base + link agli store

### Ordine di sviluppo
1. **iOS** — design, validazione, rilascio
2. **Android** — port della struttura MVVM
3. **Web** — rifacimento del sito attuale

---

## 4. Architettura

### Principi
- **Offline-first**: tutti i dati dei civici sono bundled nell'app (~3MB JSON)
- **Nessun backend**: non serve un server, i dati sono statici
- **Aggiornamento dati**: i JSON vengono aggiornati con le release dell'app
- **Privacy**: zero tracking, zero account, zero dati personali

### Pattern: MVVM

```
┌─────────────────────────────────────────┐
│  View (SwiftUI / Compose)               │
│  Schermate, componenti UI               │
├─────────────────────────────────────────┤
│  ViewModel                              │
│  Logica di presentazione, stato UI      │
├─────────────────────────────────────────┤
│  Model                                  │
│  Dati civici, sestieri, coordinate      │
└─────────────────────────────────────────┘
```

### Struttura dati (già esistente)

```json
{
  "CN": {
    "18":  { "lat": 45.43931, "lng": 12.320046 },
    "19":  { "lat": 45.439429, "lng": 12.320054 }
  },
  "CS": { ... },
  "DD": { ... },
  "GD": { ... },
  "SC": { ... },
  "SM": { ... },
  "SP": { ... }
}
```

Sestieri:
| Codice | Nome         | Colore   |
|--------|-------------|----------|
| CN     | Cannaregio  | #87CEFA  |
| CS     | Castello    | #98FF98  |
| DD     | Dorsoduro   | #FFFF99  |
| GD     | Giudecca    | #c0c0fa  |
| SC     | Santa Croce | #FFC0CB  |
| SM     | San Marco   | #FFDAB9  |
| SP     | San Polo    | #AFEEEE  |

---

## 5. Alberatura e schermate

### 5.1 Home
- Logo DoVe
- Breve tagline ("Trova ogni civico di Venezia")
- Accesso diretto alla ricerca
- Mappa di Venezia come sfondo/elemento visivo

### 5.2 Selezione sestiere
- 7 card/bottoni per i sestieri
- Ognuno con nome e colore identificativo
- Tap → vai alla ricerca numeri

### 5.3 Ricerca civico
- Sestiere selezionato in evidenza
- Campo numerico per il civico
- Lista risultati filtrata in tempo reale (startsWith)
- Tap su un numero → vai al risultato

### 5.4 Risultato / Mappa
- Mappa centrata sulla posizione esatta del civico
- Pin/marker con numero e sestiere
- Bottone "Apri in Mappe" (Apple Maps / Google Maps)
- Bottone "Condividi posizione"
- Possibilità di tornare indietro e cercare un altro numero

### 5.5 Info / About
- Spiegazione breve del sistema civico veneziano
- Cos'è un nizioleto
- Credits, link al progetto originale

---

## 6. Design

### Direzione visiva
**iOS 26 Liquid Glass** come linguaggio di design primario. L'app deve sentirsi nativa, premium, come se fosse progettata da Apple per Venezia. Minimale ma con anima — ogni interazione deve avere peso e intenzione.

### Liquid Glass — Utilizzo
- **Navigation layer**: TabBar, toolbar, bottoni floating con `.glassEffect()`
- **Sestieri cards**: `.glassEffect(.regular.interactive())` con tint per colore sestiere
- **Ricerca**: campo di ricerca in glass, risultati su sfondo content
- **Mappa overlay**: controlli mappa in `.glassEffect(.clear)` sopra MapKit
- **Transizioni**: morphing con `GlassEffectContainer` e `glassEffectID` tra stati
- **Animazioni**: `.bouncy`, spring animations, symbol effects

### Palette
- **Sfondo**: sistema iOS (supporto light/dark mode nativo)
- **Accento primario**: rosso veneziano terracotta `#C2452D`
- **Sestieri**: colori pastello armonici (già definiti) usati come tint su glass
- **Testo**: system colors per massima leggibilità su glass

### Tipografia
- **CCXLKSNizioleti-Regular** per nomi sestieri nella lista — il font dei nizioleti veneziani, dal progetto originale (subset, solo minuscole)
- **SF Pro** per tutto il resto del testo (coerenza con iOS 26)
- **SF Pro Rounded** per numeri civici (più caldo, leggibile)
- Gerarchia forte: `.largeTitle` per numeri, `.headline` per sestieri, `.body` per contenuto

### Mappa
- **MapKit** nativo con stile standard iOS (si integra con Liquid Glass)
- Pin custom con annotation SwiftUI
- Animazioni di camera con `MapCamera`

---

## 7. Feature future (post-MVP)

In ordine di priorità stimata:

### Evoluzione dell'app

Queste feature trasformano DoVe da cercatore di civici a guida completa per Venezia. Richiedono una nuova alberatura con Home, TabBar e sezioni dedicate.

1. **Nuova alberatura** — Home con accesso a sezioni multiple, la ricerca civici diventa la sezione "Civici"
2. **Sezione Servizi** — Mappa con punti di pubblica utilità localizzati (farmacie, bagni pubblici, uffici comunali, pronto soccorso, fontanelle, ecc.). Fonte dati da individuare (open data Comune di Venezia?). Filtro per categoria, dettaglio con indirizzo/orari/contatti
3. **Sezione Eventi** — Lista/calendario di eventi in città con localizzazione su mappa. Fonte dati da individuare (API Comune, feed RSS, curazione manuale?)
4. **Impostazioni** — Lingua (italiano/inglese), preferenze mappa, about/info

### Miglioramenti alla ricerca civici

5. **Ricerca inversa** — Sei davanti a un edificio? Trova il civico dalla tua posizione GPS
6. **Preferiti** — Salva i civici che cerchi spesso
7. **Cronologia** — Ultime ricerche
8. **OCR nizioleti** — Inquadra un nizioleto con la camera, l'app legge il numero
9. **Condivisione smart** — "Ci vediamo al Cannaregio 2345" con link che apre l'app o il web

### Piattaforma

10. **Widget iOS** — Ricerca rapida dalla home screen
11. **Apple Watch** — Complicazione con ultimo civico cercato
12. **Contribuzione dati** — Segnala civici mancanti o errati (richiede backend)

---

## 8. Dati e qualità

### Stato attuale
- Dataset completo di tutti i civici per i 7 sestieri
- Formato: JSON con coordinate lat/lng per ogni civico
- Dimensione: ~3MB (gestibile come bundle)

### Da verificare
- Completezza dei dati (civici mancanti?)
- Accuratezza delle coordinate (spot check su campione)
- Civici con suffisso lettera (es. 2345/A) — gestiti?
- Aggiornamento: ogni quanto cambiano i civici? (raramente, ma succede)

---

## 9. Distribuzione

### iOS
- App Store (gratuita)
- Categoria: Navigazione o Viaggi
- Parole chiave: venezia, civici, sestieri, nizioleti, venice, address

### Android
- Google Play (gratuita)
- Stessa categoria e keywords

### Web
- dovevenezia.app o doveapp.it
- Landing page + versione web della ricerca
- Link agli store

### Monetizzazione
- Nessuna per il MVP
- Possibilità future: versione pro con feature avanzate, o donazioni

---

## 10. Struttura repository

```
dove/
├── MASTERPLAN.md              # Questo documento
├── data/
│   ├── civici.json            # Dataset completo civici
│   └── sestieri/              # GeoJSON confini sestieri
│       ├── cannaregio.json
│       ├── castello.json
│       ├── dorsoduro.json
│       ├── giudecca.json
│       ├── san-marco.json
│       ├── san-polo.json
│       └── santa-croce.json
├── ios/                       # Progetto Xcode
│   └── DoVe/
│       ├── App/
│       │   └── DoVeApp.swift
│       ├── Models/
│       │   ├── Civico.swift
│       │   └── Sestiere.swift
│       ├── ViewModels/
│       │   ├── SearchViewModel.swift
│       │   └── MapViewModel.swift
│       ├── Views/
│       │   ├── HomeView.swift
│       │   ├── SestieriView.swift
│       │   ├── SearchView.swift
│       │   ├── ResultView.swift
│       │   └── InfoView.swift
│       ├── Components/
│       │   ├── SestiereCard.swift
│       │   ├── CivicoRow.swift
│       │   └── MapPin.swift
│       ├── Resources/
│       │   ├── Assets.xcassets
│       │   └── Data/           # civici.json copiato qui
│       └── Utilities/
│           └── DataLoader.swift
├── android/                   # Progetto Android Studio (futuro)
├── web/                       # Web app (futuro)
├── design/                    # File di design, asset, riferimenti
│   ├── palette.md
│   └── references/
└── legacy/                    # Vecchio codice Nuxt (archivio)
    ├── pages/
    ├── components/
    ├── stores/
    ├── assets/
    └── ...
```

---

## 11. Prossimi passi

1. **Rinominare il repository** da `civici` a `dove` (o creare repo nuovo)
2. **Riorganizzare le cartelle** secondo la struttura sopra
3. **Creare il progetto Xcode** con SwiftUI
4. **Definire il design** — palette, tipografia, componenti in Paper o su carta
5. **Implementare MVP iOS** — le 5 schermate con dati reali
6. **Test su dati** — verificare accuratezza su campione di civici noti
7. **TestFlight** — beta con amici veneziani
8. **Rilascio App Store**
