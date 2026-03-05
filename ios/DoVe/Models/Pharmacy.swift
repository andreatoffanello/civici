import Foundation
import CoreLocation
import SwiftUI

struct Pharmacy: Identifiable, Hashable {
    let id: String
    let name: String
    let address: String
    let sestiere: Sestiere?
    let zonaCode: String?
    let phone: String
    let coordinate: CLLocationCoordinate2D
    let hours: PharmacyHours
    let turpiDates: [String]

    var areaColor: Color {
        if let sestiere {
            return sestiere.color
        }
        if let zonaCode, let zona = ZonaNormale(rawValue: zonaCode) {
            return zona.color
        }
        return Color.secondary
    }

    var areaName: String {
        if let sestiere {
            return sestiere.name
        }
        if let zonaCode, let zona = ZonaNormale(rawValue: zonaCode) {
            return zona.name
        }
        return ""
    }

    func isOnDuty(at date: Date = Date()) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: date)
        return turpiDates.contains(dateStr)
    }

    func isOpen(at date: Date = Date()) -> Bool {
        // If on 24h duty, always open
        if isOnDuty(at: date) { return true }

        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute, .weekday], from: date)
        guard let hour = components.hour, let minute = components.minute, let weekday = components.weekday else {
            return false
        }

        let currentMinutes = hour * 60 + minute
        let daySlot: DayHours?

        switch weekday {
        case 1: // Sunday
            daySlot = hours.sunday
        case 7: // Saturday
            daySlot = hours.saturday
        default: // Weekday
            daySlot = hours.weekday
        }

        guard let slot = daySlot else { return false }
        let openMinutes = slot.openHour * 60 + slot.openMinute
        let closeMinutes = slot.closeHour * 60 + slot.closeMinute
        return currentMinutes >= openMinutes && currentMinutes < closeMinutes
    }

    func nextOpeningDescription(strings: L10n.Strings, at date: Date = Date()) -> String {
        if isOnDuty(at: date) {
            return "24h (turno)"
        }
        if isOpen(at: date) {
            let calendar = Calendar.current
            let weekday = calendar.component(.weekday, from: date)
            let slot: DayHours?
            switch weekday {
            case 1: slot = hours.sunday
            case 7: slot = hours.saturday
            default: slot = hours.weekday
            }
            if let slot {
                return strings.pharmacyClosesAt(slot.closeFormatted)
            }
            return strings.pharmacyOpen
        } else {
            return strings.pharmacyClosed
        }
    }

    func todayHoursFormatted(at date: Date = Date()) -> String? {
        if isOnDuty(at: date) { return "24h (turno)" }

        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        let slot: DayHours?
        switch weekday {
        case 1: slot = hours.sunday
        case 7: slot = hours.saturday
        default: slot = hours.weekday
        }
        guard let slot else { return nil }
        return "\(slot.openFormatted) – \(slot.closeFormatted)"
    }

    // MARK: Hashable
    static func == (lhs: Pharmacy, rhs: Pharmacy) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct PharmacyHours: Hashable {
    let weekday: DayHours?
    let saturday: DayHours?
    let sunday: DayHours?
}

struct DayHours: Hashable {
    let openHour: Int
    let openMinute: Int
    let closeHour: Int
    let closeMinute: Int

    var openFormatted: String {
        String(format: "%d:%02d", openHour, openMinute)
    }

    var closeFormatted: String {
        String(format: "%d:%02d", closeHour, closeMinute)
    }

    init(open: String, close: String) {
        let openParts = open.split(separator: ":").map { Int($0) ?? 0 }
        let closeParts = close.split(separator: ":").map { Int($0) ?? 0 }
        self.openHour = openParts.first ?? 0
        self.openMinute = openParts.count > 1 ? openParts[1] : 0
        self.closeHour = closeParts.first ?? 0
        self.closeMinute = closeParts.count > 1 ? closeParts[1] : 0
    }
}
