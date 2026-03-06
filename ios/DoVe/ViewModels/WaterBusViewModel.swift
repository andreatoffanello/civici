import Foundation
import CoreLocation

@MainActor @Observable
final class WaterBusViewModel {
    private(set) var stops: [WaterBusStop] = []
    private(set) var routes: [WaterBusRoute] = []
    private(set) var isLoaded = false
    var selectedStop: WaterBusStop?
    var searchText: String = ""

    private static let remoteURL = URL(string: "https://andreatoffanello.github.io/civici/api/vaporetti.json")!

    func loadData() {
        guard !isLoaded else { return }
        Task {
            let result = await Self.fetchData()
            self.stops = result.stops
            self.routes = result.routes
            self.isLoaded = true
        }
    }

    // MARK: - Computed

    var filteredStops: [WaterBusStop] {
        guard !searchText.isEmpty else { return stops }
        let query = searchText.lowercased()
        return stops.filter { stop in
            stop.name.lowercased().contains(query) ||
            stop.lines.contains { $0.lowercased().contains(query) }
        }
    }

    func stopsSortedByDistance(from location: CLLocation?) -> [WaterBusStop] {
        guard let location else { return filteredStops }
        return filteredStops.sorted { a, b in
            let distA = location.distance(from: CLLocation(latitude: a.coordinate.latitude, longitude: a.coordinate.longitude))
            let distB = location.distance(from: CLLocation(latitude: b.coordinate.latitude, longitude: b.coordinate.longitude))
            return distA < distB
        }
    }

    /// Partenze di oggi per una fermata, ordinate per orario
    func todayDepartures(for stop: WaterBusStop, date: Date = Date()) -> [Departure] {
        for (group, deps) in stop.departures where group.contains(date: date) {
            return deps
        }
        return []
    }

    /// Prossime N partenze da una fermata
    func nextDepartures(for stop: WaterBusStop, count: Int = 5, date: Date = Date()) -> [Departure] {
        let today = todayDepartures(for: stop, date: date)
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)
        let nowMinutes = (components.hour ?? 0) * 60 + (components.minute ?? 0)

        let upcoming = today.filter { $0.minutesFromMidnight >= nowMinutes }
        return Array(upcoming.prefix(count))
    }

    /// Route object per nome linea
    func route(for lineName: String) -> WaterBusRoute? {
        routes.first { $0.name == lineName }
    }

    func reset() {
        selectedStop = nil
        searchText = ""
    }

    // MARK: - Data Loading

    private static func fetchData() async -> (stops: [WaterBusStop], routes: [WaterBusRoute]) {
        if let remote = await fetchRemote() { return remote }
        return loadBundled()
    }

    private static func fetchRemote() async -> (stops: [WaterBusStop], routes: [WaterBusRoute])? {
        do {
            var request = URLRequest(url: remoteURL)
            request.timeoutInterval = 10
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else { return nil }
            let result = parseData(data)
            // Require stops and routes with directions to be valid
            guard !result.stops.isEmpty,
                  result.routes.contains(where: { !$0.directions.isEmpty }) else { return nil }
            return result
        } catch {
            return nil
        }
    }

    private static func loadBundled() -> (stops: [WaterBusStop], routes: [WaterBusRoute]) {
        guard let url = Bundle.main.url(forResource: "vaporetti", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            return ([], [])
        }
        return parseData(data)
    }

    // MARK: - Parse

    private static func parseData(_ data: Data) -> (stops: [WaterBusStop], routes: [WaterBusRoute]) {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return ([], [])
        }

        let routes = (json["routes"] as? [[String: Any]] ?? []).compactMap { parseRoute($0) }
        let stops = (json["stops"] as? [[String: Any]] ?? []).compactMap { parseStop($0) }

        return (stops, routes)
    }

    var filteredRoutes: [WaterBusRoute] {
        guard !searchText.isEmpty else { return routes }
        let query = searchText.lowercased()
        return routes.filter { route in
            route.name.lowercased().contains(query) ||
            route.longName.lowercased().contains(query) ||
            route.directions.contains { $0.headsign.lowercased().contains(query) }
        }
    }

    func stopsForRoute(_ route: WaterBusRoute, direction: Int) -> [WaterBusStop] {
        guard let dir = route.directions.first(where: { $0.id == direction }) else {
            return []
        }
        return dir.stopIds.compactMap { stopId in
            stops.first { $0.id == stopId }
        }
    }

    // MARK: - Parse Route

    private static func parseRoute(_ dict: [String: Any]) -> WaterBusRoute? {
        guard let id = dict["id"] as? String,
              let name = dict["name"] as? String else { return nil }

        let longName = dict["longName"] as? String ?? ""
        let colorHex = dict["color"] as? String ?? "#000000"
        let textColorHex = dict["textColor"] as? String ?? "#FFFFFF"
        let source = dict["source"] as? String ?? "actv"

        var directions: [RouteDirection] = []
        if let dirsArray = dict["directions"] as? [[String: Any]] {
            for dirDict in dirsArray {
                guard let dirId = dirDict["id"] as? Int,
                      let headsign = dirDict["headsign"] as? String else { continue }
                let stopIds = dirDict["stopIds"] as? [String] ?? []
                let shape = dirDict["shape"] as? [[Double]] ?? []
                directions.append(RouteDirection(
                    id: dirId,
                    headsign: headsign,
                    stopIds: stopIds,
                    shape: shape
                ))
            }
        }

        return WaterBusRoute(
            id: id,
            name: name,
            longName: longName,
            color: .init(hex: colorHex),
            textColor: .init(hex: textColorHex),
            source: source,
            directions: directions
        )
    }

    private static func parseStop(_ dict: [String: Any]) -> WaterBusStop? {
        guard let id = dict["id"] as? String,
              let name = dict["name"] as? String,
              let lat = dict["lat"] as? Double,
              let lng = dict["lng"] as? Double else { return nil }

        let lines = dict["lines"] as? [String] ?? []

        // Parse departures: {"mon,tue,...": [["HH:MM","line","headsign"], ...]}
        var departures: [DayGroup: [Departure]] = [:]
        if let depsDict = dict["departures"] as? [String: [[Any]]] {
            for (dayKey, entries) in depsDict {
                let group = DayGroup(key: dayKey)
                let deps = entries.compactMap { arr -> Departure? in
                    guard arr.count >= 3,
                          let time = arr[0] as? String,
                          let line = arr[1] as? String,
                          let headsign = arr[2] as? String else { return nil }
                    return Departure(time: time, line: line, headsign: headsign)
                }
                departures[group] = deps
            }
        }

        return WaterBusStop(
            id: id,
            name: name,
            coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng),
            lines: lines,
            departures: departures
        )
    }
}
