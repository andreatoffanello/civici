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

### 3.1 iOS (piattaforma primaria) — in review App Store
- **Linguaggio**: Swift 6
- **UI**: SwiftUI con Liquid Glass (iOS 26+)
- **Target**: iOS 26+
- **Mappe**: MapKit (nativo, gratuito, ottima integrazione)
- **Stato**: MVP completo, submission App Store in review

### 3.2 Android — APK debug compilato
- **Linguaggio**: Kotlin 2.1
- **UI**: Jetpack Compose + Material 3
- **Target**: Android 10+ (API 29), target SDK 35
- **Mappe**: MapLibre + OpenFreeMap (gratuito, no API key)
- **Stato**: 90% completato, da rifinire (icona, animazioni) e rilasciare su Play Store

### 3.3 Web — sito online
- **Stack**: Nuxt 4 + Vue 3
- **Funzione**: landing page + ricerca civici + mappa + link agli store
- **Multilingua**: IT, EN, FR, DE
- **Stato**: 80% completato, funzionante

### Ordine di sviluppo (realizzato)
1. **iOS** — completato, in review App Store
2. **Android** — port completato, da rilasciare
3. **Web** — sito funzionante con ricerca e mappa

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

In ordine di priorità. Principio guida: **solo fonti ufficiali e verificabili**, no OSM (rischio dati obsoleti a Venezia). Meglio pochi dati certi che tanti inaffidabili. Focus su cittadini prima che turisti.

### 1. Vaporetti — priorità alta

Tab standalone nell'app (non legata alla ricerca civici). Un'alternativa a "chebateo": tabellone partenze digitale, non journey planner.

- **Dati**: GTFS ufficiali ACTV navigazione (22 linee, 149 fermate, ~87k stop_times) + Alilaguna (2 linee, 34 fermate)
- **UX**: ricerca fermate come lista o selezione da mappa → dettaglio fermata con prossime partenze programmate, direzioni, pontili
- **Fonti**:
  - ACTV: `https://actv.avmspa.it/sites/default/files/attachments/opendata/navigazione/actv_nav.zip` (~1.2MB, aggiornato mensilmente)
  - Alilaguna: `http://www.alilaguna.it/attuale/alilaguna.zip` (17KB, aggiornato stagionalmente)
- **Pipeline**: GitHub Actions (cron settimanale) → scarica GTFS → converte in JSON ottimizzati → hosting statico (GitHub Pages o Cloudflare Pages). L'app scarica il JSON aggiornato
- **No journey planner**: troppo complesso, Google Maps lo fa già. DoVe = tabellone partenze

### 2. Farmacie di turno — priorità alta

Sapere quale farmacia è aperta/di turno, utile soprattutto per i residenti.

- **Dati**: ~15 farmacie nel centro storico, con indirizzi in formato sestiere+civico (geocodificabili con civici.json)
- **Fonte**: Ordine dei Farmacisti di Venezia (`ordinefarmacistivenezia.it`) — export JSON/XML ufficiale dei turni
- **Pipeline**: GitHub Actions (cron giornaliero o settimanale) → scraping turni → JSON con coordinate → hosting statico
- **UX**: lista farmacie con stato aperta/turno, mappa con pin, dettaglio con indirizzo/orari/telefono

### 3. Bagni pubblici — priorità media

- **Dati**: 16 bagni pubblici gestiti da Veritas nel centro storico
- **Fonte**: lista ufficiale Veritas (`gruppoveritas.it`)
- **Formato**: JSON curato a mano (dato quasi statico, raramente cambia)
- **UX**: lista + mappa con pin, orari, costo (€1.50)

### 4. Fontanelle — priorità media-bassa

- **Dati**: ~140 fontanelle funzionanti a Venezia
- **Fonte**: mappa ufficiale Veritas delle fontanelle pubbliche
- **Note**: serve verifica/curazione iniziale, poi dato relativamente statico
- **UX**: mappa con pin, filtro per zona

### 5. Tassini / Curiosità Veneziane — parcheggiato

Storia e origine dei nomi delle vie veneziane, dal libro "Curiosità Veneziane" di Giuseppe Tassini (1863, pubblico dominio).

