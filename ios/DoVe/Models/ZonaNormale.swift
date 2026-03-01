import SwiftUI
import MapKit

/// Zone con sistema di indirizzamento "normale" (toponimo/civico)
/// anziché numerazione progressiva per sestiere.
enum ZonaNormale: String, CaseIterable, Identifiable {
    case murano = "MU"
    case burano = "BU"
    case torcello = "TO"
    case mazzorbo = "MZ"
    case lido = "LI"
    case pellestrina = "PE"
    case santErasmo = "SR"
    case vignole = "VI"
    case certosa = "CE"
    case santElena = "SE"
    case saccaFisola = "SF"

    var id: String { rawValue }

    var name: String {
        switch self {
        case .murano: "Murano"
        case .burano: "Burano"
        case .torcello: "Torcello"
        case .mazzorbo: "Mazzorbo"
        case .lido: "Lido"
        case .pellestrina: "Pellestrina"
        case .santErasmo: "Sant'Erasmo"
        case .vignole: "Vignole"
        case .certosa: "Certosa"
        case .santElena: "Sant'Elena"
        case .saccaFisola: "Sacca Fisola"
        }
    }

    var color: Color {
        switch self {
        case .murano: Color(hex: "B85A8A")
        case .burano: Color(hex: "E06B45")
        case .torcello: Color(hex: "6B8E5A")
        case .mazzorbo: Color(hex: "C4956A")
        case .lido: Color(hex: "4A90B8")
        case .pellestrina: Color(hex: "5AACAC")
        case .santErasmo: Color(hex: "8B9E5A")
        case .vignole: Color(hex: "7AAA6B")
        case .certosa: Color(hex: "5A8A7A")
        case .santElena: Color(hex: "5BA86B")
        case .saccaFisola: Color(hex: "8B7BB8")
        }
    }

    var coordinate: CLLocationCoordinate2D {
        switch self {
        case .murano: CLLocationCoordinate2D(latitude: 45.4585, longitude: 12.3520)
        case .burano: CLLocationCoordinate2D(latitude: 45.4855, longitude: 12.4170)
        case .torcello: CLLocationCoordinate2D(latitude: 45.4970, longitude: 12.4180)
        case .mazzorbo: CLLocationCoordinate2D(latitude: 45.4880, longitude: 12.4080)
        case .lido: CLLocationCoordinate2D(latitude: 45.4050, longitude: 12.3600)
        case .pellestrina: CLLocationCoordinate2D(latitude: 45.3200, longitude: 12.3100)
        case .santErasmo: CLLocationCoordinate2D(latitude: 45.4780, longitude: 12.4150)
        case .vignole: CLLocationCoordinate2D(latitude: 45.4480, longitude: 12.3800)
        case .certosa: CLLocationCoordinate2D(latitude: 45.4400, longitude: 12.3680)
        case .santElena: CLLocationCoordinate2D(latitude: 45.4275, longitude: 12.3630)
        case .saccaFisola: CLLocationCoordinate2D(latitude: 45.4260, longitude: 12.3130)
        }
    }

    var symbolName: String {
        switch self {
        case .murano: "flame"
        case .burano: "house"
        case .torcello: "tree"
        case .mazzorbo: "leaf.circle"
        case .lido: "beach.umbrella"
        case .pellestrina: "water.waves"
        case .santErasmo: "carrot"
        case .vignole: "leaf"
        case .certosa: "building"
        case .santElena: "figure.walk"
        case .saccaFisola: "building.2"
        }
    }

    var silhouetteAsset: String {
        switch self {
        case .murano: "isola-murano"
        case .burano: "isola-burano"
        case .torcello: "isola-torcello"
        case .mazzorbo: "isola-mazzorbo"
        case .lido: "isola-lido"
        case .pellestrina: "isola-pellestrina"
        case .santErasmo: "isola-sant-erasmo"
        case .vignole: "isola-vignole"
        case .certosa: "isola-certosa"
        case .santElena: "isola-sant-elena"
        case .saccaFisola: "isola-sacca-fisola"
        }
    }

    /// Isole della laguna
    static var isole: [ZonaNormale] {
        [.murano, .burano, .torcello, .mazzorbo, .lido, .pellestrina, .santErasmo, .vignole, .certosa]
    }

    /// Zone del centro storico con indirizzamento normale
    static var zoneCentro: [ZonaNormale] {
        [.santElena, .saccaFisola]
    }
}
