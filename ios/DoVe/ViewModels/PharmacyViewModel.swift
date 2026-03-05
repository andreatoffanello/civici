import Foundation
import CoreLocation

@MainActor @Observable
final class PharmacyViewModel {
    private(set) var pharmacies: [Pharmacy] = []
    private(set) var isLoaded = false
    var selectedPharmacy: Pharmacy?

    private static let remoteURL = URL(string: "https://andreatoffanello.github.io/civici/api/farmacie.json")!

    func loadData() {
        guard !isLoaded else { return }

        // Try remote first, then fall back to bundled
        Task {
            let result = await Self.fetchPharmacies()
            self.pharmacies = result
            self.isLoaded = true
        }
    }

    // MARK: - Computed

    var openPharmacies: [Pharmacy] {
        pharmacies.filter { $0.isOpen() }
    }

    var closedPharmacies: [Pharmacy] {
        pharmacies.filter { !$0.isOpen() }
    }

    func pharmaciesSortedByDistance(from location: CLLocation?) -> [Pharmacy] {
        guard let location else { return pharmacies }
        return pharmacies.sorted { a, b in
            let distA = location.distance(from: CLLocation(latitude: a.coordinate.latitude, longitude: a.coordinate.longitude))
            let distB = location.distance(from: CLLocation(latitude: b.coordinate.latitude, longitude: b.coordinate.longitude))
            return distA < distB
        }
    }

    func sortedForDisplay(from location: CLLocation?) -> (open: [Pharmacy], closed: [Pharmacy]) {
        let sorted = pharmaciesSortedByDistance(from: location)
        let open = sorted.filter { $0.isOpen() }
        let closed = sorted.filter { !$0.isOpen() }
        return (open, closed)
    }

    func reset() {
        selectedPharmacy = nil
    }

    // MARK: - Data Loading (static to avoid concurrency issues)

    private static func fetchPharmacies() async -> [Pharmacy] {
        // Try remote first
        if let remote = await fetchRemote() {
            return remote
        }
        // Fallback to bundled
        return loadBundled()
    }

    private static func fetchRemote() async -> [Pharmacy]? {
        do {
            var request = URLRequest(url: remoteURL)
            request.timeoutInterval = 8
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else { return nil }
            let result = parseData(data)
            return result?.isEmpty == false ? result : nil
        } catch {
            return nil
        }
    }

    private static func loadBundled() -> [Pharmacy] {
        guard let url = Bundle.main.url(forResource: "farmacie", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            return []
        }
        return parseData(data) ?? []
    }

    // MARK: - Parse

    private static func parseData(_ data: Data) -> [Pharmacy]? {
        guard let json = try? JSONSerialization.jsonObject(with: data) else { return nil }

        // Support both wrapped {"pharmacies": [...]} and plain array [...]
        let rawArray: [[String: Any]]
        if let dict = json as? [String: Any], let arr = dict["pharmacies"] as? [[String: Any]] {
            rawArray = arr
        } else if let arr = json as? [[String: Any]] {
            rawArray = arr
        } else {
            return nil
        }

        return rawArray.compactMap { parsePharmacy($0) }
    }

    private static func parsePharmacy(_ dict: [String: Any]) -> Pharmacy? {
        guard let id = dict["id"] as? String,
              let name = dict["name"] as? String,
              let address = dict["address"] as? String,
              let phone = dict["phone"] as? String,
              let lat = dict["lat"] as? Double,
              let lng = dict["lng"] as? Double else {
            return nil
        }

        let sestiereCode = dict["sestiereCode"] as? String
        let sestiere: Sestiere? = sestiereCode.flatMap { Sestiere(rawValue: $0) }
        let zonaCode = dict["zonaCode"] as? String

        // Parse hours
        let hoursDict = dict["hours"] as? [String: Any]
        let weekday = parseDayHours(hoursDict?["weekday"])
        let saturday = parseDayHours(hoursDict?["saturday"])
        let sunday = parseDayHours(hoursDict?["sunday"])

        // Parse turpi dates
        let turpiDates = dict["turpiDates"] as? [String] ?? []

        return Pharmacy(
            id: id,
            name: name,
            address: address,
            sestiere: sestiere,
            zonaCode: zonaCode,
            phone: phone,
            coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng),
            hours: PharmacyHours(weekday: weekday, saturday: saturday, sunday: sunday),
            turpiDates: turpiDates
        )
    }

    private static func parseDayHours(_ value: Any?) -> DayHours? {
        guard let dict = value as? [String: String],
              let open = dict["open"],
              let close = dict["close"] else {
            return nil
        }
        return DayHours(open: open, close: close)
    }
}
