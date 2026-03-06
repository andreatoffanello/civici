import Foundation
import SwiftUI

// MARK: - Environment Key

struct AppStringsKey: EnvironmentKey {
    static let defaultValue = L10n.Strings.it
}

extension EnvironmentValues {
    var strings: L10n.Strings {
        get { self[AppStringsKey.self] }
        set { self[AppStringsKey.self] = newValue }
    }
}

// MARK: - L10n

enum L10n {
    static func strings(for language: String) -> Strings {
        language == "en" ? Strings.en : Strings.it
    }

    struct Strings: @unchecked Sendable {
        // MARK: Tabs
        let tabHome: String
        let tabSearch: String
        let tabServices: String
        let tabInfo: String
        let tabSettings: String

        // MARK: Home
        let homeCiviciTitle: String
        let homeTagline: String

        // MARK: SestieriView
        let tagline: String
        let selectSestiere: String
        let otherAreas: String
        let islands: String

        // MARK: SearchView
        let civicNumberPlaceholder: String
        let keepTypingToFilter: String
        let civiciLabel: (Int) -> String
        let streetsLabel: (Int) -> String
        let resultsLabel: (Int) -> String

        // MARK: StreetListView
        let streetSearchPlaceholder: String

        // MARK: ResultView
        let navigate: String
        let openNavigationWith: String
        let cancel: String

        // MARK: InfoView
        let whatIsNizioleto: String
        let whatIsNizioletoCont: String
        let twoAddressingSystems: String
        let twoAddressingSystemsContent: String
        let howItWorks: String
        let howItWorksContent: String
        let numberingBySestiere: String
        let ordinaryToponymy: String
        let islandLabel: String
        let madeWithCare: String

        // MARK: InfoView — Storia
        let historyTitle: String
        let historyOralTitle: String
        let historyOralContent: String
        let historyNamingTitle: String
        let historyNamingContent: String
        let historyNapoleonTitle: String
        let historyNapoleonContent: String
        let historyAustrianTitle: String
        let historyAustrianContent: String

        // MARK: SettingsView
        let sectionAppearance: String
        let theme: String
        let themeLight: String
        let themeDark: String
        let themeSystem: String
        let sectionMap: String
        let mapView: String
        let navigationLabel: String
        let navFooter: String
        let sectionLanguage: String
        let languageLabel: String
        let languageFooter: String
        let sectionPermissions: String
        let locationLabel: String
        let notificationsLabel: String
        let permissionsFooter: String
        let permissionGranted: String
        let permissionDenied: String
        let permissionNotRequested: String
        let permissionUnknown: String
        let sectionAbout: String
        let versionLabel: String
        let settingsNavTitle: String
        let alwaysAsk: String

        // MARK: ServicesView
        let servicesTitle: String
        let servicesSubtitle: String
        let servicesAvailable: String

        // MARK: Water Bus (Vaporetti)
        let waterBusTitle: String
        let waterBusSearchPlaceholder: String
        let waterBusNoResults: String
        let waterBusLines: String
        let waterBusNextDepartures: String
        let waterBusNavigate: String
        let waterBusAllLines: String
        let waterBusTime: String
        let waterBusLine: String
        let waterBusDirection: String
        let waterBusNoDepartures: String
        let waterBusStopsCount: (Int) -> String
        let waterBusStops: String
        let waterBusNoLines: String
        let waterBusRouteStops: String

        // MARK: Pharmacies
        let pharmaciesTitle: String
        let pharmaciesOpenCount: (Int, Int) -> String
        let pharmaciesAllClosed: String
        let pharmaciesOpenNow: String
        let pharmaciesClosedNow: String
        let pharmacyOpen: String
        let pharmacyClosed: String
        let pharmacyClosesAt: (String) -> String
        let pharmacyHoursLabel: String
        let pharmacyPhoneLabel: String
        let pharmacyAreaLabel: String
        let pharmacyCall: String

        // MARK: - Italian