- **Stato**: esiste già un lavoro di trascrizione e georeferenziazione su `curiositaveneziane.it` — da contattare l'autore per possibile collaborazione
- **Alternativa**: OCR/trascrizione dal testo originale (pubblico dominio) + georeferenziazione propria
- **Da valutare**: effort vs valore, questione copyright del lavoro derivato

### Nuova alberatura

Le feature sopra richiedono una nuova struttura dell'app con TabBar e sezioni dedicate:
- **Civici** (ricerca civici, funzionalità core attuale)
- **Vaporetti** (fermate e partenze)
- **Servizi** (farmacie, bagni, fontanelle)
- **Info** (about, impostazioni)

### Infrastruttura dati

- **Pipeline preferita**: GitHub Actions (cron) → scarica/scrape dati → JSON ottimizzati → GitHub Pages / Cloudflare Pages (gratis)
- **Fallback**: VPS Hetzner già disponibile per job di scraping o backend leggero
- **Principio**: l'app scarica JSON statici, nessun backend real-time necessario
- **Aggiornamento dati**: settimanale per GTFS/farmacie, manuale per bagni/fontanelle

### Feature scartate

Valutate e scartate perché poco utili o non in scope:
- ~~Cronologia ricerche~~ — non aggiunge valore reale
- ~~Preferiti civici~~ — caso d'uso troppo raro
- ~~Ricerca inversa GPS~~ — utilità marginale
- ~~OCR nizioleti~~ — wow factor senza utilità pratica
- ~~Journey planner vaporetti~~ — troppo complesso, Google Maps lo fa già
- ~~Widget iOS / Apple Watch~~ — prematura
- ~~Contribuzione dati~~ — richiede backend, moderazione, non prioritario
- ~~Sezione Eventi~~ — fonte dati incerta, difficile da mantenere aggiornata

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
civici/
├── MASTERPLAN.md              # Questo documento
├── STATUS.md                  # Stato avanzamento progetto
├── README.md                  # Panoramica progetto
├── data/
│   ├── civici.json            # Dataset completo civici
│   ├── civici-plain.json      # Dataset semplificato
│   └── sestieri/              # GeoJSON confini sestieri
│       ├── cannaregio.json
│       ├── castello.json
│       ├── dorsoduro.json
│       ├── giudecca.json
│       ├── sanmarco.json
│       ├── sanpolo.json
│       └── santacroce.json
├── scripts/                   # Script utilità dati
│   ├── add_more_islands.py
│   ├── enrich_civici.py
│   └── enrich_from_cartotecnica.py
├── ios/                       # App iOS (SwiftUI, Liquid Glass)
│   └── DoVe/
│       ├── App/, Models/, ViewModels/, Views/
│       ├── Components/, Utilities/, Resources/
│       └── (dettaglio in STATUS.md)
├── android/                   # App Android (Kotlin, Compose, Material 3)
│   ├── ANDROID_PLAN.md        # Piano dettagliato Android
│   └── app/src/main/java/app/dove/venezia/
│       ├── data/, ui/, viewmodel/
│       └── MainActivity.kt
├── web/                       # Sito web (Nuxt 4, Vue 3)
│   └── app/
│       ├── pages/             # index, about, privacy, contatti, ...
│       ├── components/        # Hero, CiviciSearch, VeniceMap, ...
│       └── layouts/
├── design/                    # Asset di design (logo, riferimenti)
└── legacy/                    # Vecchio codice Nuxt (archivio)
```

---

## 11. Prossimi passi

### Completati
1. ~~Riorganizzare le cartelle~~ — fatto
2. ~~Creare il progetto Xcode con SwiftUI~~ — fatto
3. ~~Definire il design~~ — Liquid Glass, palette, tipografia
4. ~~Implementare MVP iOS~~ — tutte le schermate con dati reali
5. ~~Submission App Store~~ — in review
6. ~~Port Android~~ — APK debug compilato
7. ~~Sito web~~ — Nuxt 4, landing page + ricerca + mappa

### Da fare
- [ ] Rilascio App Store iOS (in attesa review)
- [ ] Android: rifinitura (icona, animazioni, marker custom) e rilascio Play Store
- [ ] Web: deploy definitivo
- [ ] Test dati: spot check civici noti su entrambe le piattaforme
- [ ] Cronologia ricerche + preferiti (iOS e Android)
- [ ] Rinominare il repository da `civici` a `dove` (opzionale)
