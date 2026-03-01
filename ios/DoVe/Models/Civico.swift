import Foundation
import MapKit

struct Civico: Identifiable, Hashable {
    let sestiere: Sestiere?
    let zona: ZonaNormale?
    let number: String
    let coordinate: CLLocationCoordinate2D
    let via: String?

    /// Inizializza per sestiere (numerazione progressiva)
    init(sestiere: Sestiere, number: String, coordinate: CLLocationCoordinate2D, via: String?) {
        self.sestiere = sestiere
        self.zona = nil
        self.number = number
        self.coordinate = coordinate
        self.via = via
    }

    /// Inizializza per zona normale (toponimo/civico)
    init(zona: ZonaNormale, number: String, coordinate: CLLocationCoordinate2D, via: String?) {
        self.sestiere = nil
        self.zona = zona
        self.number = number
        self.coordinate = coordinate
        self.via = via
    }

    var areaName: String {
        sestiere?.name ?? zona?.name ?? ""
    }

    var areaCode: String {
        sestiere?.rawValue ?? zona?.rawValue ?? ""
    }

    var id: String { "\(areaCode)-\(via ?? "")-\(number)" }

    var displayName: String {
        if let via {
            return "\(areaName) – \(via) \(number)"
        }
        return "\(areaName) \(number)"
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Civico, rhs: Civico) -> Bool {
        lhs.id == rhs.id
    }
}
