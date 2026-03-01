import SwiftUI
import MapKit

enum Sestiere: String, CaseIterable, Identifiable, Codable {
    case cannaregio = "CN"
    case castello = "CS"
    case dorsoduro = "DD"
    case giudecca = "GD"
    case santaCroce = "SC"
    case sanMarco = "SM"
    case sanPolo = "SP"

    var id: String { rawValue }

    var name: String {
        switch self {
        case .cannaregio: "Cannaregio"
        case .castello: "Castello"
        case .dorsoduro: "Dorsoduro"
        case .giudecca: "Giudecca"
        case .santaCroce: "Santa Croce"
        case .sanMarco: "San Marco"
        case .sanPolo: "San Polo"
        }
    }

    var color: Color {
        switch self {
        case .cannaregio: Color(hex: "4A90B8")
        case .castello: Color(hex: "5BA86B")
        case .dorsoduro: Color(hex: "D4A843")
        case .giudecca: Color(hex: "8B7BB8")
        case .santaCroce: Color(hex: "C76B7A")
        case .sanMarco: Color(hex: "D4885A")
        case .sanPolo: Color(hex: "5AACAC")
        }
    }

    var coordinate: CLLocationCoordinate2D {
        switch self {
        case .cannaregio: CLLocationCoordinate2D(latitude: 45.4435, longitude: 12.3308)
        case .castello: CLLocationCoordinate2D(latitude: 45.4333, longitude: 12.3492)
        case .dorsoduro: CLLocationCoordinate2D(latitude: 45.4308, longitude: 12.3257)
        case .giudecca: CLLocationCoordinate2D(latitude: 45.4266, longitude: 12.3253)
        case .santaCroce: CLLocationCoordinate2D(latitude: 45.4396, longitude: 12.3271)
        case .sanMarco: CLLocationCoordinate2D(latitude: 45.4339, longitude: 12.3341)
        case .sanPolo: CLLocationCoordinate2D(latitude: 45.4375, longitude: 12.3300)
        }
    }

    var symbolName: String {
        switch self {
        case .cannaregio: "building.2"
        case .castello: "building.columns"
        case .dorsoduro: "paintpalette"
        case .giudecca: "water.waves"
        case .santaCroce: "leaf"
        case .sanMarco: "star"
        case .sanPolo: "bridge"
        }
    }

    var silhouetteAsset: String {
        switch self {
        case .cannaregio: "sestiere-cannaregio"
        case .castello: "sestiere-castello"
        case .dorsoduro: "sestiere-dorsoduro"
        case .giudecca: "sestiere-giudecca"
        case .santaCroce: "sestiere-santa-croce"
        case .sanMarco: "sestiere-san-marco"
        case .sanPolo: "sestiere-san-polo"
        }
    }

    var numberRange: String {
        switch self {
        case .cannaregio: "1 – 6420"
        case .castello: "1 – 6828"
        case .dorsoduro: "1 – 3901"
        case .giudecca: "1 – 907"
        case .santaCroce: "1 – 2362"
        case .sanMarco: "1 – 5562"
        case .sanPolo: "1 – 3144"
        }
    }
}
