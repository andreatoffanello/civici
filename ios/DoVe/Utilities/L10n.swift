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
        let tabSearch: String
        let tabInfo: String
        let tabSettings: String

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

        // MARK: - Italian

        static let it = Strings(
            tabSearch: "Cerca",
            tabInfo: "Info",
            tabSettings: "Impostazioni",

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
            alwaysAsk: "Chiedi sempre"
        )

        // MARK: - English

        static let en = Strings(
            tabSearch: "Search",
            tabInfo: "Info",
            tabSettings: "Settings",

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
            alwaysAsk: "Always ask"
        )
    }
}