        static let it = Strings(
            tabHome: "Home",
            tabSearch: "Civici",
            tabServices: "Servizi",
            tabInfo: "Info",
            tabSettings: "Impostazioni",

            homeCiviciTitle: "Civici",
            homeTagline: "DoVe vai oggi?",
            tagline: "Trova ogni civico di Venezia",
            selectSestiere: "SELEZIONA UN SESTIERE",
            otherAreas: "ALTRE ZONE",
            islands: "ISOLE",

            civicNumberPlaceholder: "Numero civico",
            keepTypingToFilter: "Continua a digitare per filtrare...",
            civiciLabel: { n in "\(n) civici" },
            streetsLabel: { n in "\(n) \(n == 1 ? "via" : "vie")" },
            resultsLabel: { n in "\(n) risultat\(n == 1 ? "o" : "i")" },

            streetSearchPlaceholder: "Cerca via, calle, fondamenta...",

            navigate: "Naviga",
            openNavigationWith: "Apri navigazione con",
            cancel: "Annulla",

            whatIsNizioleto: "Cos'è un nizioleto?",
            whatIsNizioletoCont: "I nizioleti sono i cartelli dipinti sui muri di Venezia che indicano strade, campi e direzioni. Il nome viene dal veneziano \"lenzuoletto\" — piccoli rettangoli bianchi con scritte nere che da secoli guidano chi cammina per la città.",
            twoAddressingSystems: "Due sistemi di indirizzamento",
            twoAddressingSystemsContent: "Il centro storico è diviso in sei sestieri, ognuno con una numerazione civica progressiva indipendente. Conoscere solo il numero non basta: serve sapere il sestiere. Le isole della laguna e alcune zone del centro usano invece il sistema ordinario, con via e numero civico come nel resto d'Italia.",
            howItWorks: "Come funziona",
            howItWorksContent: "Scegli un sestiere e digita il numero civico per trovarlo sulla mappa. Per le isole e le zone normali, seleziona prima la via e poi il numero. Tocca \"Naviga\" per aprire le indicazioni in Apple Maps, Google Maps o Waze.",
            numberingBySestiere: "Numerazione per sestiere",
            ordinaryToponymy: "Toponomastica ordinaria",
            islandLabel: "isola",
            madeWithCare: "Fatto con cura a Venezia",

            historyTitle: "Storia del sistema",
            historyOralTitle: "Prima dei cartelli: la toponomastica orale",
            historyOralContent: "Sotto la Serenissima non esistevano nizioleti, né una numerazione civica. Venezia era divisa in circa settanta contrade — le parrocchie — e ci si orientava a memoria, per prossimità a chiese, pozzi e campi. Chi non era del posto chiedeva ai passanti. I nomi delle strade esistevano, ma solo nella voce delle persone.",
            historyNamingTitle: "Come nascevano i nomi",
            historyNamingContent: "I nomi erano pratici e descrittivi: indicavano chi lavorava lì, cosa si vendeva, o chi ci abitava. I Calegheri erano i calzolai, i Pistori i fornai, i Calafati i carpentieri navali. La Frezzeria vendeva frecce per balestre, la Naranzaria arance. Comunità straniere lasciarono il nome ai loro quartieri: Furlani, Albanesi, Greci, Bergamaschi. I tedeschi e i turchi avevano i loro fondaci a Rialto. Persino le insegne delle osterie diventavano toponomastica: Calle del Gambaro, dello Storione, della Scimmia. Il ghetto di Cannaregio ha dato il suo nome a tutte le lingue del mondo.",
            historyNapoleonTitle: "1797–1813: Napoleone scrive i nomi sui muri",
            historyNapoleonContent: "Con la caduta della Serenissima nel 1797, l'amministrazione francese introduce la razionalizzazione burocratica. Il 24 settembre 1801, sotto Francesco II, viene adottata ufficialmente la numerazione civica progressiva per sestiere — un sistema mutuato da quello che Giuseppe II aveva già applicato a Milano nel 1786. Tra il 1808 e il 1813 i francesi istituiscono il catasto e fanno dipingere fisicamente i nizioleti sui muri: i nomi che la città si dava da secoli vengono per la prima volta scritti sulla pietra.",
            historyAustrianTitle: "1814–1866: gli austriaci consolidano il sistema",
            historyAustrianContent: "Tornata all'Austria dopo la caduta di Napoleone, Venezia affida il proprio territorio alla precisione burocratica asburgica. Il catasto austriaco (1838–1842) standardizza e completa il lavoro iniziato dai francesi. È in questo periodo che il sistema raggiunge la forma definitiva che usiamo ancora oggi. Quando nel 1866 Venezia entra nel Regno d'Italia, il sistema viene mantenuto invariato — segno che era già radicato e funzionale.",

            sectionAppearance: "Aspetto",
            theme: "Tema",
            themeLight: "Chiara",
            themeDark: "Scura",
            themeSystem: "Sistema",
            sectionMap: "Mappa",
            mapView: "Vista mappa",
            navigationLabel: "Navigazione",
            navFooter: "L'app di navigazione verrà usata quando premi \"Naviga\". Se l'app scelta non è installata, si aprirà Apple Maps.",
            sectionLanguage: "Lingua",
            languageLabel: "Lingua",
            languageFooter: "Seleziona la lingua preferita dell'app.",
            sectionPermissions: "Permessi",
            locationLabel: "Posizione",
            notificationsLabel: "Notifiche",
            permissionsFooter: "Puoi gestire i permessi nelle Impostazioni di sistema.",
            permissionGranted: "Concesso",
            permissionDenied: "Negato",
            permissionNotRequested: "Non richiesto",
            permissionUnknown: "Sconosciuto",
            sectionAbout: "Info",
            versionLabel: "Versione",
            settingsNavTitle: "Impostazioni",
            alwaysAsk: "Chiedi sempre",

            servicesTitle: "Servizi",
            servicesSubtitle: "Informazioni utili per chi vive e visita Venezia",
            servicesAvailable: "DISPONIBILI",
            waterBusTitle: "Vaporetti",
            waterBusSearchPlaceholder: "Cerca fermata o linea...",
            waterBusNoResults: "Nessuna fermata trovata",
            waterBusLines: "Linee",
            waterBusNextDepartures: "Prossime partenze",
            waterBusNavigate: "Naviga alla fermata",
            waterBusAllLines: "Tutte",
            waterBusTime: "Ora",
            waterBusLine: "Linea",
            waterBusDirection: "Direzione",
            waterBusNoDepartures: "Nessuna partenza programmata",
            waterBusStopsCount: { n in "\(n) \(n == 1 ? "fermata" : "fermate")" },
            waterBusStops: "Fermate",
            waterBusNoLines: "Nessuna linea trovata",
            waterBusRouteStops: "FERMATE DEL PERCORSO",

            pharmaciesTitle: "Farmacie",
            pharmaciesOpenCount: { open, total in "\(open) aperte su \(total)" },
            pharmaciesAllClosed: "Tutte chiuse in questo momento",
            pharmaciesOpenNow: "APERTE ORA",
            pharmaciesClosedNow: "CHIUSE",
            pharmacyOpen: "Aperta",
            pharmacyClosed: "Chiusa",
            pharmacyClosesAt: { time in "Chiude alle \(time)" },
            pharmacyHoursLabel: "Orario",
            pharmacyPhoneLabel: "Telefono",
            pharmacyAreaLabel: "Zona",
            pharmacyCall: "Chiama"
        )

