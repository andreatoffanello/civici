import Foundation
import Observation

@Observable
final class SearchViewModel {
    var selectedSestiere: Sestiere?
    var searchText: String = ""
    var selectedCivico: Civico?

    // Zone normali
    var selectedZona: ZonaNormale?
    var selectedStreet: String?
    var streetSearchText: String = ""

    private let dataLoader = DataLoader.shared

    // MARK: - Sestiere (numerazione progressiva)

    var filteredNumbers: [String] {
        guard let sestiere = selectedSestiere else { return [] }
        let all = dataLoader.numbers(for: sestiere)

        if searchText.isEmpty {
            return all
        }

        return all.filter { $0.hasPrefix(searchText) }
    }

    var displayedNumbers: [String] {
        Array(filteredNumbers.prefix(50))
    }

    var hasMoreResults: Bool {
        filteredNumbers.count > 50
    }

    var totalCount: Int {
        guard let sestiere = selectedSestiere else { return 0 }
        return dataLoader.totalCount(for: sestiere)
    }

    var resultCount: Int {
        filteredNumbers.count
    }

    func selectSestiere(_ sestiere: Sestiere) {
        selectedSestiere = sestiere
        searchText = ""
        selectedCivico = nil
    }

    func selectNumber(_ number: String) {
        guard let sestiere = selectedSestiere else { return }
        selectedCivico = dataLoader.civico(for: sestiere, number: number)
    }

    // MARK: - Zone normali (toponimo/civico)

    var streets: [String] {
        guard let zona = selectedZona else { return [] }
        let all = dataLoader.streets(for: zona)
        if streetSearchText.isEmpty { return all }
        return all.filter { $0.localizedCaseInsensitiveContains(streetSearchText) }
    }

    var streetNumbers: [String] {
        guard let zona = selectedZona, let street = selectedStreet else { return [] }
        return dataLoader.numbers(for: zona, street: street)
    }

    func selectZona(_ zona: ZonaNormale) {
        selectedZona = zona
        selectedStreet = nil
        streetSearchText = ""
        selectedCivico = nil
    }

    func selectStreet(_ street: String) {
        selectedStreet = street
        selectedCivico = nil
    }

    func selectZonaNumber(_ number: String) {
        guard let zona = selectedZona, let street = selectedStreet else { return }
        selectedCivico = dataLoader.civico(for: zona, street: street, number: number)
    }

    // MARK: - Common

    func reset() {
        selectedSestiere = nil
        selectedZona = nil
        selectedStreet = nil
        searchText = ""
        streetSearchText = ""
        selectedCivico = nil
    }

    func clearSearch() {
        searchText = ""
        streetSearchText = ""
        selectedCivico = nil
    }
}
