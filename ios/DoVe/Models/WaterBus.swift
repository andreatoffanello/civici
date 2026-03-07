import Foundation
import CoreLocation
import SwiftUI

// MARK: - WaterBus Stop (fermata vaporetto)

struct WaterBusStop: Identifiable, Hashable {
    let id: String
    let name: String
    let coordinate: CLLocationCoordinate2D
    let lines: [String]
    let departures: [DayGroup: [Departure]]

    static func == (lhs: WaterBusStop, rhs: WaterBusStop) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// MARK: - Day Group

/// Raggruppa i giorni con orari identici (es. "mon,tue,wed,thu,fri")
struct DayGroup: Hashable, Comparable {
    let days: [WeekDay]

    var key: String { days.map(\.rawValue).joined(separator: ",") }

    var localizedLabel: String {
        if days.count == 7 { return "Tutti i giorni" }
        if days == WeekDay.weekdays { return "Lun–Ven" }
        if days == WeekDay.weekend { return "Sab–Dom" }
        if days.count == 6 && !days.contains(.sun) { return "Lun–Sab" }
        return days.map(\.shortLabel).joined(separator: ", ")
    }

    func contains(date: Date) -> Bool {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        let mapped = WeekDay.from(calendarWeekday: weekday)
        return days.contains(mapped)
    }

    static func < (lhs: DayGroup, rhs: DayGroup) -> Bool {
        lhs.days.first?.sortIndex ?? 0 < rhs.days.first?.sortIndex ?? 0
    }

    init(key: String) {
        self.days = key.split(separator: ",").compactMap { WeekDay(rawValue: String($0)) }
    }
}

enum WeekDay: String, CaseIterable {
    case mon, tue, wed, thu, fri, sat, sun

    var shortLabel: String {
        switch self {
        case .mon: "Lun"
        case .tue: "Mar"
        case .wed: "Mer"
        case .thu: "Gio"
        case .fri: "Ven"
        case .sat: "Sab"
        case .sun: "Dom"
        }
    }

    var sortIndex: Int {
        switch self {
        case .mon: 0
        case .tue: 1
        case .wed: 2
        case .thu: 3
        case .fri: 4
        case .sat: 5
        case .sun: 6
        }
    }

    static let weekdays: [WeekDay] = [.mon, .tue, .wed, .thu, .fri]
    static let weekend: [WeekDay] = [.sat, .sun]

    static func from(calendarWeekday: Int) -> WeekDay {
        // Calendar: 1=Sun, 2=Mon, ...
        switch calendarWeekday {
        case 1: .sun
        case 2: .mon
        case 3: .tue
        case 4: .wed
        case 5: .thu
        case 6: .fri
        case 7: .sat
        default: .mon
        }
    }
}

// MARK: - Departure

struct Departure: Identifiable, Hashable {
    let time: String      // "HH:MM"
    let line: String      // "1", "2", "A", "B", "N"
    let headsign: String  // "Lido S.M.E."

    var id: String { "\(time)_\(line)_\(headsign)" }

    /// Minuti dalla mezzanotte, per ordinamento e calcolo "prossima partenza"
    var minutesFromMidnight: Int {
        let parts = time.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { return 0 }
        return parts[0] * 60 + parts[1]
    }

    /// Minuti rimanenti da ora
    func minutesUntil(from date: Date = Date()) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)
        let nowMinutes = (components.hour ?? 0) * 60 + (components.minute ?? 0)
        let diff = minutesFromMidnight - nowMinutes
        return diff >= 0 ? diff : diff + 1440  // wrap around midnight
    }

    /// Label leggibile per il countdown
    var countdownLabel: String {
        let mins = minutesUntil()
        switch mins {
        case 0:      return "in partenza"
        case 1...59: return "tra \(mins) min"
        default:
            let h = mins / 60
            let m = mins % 60
            return m > 0 ? "tra \(h)h \(m)min" : "tra \(h)h"
        }
    }

    /// true se la partenza è davvero imminente (≤ 1 min) — usato per il pallino pulsante
    var isImminent: Bool {
        minutesUntil() <= 1
    }

    /// true se la partenza è vicina (≤ 5 min) — usato per il colore verde
    var isSoon: Bool {
        minutesUntil() <= 5
    }
}

// MARK: - Route (linea)

struct WaterBusRoute: Identifiable, Hashable {
    let id: String
    let name: String
    let longName: String
    let color: Color
    let textColor: Color
    let source: String  // "actv" or "alilaguna"
    let directions: [RouteDirection]

    static func == (lhs: WaterBusRoute, rhs: WaterBusRoute) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// MARK: - Route Direction

struct RouteDirection: Identifiable, Hashable {
    let id: Int       // 0 = andata, 1 = ritorno
    let headsign: String
    let stopIds: [String]
    let shape: [[Double]]  // [[lat, lng], ...]

    var coordinates: [CLLocationCoordinate2D] {
        shape.compactMap { point in
            guard point.count >= 2 else { return nil }
            return CLLocationCoordinate2D(latitude: point[0], longitude: point[1])
        }
    }
}
