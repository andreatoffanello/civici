# Play Store — Riepilogo e prossimi passi

> Ultimo aggiornamento: 3 marzo 2026

## Stato attuale

| Cosa | Stato |
|------|-------|
| AAB firmato | ✅ `android/app/build/outputs/bundle/release/app-release.aab` |
| Keystore | ✅ `~/Documents/DoVe/keystore/dove-release.jks` (solo sul Mac di casa) |
| Privacy policy | ✅ `https://dovevenezia.com/privacy` (live) |
| Store listing testi | ✅ Vedi sezione sotto |
| Account Play Console | ✅ Creato, $25 pagati |
| Verifica device Android | ⏳ Da fare con cellulare collega |

---

## Step 1 — Verifica device (da fare con collega)

1. Collega scarica **"Google Play Console"** dal Play Store sul suo Android 10+
2. Apre l'app → **Sign in** con `andrea.toffanello@gmail.com`
3. L'app completa automaticamente la verifica device
4. Collega esce dall'account (Impostazioni → Sign out)

Poi vai su [play.google.com/console](https://play.google.com/console) e verifica che il banner di avviso sia sparito.

---

## Step 2 — Build AAB sul Mac del lavoro

Il keystore è su `~/Documents/DoVe/keystore/` **solo sul Mac di casa**.
Sul Mac del lavoro hai due opzioni:

**Opzione A** — Copi il keystore via AirDrop/Drive prima:
```bash
# Sul mac di lavoro, dopo aver copiato dove-release.jks e creato keystore.properties:
cd civici/android
JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" \
  ./gradlew bundleRelease
# AAB risultante: android/app/build/outputs/bundle/release/app-release.aab
```

**Opzione B** — Usa l'AAB già pronto sul Mac di casa:
- Copia `android/app/build/outputs/bundle/release/app-release.aab` via Drive/AirDrop

---

## Step 3 — Upload su Play Console

1. Vai su [play.google.com/console](https://play.google.com/console)
2. **Create app** → nome: "DoVe – Civici di Venezia"
3. **App content** → carica l'AAB in *Production* (o *Internal testing* per iniziare)
4. Compila **Store listing** con i testi sotto
5. Compila **Data safety** (vedi sezione sotto)
6. Compila **Content rating** (questionario semplice)
7. **Submit for review**

---

## Testi Store Listing

### Titolo (30 car)
```
DoVe – Civici di Venezia
```

### Descrizione breve (80 car)
```
Trova subito qualsiasi numero civico di Venezia, sestiere per sestiere.
```

### Descrizione completa IT
```
Venezia è l'unica città al mondo dove i numeri civici non seguono le strade, ma i sestieri: ogni sestiere ha una numerazione continua che può arrivare fino a 6000 e oltre. Orientarsi è quasi impossibile per chi non è del posto.

DoVe risolve questo problema in modo semplice ed elegante.

Seleziona il sestiere — Cannaregio, Castello, Dorsoduro, Giudecca, San Marco, San Polo, Santa Croce — oppure una delle isole della laguna (Murano, Burano, Torcello, Lido, Pellestrina e altre), cerca il numero civico e in un secondo vedi la posizione esatta su mappa 3D con la distanza da dove ti trovi.

FUNZIONALITÀ
• Ricerca rapida per sestiere e numero civico
• Mappa 3D con indicatore di posizione sempre visibile
• Distanza dal civico in tempo reale
• Navigazione diretta con Google Maps o Maps Apple
• Supporto completo per tutte le isole della laguna
• Tema chiaro, scuro o automatico
• Disponibile in italiano e inglese
• Funziona offline per la ricerca (connessione richiesta solo per la mappa)

Progettata per veneziani, turisti, agenti immobiliari, corrieri, professionisti della salute e chiunque debba muoversi nella città più labirintica del mondo.
```

### Descrizione completa EN
```
Venice is the only city in the world where civic numbers don't follow streets — they follow sestieri. Each of the six historic districts has its own continuous numbering that can reach 6,000 and beyond. For anyone not born there, finding an address is nearly impossible.

DoVe solves this simply and elegantly.

Select a sestiere — Cannaregio, Castello, Dorsoduro, Giudecca, San Marco, San Polo, Santa Croce — or one of the lagoon islands (Murano, Burano, Torcello, Lido, Pellestrina and more), search for the civic number, and instantly see its exact location on a 3D map with your distance to it.

FEATURES
• Fast search by sestiere and civic number
• 3D map with always-visible position marker
• Real-time distance to the address
• Direct navigation via Google Maps or Apple Maps
• Full support for all lagoon islands
• Light, dark or automatic theme
• Available in Italian and English
• Offline search support (internet required for map only)

Built for Venetians, tourists, real estate agents, couriers, healthcare workers, and anyone navigating the world's most labyrinthine city.
```

### Note di rilascio
```
Prima versione su Google Play.
```

---

## Data Safety (sezione Play Console)

Rispondi così al questionario:

| Domanda | Risposta |
|---------|----------|
| Data collected or shared? | No |
| Location data collected? | Yes — "Approximate location", optional, not shared |
| Location purpose? | "App functionality" (mostrare distanza dal civico) |
| Data encrypted in transit? | Yes |
| Users can request deletion? | N/A (nessun dato archiviato) |

---

## Privacy Policy
URL da inserire in Play Console: `https://dovevenezia.com/privacy`

---

## Keystore — INFO CRITICHE

> ⚠️ Senza il keystore non puoi MAI aggiornare l'app sul Play Store.

```
File    : ~/Documents/DoVe/keystore/dove-release.jks
Password: rfAJeexarpxyiP80t4Nx
Alias   : dove-key
```

**Fai subito un backup** su 1Password / Google Drive / Bitwarden.