        // MARK: - English

        static let en = Strings(
            tabHome: "Home",
            tabSearch: "Civics",
            tabServices: "Services",
            tabInfo: "Info",
            tabSettings: "Settings",

            homeCiviciTitle: "Civic Numbers",
            homeTagline: "Where are you going today?",
            tagline: "Find every civic number in Venice",
            selectSestiere: "SELECT A SESTIERE",
            otherAreas: "OTHER AREAS",
            islands: "ISLANDS",

            civicNumberPlaceholder: "Civic number",
            keepTypingToFilter: "Keep typing to filter...",
            civiciLabel: { n in "\(n) \(n == 1 ? "number" : "numbers")" },
            streetsLabel: { n in "\(n) \(n == 1 ? "street" : "streets")" },
            resultsLabel: { n in "\(n) \(n == 1 ? "result" : "results")" },

            streetSearchPlaceholder: "Search street, calle, fondamenta...",

            navigate: "Navigate",
            openNavigationWith: "Open navigation with",
            cancel: "Cancel",

            whatIsNizioleto: "What is a nizioleto?",
            whatIsNizioletoCont: "Nizioleti are signs painted on Venice's walls indicating streets, squares and directions. The name comes from the Venetian word for \"little sheet\" — small white rectangles with black text that have guided walkers through the city for centuries.",
            twoAddressingSystems: "Two addressing systems",
            twoAddressingSystemsContent: "The historic center is divided into six sestieri, each with its own independent sequential civic numbering. Knowing just the number isn't enough: you also need the sestiere. The lagoon islands and some central areas use the standard system instead, with street name and number like the rest of Italy.",
            howItWorks: "How it works",
            howItWorksContent: "Choose a sestiere and type the civic number to find it on the map. For islands and standard areas, select the street first and then the number. Tap \"Navigate\" to open directions in Apple Maps, Google Maps or Waze.",
            numberingBySestiere: "Numbering by sestiere",
            ordinaryToponymy: "Ordinary toponymy",
            islandLabel: "island",
            madeWithCare: "Made with care in Venice",

            historyTitle: "History of the system",
            historyOralTitle: "Before the signs: oral toponymy",
            historyOralContent: "Under the Serenissima there were no nizioleti, nor any civic numbering. Venice was divided into roughly seventy contrade — parishes — and people navigated by memory, guided by proximity to churches, wells and squares. Strangers had to ask locals for directions. Street names existed, but only in people's voices.",
            historyNamingTitle: "How names were born",
            historyNamingContent: "Names were practical and descriptive: they indicated who worked there, what was sold, or who lived there. The Calegheri were shoemakers, the Pistori bakers, the Calafati ship carpenters. The Frezzeria sold crossbow arrows, the Naranzaria oranges. Foreign communities left their names on their neighborhoods: Furlani, Albanesi, Greci, Bergamaschi. Germans and Turks had their fondaci at Rialto. Even tavern signs became toponymy: Calle del Gambaro (Crab), dello Storione (Sturgeon), della Scimmia (Monkey). The Ghetto in Cannaregio gave its name to every language in the world.",
            historyNapoleonTitle: "1797–1813: Napoleon writes names on walls",
            historyNapoleonContent: "With the fall of the Serenissima in 1797, French administration introduced bureaucratic rationalization. On 24 September 1801, under Francis II, progressive civic numbering by sestiere was officially adopted — a system borrowed from the one Joseph II had already applied to Milan in 1786. Between 1808 and 1813 the French established the cadastre and had the nizioleti physically painted on walls: names the city had given itself for centuries were written in stone for the first time.",
            historyAustrianTitle: "1814–1866: the Austrians consolidate the system",
            historyAustrianContent: "Returned to Austria after Napoleon's fall, Venice entrusted its territory to Habsburg bureaucratic precision. The Austrian cadastre (1838–1842) standardized and completed the work begun by the French. It was during this period that the system reached the definitive form still in use today. When Venice joined the Kingdom of Italy in 1866, the system was kept unchanged — proof that it was already deeply rooted and functional.",

            sectionAppearance: "Appearance",
            theme: "Theme",
            themeLight: "Light",
            themeDark: "Dark",
            themeSystem: "System",
            sectionMap: "Map",
            mapView: "Map view",
            navigationLabel: "Navigation",
            navFooter: "The navigation app will be used when you tap \"Navigate\". If the chosen app is not installed, Apple Maps will open instead.",
            sectionLanguage: "Language",
            languageLabel: "Language",
            languageFooter: "Select your preferred app language.",
            sectionPermissions: "Permissions",
            locationLabel: "Location",
            notificationsLabel: "Notifications",
            permissionsFooter: "You can manage permissions in System Settings.",
            permissionGranted: "Granted",
            permissionDenied: "Denied",
            permissionNotRequested: "Not requested",
            permissionUnknown: "Unknown",
            sectionAbout: "About",
            versionLabel: "Version",
            settingsNavTitle: "Settings",
            alwaysAsk: "Always ask",

            servicesTitle: "Services",
            servicesSubtitle: "Useful information for those who live in and visit Venice",
            servicesAvailable: "AVAILABLE",
            waterBusTitle: "Water Buses",
            waterBusSearchPlaceholder: "Search stop or line...",
            waterBusNoResults: "No stops found",
            waterBusLines: "Lines",
            waterBusNextDepartures: "Next departures",
            waterBusNavigate: "Navigate to stop",
            waterBusAllLines: "All",
            waterBusTime: "Time",
            waterBusLine: "Line",
            waterBusDirection: "Direction",
            waterBusNoDepartures: "No departures scheduled",
            waterBusStopsCount: { n in "\(n) \(n == 1 ? "stop" : "stops")" },
            waterBusStops: "Stops",
            waterBusNoLines: "No lines found",
            waterBusRouteStops: "ROUTE STOPS",

            pharmaciesTitle: "Pharmacies",
            pharmaciesOpenCount: { open, total in "\(open) open out of \(total)" },
            pharmaciesAllClosed: "All closed right now",
            pharmaciesOpenNow: "OPEN NOW",
            pharmaciesClosedNow: "CLOSED",
            pharmacyOpen: "Open",
            pharmacyClosed: "Closed",
            pharmacyClosesAt: { time in "Closes at \(time)" },
            pharmacyHoursLabel: "Hours",
            pharmacyPhoneLabel: "Phone",
            pharmacyAreaLabel: "Area",
            pharmacyCall: "Call"
        )
    }
}
