import Foundation
import CoreLocation

private extension String {
    /// Normalizza per ricerca: lowercase, rimuove accenti, trim
    var normalized: String {
        self.lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)
            .trimmingCharacters(in: .whitespaces)
    }
}

@MainActor @Observable
final class WaterBusViewModel {
    private(set) var stops: [WaterBusStop] = []
    private(set) var routes: [WaterBusRoute] = []
    private(set) var trips: [String: [(stationId: String, time: String, dock: String?)]] = [:]
    private(set) var isLoaded = false

    /// Lookup O(1) per nome linea → route (evita linear scan ripetuti)
    private var routeIndex: [String: WaterBusRoute] = [:]
    var selectedStop: WaterBusStop?
    var searchText: String = ""

    // Deep-linkable view state
    var deepLinkViewMode: String?
    var deepLinkContentMode: String?

    /// Tick che si incrementa ogni 30s per forzare il ricalcolo delle partenze
    private(set) var departureTick: UInt = 0
    private var tickTask: Task<Void, Never>?

    func startDepartureTicker() {
        guard tickTask == nil else { return }
        tickTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(30))
                self?.departureTick &+= 1
            }
        }
    }

    // MARK: - Favorites

    private static let favoritesKey = "waterBusFavoriteStopIds"

    private(set) var favoriteStopIds: Set<String> = {
        let ids = UserDefaults.standard.stringArray(forKey: favoritesKey) ?? []
        return Set(ids)
    }()

    func isFavorite(_ stop: WaterBusStop) -> Bool {
        favoriteStopIds.contains(stop.id)
    }

    func toggleFavorite(_ stop: WaterBusStop) {
        if favoriteStopIds.contains(stop.id) {
            favoriteStopIds.remove(stop.id)
        } else {
            favoriteStopIds.insert(stop.id)
        }
        UserDefaults.standard.set(Array(favoriteStopIds), forKey: Self.favoritesKey)
    }

    var favoriteStops: [WaterBusStop] {
        stops.filter { favoriteStopIds.contains($0.id) }
    }

    private static let remoteURL = URL(string: "https://andreatoffanello.github.io/civici/api/vaporetti.json")!

    func loadData() {
        guard !isLoaded else { return }
        Task {
            let result = await Self.fetchData()
            self.stops = result.stops
            self.routes = result.routes
            self.trips = result.trips
            self.routeIndex = Dictionary(uniqueKeysWithValues: result.routes.map { ($0.name, $0) })
            self.isLoaded = true
            startDepartureTicker()
        }
    }

    // MARK: - Computed

    var filteredStops: [WaterBusStop] {
        guard !searchText.isEmpty else { return stops }
        return smartSearch(query: searchText)
    }

    func stopsSortedByDistance(from location: CLLocation?) -> [WaterBusStop] {
        let base = searchText.isEmpty ? stops : filteredStops
        guard let location else { return base }
        return base.sorted { a, b in
            let distA = location.distance(from: CLLocation(latitude: a.coordinate.latitude, longitude: a.coordinate.longitude))
            let distB = location.distance(from: CLLocation(latitude: b.coordinate.latitude, longitude: b.coordinate.longitude))
            return distA < distB
        }
    }

    // MARK: - Smart Search

    /// Ricerca intelligente: normalizza accenti, ranking per rilevanza
    private func smartSearch(query: String) -> [WaterBusStop] {
        let q = query.normalized

        struct Scored {
            let stop: WaterBusStop
            let score: Int // lower = better
        }

        let scored: [Scored] = stops.compactMap { stop in
            let name = stop.name.normalized

            // Exact match
            if name == q { return Scored(stop: stop, score: 0) }
            // Starts with query
            if name.hasPrefix(q) { return Scored(stop: stop, score: 1) }
            // Any word starts with query
            let words = name.split(separator: " ").map(String.init)
            if words.contains(where: { $0.hasPrefix(q) }) { return Scored(stop: stop, score: 2) }
            // Contains query
            if name.contains(q) { return Scored(stop: stop, score: 3) }
            // Line number match
            if stop.lines.contains(where: { $0.lowercased() == q }) { return Scored(stop: stop, score: 4) }
            // Line name contains
            if stop.lines.contains(where: { $0.lowercased().contains(q) }) { return Scored(stop: stop, score: 5) }
            // Headsign/destination match (search in departures)
            let matchesHeadsign = stop.departures.values.joined().contains { dep in
                dep.headsign.normalized.contains(q)
            }
            if matchesHeadsign { return Scored(stop: stop, score: 6) }

            return nil
        }

        return scored.sorted { $0.score < $1.score }.map(\.stop)
    }

    /// Partenze di oggi per una fermata, ordinate per orario
    func todayDepartures(for stop: WaterBusStop, date: Date = Date()) -> [Departure] {
        for (group, deps) in stop.departures where group.contains(date: date) {
            return deps.sorted { $0.minutesFromMidnight < $1.minutesFromMidnight }
        }
        return []
    }

    /// Prossime N partenze da una fermata (si aggiorna col tick)
    func nextDepartures(for stop: WaterBusStop, count: Int = 5, date: Date = Date()) -> [Departure] {
        _ = departureTick // subscribe to tick changes
        let today = todayDepartures(for: stop, date: date)
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)
        let nowMinutes = (components.hour ?? 0) * 60 + (components.minute ?? 0)

        var upcoming = today.filter { $0.minutesFromMidnight >= nowMinutes }

        // Se rimangono poche partenze oggi, aggiungi le prime di domani
        // (utile a fine serata quando le prossime sono dopo mezzanotte)
        if upcoming.count < count {
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: date) ?? date
            let tomorrowDeps = todayDepartures(for: stop, date: tomorrow)
            let needed = count - upcoming.count
            upcoming.append(contentsOf: tomorrowDeps.prefix(needed))
        }

        return Array(upcoming.prefix(count))
    }

    /// Route object per nome linea (O(1) via dizionario)
    func route(for lineName: String) -> WaterBusRoute? {
        routeIndex[lineName]
    }

    /// Separa le linee di una fermata in ACTV e Alilaguna
    func linesBySource(for stop: WaterBusStop) -> (actv: [String], alilaguna: [String]) {
        var actv: [String] = []
        var alilaguna: [String] = []
        for line in stop.lines {
            if let r = route(for: line), r.source == "alilaguna" {
                alilaguna.append(line)
            } else {
                actv.append(line)
            }
        }
        let sort: (String, String) -> Bool = { $0.localizedStandardCompare($1) == .orderedAscending }
        return (actv.sorted(by: sort), alilaguna.sorted(by: sort))
    }

    /// Ricostruisce una corsa: se il tripId è disponibile, usa i dati pre-calcolati dalla pipeline;
    /// altrimenti prova una ricostruzione client-side come fallback.
    func reconstructTrip(
        departure: Departure,
        fromStop: WaterBusStop,
        date: Date = Date()
    ) -> (route: WaterBusRoute, direction: RouteDirection, stops: [TripStop])? {
        guard let route = route(for: departure.line) else { return nil }

        // Find the best direction
        let direction: RouteDirection? =
            route.directions.first { $0.stopIds.contains(fromStop.id) && $0.headsign == departure.headsign }
            ?? route.directions.first { $0.stopIds.contains(fromStop.id) }
            ?? route.directions.first { $0.headsign == departure.headsign }
            ?? route.directions.first

        guard let direction else { return nil }

        // Try server-side trip data first
        if let tripId = departure.tripId, let tripStopTimes = trips[tripId] {
            let tripStops: [TripStop] = tripStopTimes.compactMap { entry in
                guard let stop = stops.first(where: { $0.id == entry.stationId }) else { return nil }
                return TripStop(stop: stop, time: entry.time, dock: entry.dock)
            }
            guard !tripStops.isEmpty else { return nil }
            return (route, direction, tripStops)
        }

        // Fallback: client-side reconstruction
        let dayGroup: DayGroup? = fromStop.departures.keys.first { $0.contains(date: date) }
            ?? fromStop.departures.keys.sorted().first
        guard let dayGroup else { return nil }

        let depMinutes = timeToMinutes(departure.time)
        var tripStops: [TripStop] = []

        // Use direction stopIds to walk the route
        let startIdx = direction.stopIds.firstIndex(of: fromStop.id) ?? 0
        let originParsed = parseDock(from: departure.headsign)
        var prevMinutes = depMinutes

        // Backward
        var backStops: [TripStop] = []
        var nextMinutes = depMinutes
        for i in stride(from: startIdx - 1, through: 0, by: -1) {
            let sid = direction.stopIds[i]
            guard let stop = stops.first(where: { $0.id == sid }) else { continue }
            let matching = (stop.departures[dayGroup] ?? [])
                .filter { $0.line == departure.line && $0.headsign == departure.headsign }
                .sorted { timeToMinutes($0.time) < timeToMinutes($1.time) }
            if let found = matching.last(where: { timeToMinutes($0.time) <= nextMinutes }) {
                let p = parseDock(from: found.headsign)
                backStops.insert(TripStop(stop: stop, time: found.time, dock: p.dock), at: 0)
                nextMinutes = timeToMinutes(found.time)
            }
        }
        tripStops.append(contentsOf: backStops)
        tripStops.append(TripStop(stop: fromStop, time: departure.time, dock: originParsed.dock))

        // Forward
        for i in (startIdx + 1)..<direction.stopIds.count {
            let sid = direction.stopIds[i]
            guard let stop = stops.first(where: { $0.id == sid }) else { continue }
            let matching = (stop.departures[dayGroup] ?? [])
                .filter { $0.line == departure.line && $0.headsign == departure.headsign }
                .sorted { timeToMinutes($0.time) < timeToMinutes($1.time) }
            if let found = matching.first(where: { timeToMinutes($0.time) >= prevMinutes }) {
                let p = parseDock(from: found.headsign)
                tripStops.append(TripStop(stop: stop, time: found.time, dock: p.dock))
                prevMinutes = timeToMinutes(found.time)
            }
        }

        guard !tripStops.isEmpty else { return nil }
        return (route, direction, tripStops)
    }

    private func timeToMinutes(_ time: String) -> Int {
        let parts = time.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { return 0 }
        return parts[0] * 60 + parts[1]
    }

    /// Coincidenze: per ogni altra linea che serve la fermata, la prima partenza
    /// dopo l'orario di arrivo + 2 min di trasbordo, entro 30 min
    func connections(at stop: WaterBusStop, arrivalTime: String, excludingLine: String, date: Date = Date()) -> [(line: String, departure: Departure)] {
        let arrivalMinutes = timeToMinutes(arrivalTime) + 2 // min trasbordo
        let maxMinutes = arrivalMinutes + 30
        let today = todayDepartures(for: stop, date: date)

        var firstByLine: [String: Departure] = [:]
        for dep in today where dep.line != excludingLine
            && dep.minutesFromMidnight >= arrivalMinutes
            && dep.minutesFromMidnight <= maxMinutes {
            if firstByLine[dep.line] == nil {
                firstByLine[dep.line] = dep
            }
        }

        return firstByLine
            .map { (line: $0.key, departure: $0.value) }
            .sorted { $0.departure.minutesFromMidnight < $1.departure.minutesFromMidnight }
    }

    /// Linee attive per un dock nelle prossime ore (basato sui trip reali)
    /// Dock di PARTENZA di una corsa a una fermata (dal trip data, non dall'headsign)
    func departureDock(for departure: Departure, at stop: WaterBusStop) -> String? {
        guard let tripId = departure.tripId, let tripStops = trips[tripId] else { return nil }
        return tripStops.first(where: { $0.stationId == stop.id })?.dock
    }

    func activeLinesForDock(stop: WaterBusStop, dockLetter: String, date: Date = Date()) -> [String] {
        _ = departureTick
        let today = todayDepartures(for: stop, date: date)
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)
        let nowMinutes = (components.hour ?? 0) * 60 + (components.minute ?? 0)
        let windowEnd = nowMinutes + 180 // prossime 3 ore

        var lines = Set<String>()
        for dep in today where dep.minutesFromMidnight >= nowMinutes && dep.minutesFromMidnight <= windowEnd {
            // Usa il trip per trovare il dock di PARTENZA a questa fermata
            if let tripId = dep.tripId, let tripStops = trips[tripId] {
                if let entry = tripStops.first(where: { $0.stationId == stop.id }) {
                    if entry.dock == dockLetter {
                        lines.insert(dep.line)
                    }
                }
            }
        }

        let sort: (String, String) -> Bool = { $0.localizedStandardCompare($1) == .orderedAscending }
        return lines.sorted(by: sort)
    }

    func reset() {
        selectedStop = nil
        searchText = ""
    }

    // MARK: - Data Loading

    private static func fetchData() async -> (stops: [WaterBusStop], routes: [WaterBusRoute], trips: [String: [(stationId: String, time: String, dock: String?)]]) {
        if let remote = await fetchRemote() {
            // Se il remote non ha trips (JSON non ancora aggiornato), usa quelli dal bundle
            if remote.trips.isEmpty {
                let bundled = loadBundled()
                return (remote.stops, remote.routes, bundled.trips)
            }
            return remote
        }
        return loadBundled()
    }

    private static func fetchRemote() async -> (stops: [WaterBusStop], routes: [WaterBusRoute], trips: [String: [(stationId: String, time: String, dock: String?)]])? {
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

    private static func loadBundled() -> (stops: [WaterBusStop], routes: [WaterBusRoute], trips: [String: [(stationId: String, time: String, dock: String?)]]) {
        guard let url = Bundle.main.url(forResource: "vaporetti", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            return ([], [], [:])
        }
        return parseData(data)
    }

    // MARK: - Parse

    private static func parseData(_ data: Data) -> (stops: [WaterBusStop], routes: [WaterBusRoute], trips: [String: [(stationId: String, time: String, dock: String?)]]) {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return ([], [], [:])
        }

        let routes = (json["routes"] as? [[String: Any]] ?? []).compactMap { parseRoute($0) }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        let stops = (json["stops"] as? [[String: Any]] ?? []).compactMap { parseStop($0) }

        // Parse trips: {"tripId": [["stationId", "HH:MM", "dock"], ...], ...}
        var trips: [String: [(stationId: String, time: String, dock: String?)]] = [:]
        if let tripsDict = json["trips"] as? [String: [[String]]] {
            for (tripId, stopTimes) in tripsDict {
                trips[tripId] = stopTimes.compactMap { arr in
                    guard arr.count >= 2 else { return nil }
                    let dock = arr.count >= 3 && !arr[2].isEmpty ? arr[2] : nil
                    return (stationId: arr[0], time: arr[1], dock: dock)
                }
            }
        }

        return (stops, routes, trips)
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
                    let tripId = arr.count >= 4 ? arr[3] as? String : nil
                    return Departure(time: time, line: line, headsign: headsign, tripId: tripId)
                }
                departures[group] = deps
            }
        }

        // Parse docks: [{letter, lat, lng, lines}, ...]
        var docks: [Dock] = []
        if let docksArray = dict["docks"] as? [[String: Any]] {
            for dockDict in docksArray {
                guard let letter = dockDict["letter"] as? String,
                      let dLat = dockDict["lat"] as? Double,
                      let dLng = dockDict["lng"] as? Double else { continue }
                let dockLines = dockDict["lines"] as? [String] ?? []
                docks.append(Dock(
                    letter: letter,
                    coordinate: CLLocationCoordinate2D(latitude: dLat, longitude: dLng),
                    lines: dockLines
                ))
            }
        }

        return WaterBusStop(
            id: id,
            name: name,
            coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng),
            lines: lines,
            departures: departures,
            docks: docks
        )
    }
}
