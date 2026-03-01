import Foundation
import MapKit

struct CiviciCoordinate: Codable {
    let lat: Double
    let lng: Double
    let via: String?
}

struct SimpleCoordinate: Codable {
    let lat: Double
    let lng: Double
}

typealias CiviciData = [String: [String: CiviciCoordinate]]
/// zone_normali.json: { "MU": { "Fondamenta Dei Vetrai": { "122": { "lat": ..., "lng": ... } } } }
typealias ZoneNormaliData = [String: [String: [String: SimpleCoordinate]]]

final class DataLoader: Sendable {
    static let shared = DataLoader()

    private let data: CiviciData?
    private let zoneData: ZoneNormaliData?

    private init() {
        data = DataLoader.loadData()
        zoneData = DataLoader.loadZoneNormali()
    }

    private static func loadData() -> CiviciData? {
        guard let url = Bundle.main.url(forResource: "civici", withExtension: "json"),
              let jsonData = try? Data(contentsOf: url) else {
            print("Failed to load civici.json")
            return nil
        }

        do {
            return try JSONDecoder().decode(CiviciData.self, from: jsonData)
        } catch {
            print("Failed to decode civici.json: \(error)")
            return nil
        }
    }

    private static func loadZoneNormali() -> ZoneNormaliData? {
        guard let url = Bundle.main.url(forResource: "zone_normali", withExtension: "json"),
              let jsonData = try? Data(contentsOf: url) else {
            print("Failed to load zone_normali.json")
            return nil
        }

        do {
            return try JSONDecoder().decode(ZoneNormaliData.self, from: jsonData)
        } catch {
            print("Failed to decode zone_normali.json: \(error)")
            return nil
        }
    }

    func numbers(for sestiere: Sestiere) -> [String] {
        guard let sestiereData = data?[sestiere.rawValue] else { return [] }
        return sestiereData.keys.sorted { a, b in
            let numA = Int(a) ?? Int.max
            let numB = Int(b) ?? Int.max
            if numA != numB { return numA < numB }
            return a < b
        }
    }

    func coordinate(for sestiere: Sestiere, number: String) -> CLLocationCoordinate2D? {
        guard let coord = data?[sestiere.rawValue]?[number] else { return nil }
        return CLLocationCoordinate2D(latitude: coord.lat, longitude: coord.lng)
    }

    func civico(for sestiere: Sestiere, number: String) -> Civico? {
        guard let coord = data?[sestiere.rawValue]?[number] else { return nil }
        let coordinate = CLLocationCoordinate2D(latitude: coord.lat, longitude: coord.lng)
        return Civico(sestiere: sestiere, number: number, coordinate: coordinate, via: coord.via)
    }

    func totalCount(for sestiere: Sestiere) -> Int {
        data?[sestiere.rawValue]?.count ?? 0
    }

    // MARK: - Zone normali

    func streets(for zona: ZonaNormale) -> [String] {
        guard let streets = zoneData?[zona.rawValue] else { return [] }
        return streets.keys.sorted()
    }

    func numbers(for zona: ZonaNormale, street: String) -> [String] {
        guard let nums = zoneData?[zona.rawValue]?[street] else { return [] }
        return nums.keys.sorted { a, b in
            let numA = Int(a.split(separator: "/").first.map(String.init) ?? a) ?? Int.max
            let numB = Int(b.split(separator: "/").first.map(String.init) ?? b) ?? Int.max
            if numA != numB { return numA < numB }
            return a < b
        }
    }

    func civico(for zona: ZonaNormale, street: String, number: String) -> Civico? {
        guard let coord = zoneData?[zona.rawValue]?[street]?[number] else { return nil }
        let coordinate = CLLocationCoordinate2D(latitude: coord.lat, longitude: coord.lng)
        return Civico(zona: zona, number: number, coordinate: coordinate, via: street)
    }

    func totalCount(for zona: ZonaNormale) -> Int {
        guard let streets = zoneData?[zona.rawValue] else { return 0 }
        return streets.values.reduce(0) { $0 + $1.count }
    }
}
