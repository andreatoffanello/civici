import SwiftUI
import CoreLocation
import UserNotifications

enum PreferredNavApp: String, CaseIterable, Identifiable {
    case appleMaps = "apple"
    case googleMaps = "google"
    case waze = "waze"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .appleMaps: "Apple Maps"
        case .googleMaps: "Google Maps"
        case .waze: "Waze"
        }
    }

    var iconName: String {
        switch self {
        case .appleMaps: "map"
        case .googleMaps: "globe"
        case .waze: "car"
        }
    }
}

enum DefaultMapView: String, CaseIterable, Identifiable {
    case threeD = "3d"
    case twoD = "2d"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .threeD: "3D"
        case .twoD: "2D"
        }
    }
}

enum AppLanguage: String, CaseIterable, Identifiable {
    case italian = "it"
    case english = "en"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .italian: "Italiano"
        case .english: "English"
        }
    }

    var flag: String {
        switch self {
        case .italian: "🇮🇹"
        case .english: "🇬🇧"
        }
    }
}

struct SettingsView: View {
    @Environment(LocationManager.self) private var locationManager
    @Environment(NotificationManager.self) private var notificationManager

    @AppStorage("preferredNavApp") private var preferredNavApp: String = PreferredNavApp.appleMaps.rawValue
    @AppStorage("defaultMapView") private var defaultMapView: String = DefaultMapView.threeD.rawValue
    @AppStorage("appLanguage") private var appLanguage: String = AppLanguage.italian.rawValue

    var body: some View {
        List {
            // Map section
            Section {
                Picker(selection: $defaultMapView) {
                    ForEach(DefaultMapView.allCases) { option in
                        Text(option.displayName).tag(option.rawValue)
                    }
                } label: {
                    Label("Vista mappa", systemImage: "cube")
                }

                Picker(selection: $preferredNavApp) {
                    ForEach(PreferredNavApp.allCases) { app in
                        Label(app.displayName, systemImage: app.iconName)
                            .tag(app.rawValue)
                    }
                } label: {
                    Label("App navigazione", systemImage: "arrow.triangle.turn.up.right.diamond")
                }
            } header: {
                Text("Mappa")
            } footer: {
                Text("L'app di navigazione verrà usata quando premi \"Naviga\". Se l'app scelta non è installata, si aprirà Apple Maps.")
            }

            // Language section
            Section {
                Picker(selection: $appLanguage) {
                    ForEach(AppLanguage.allCases) { lang in
                        Text("\(lang.flag) \(lang.displayName)").tag(lang.rawValue)
                    }
                } label: {
                    Label("Lingua", systemImage: "globe")
                }
            } header: {
                Text("Lingua")
            } footer: {
                Text("Al momento l'app è disponibile solo in italiano. Altre lingue saranno aggiunte in futuro.")
            }

            // Permissions section
            Section {
                HStack {
                    Label("Posizione", systemImage: "location")
                    Spacer()
                    permissionBadge(for: locationManager.authorizationStatus)
                }

                HStack {
                    Label("Notifiche", systemImage: "bell")
                    Spacer()
                    permissionBadge(forNotification: notificationManager.authorizationStatus)
                }
            } header: {
                Text("Permessi")
            } footer: {
                Text("Puoi gestire i permessi nelle Impostazioni di sistema.")
            }

            // About section
            Section {
                HStack {
                    Text("Versione")
                    Spacer()
                    Text("1.0")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Info")
            }
        }
        .navigationTitle("Impostazioni")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await notificationManager.refreshStatus()
        }
    }

    @ViewBuilder
    private func permissionBadge(for status: CLAuthorizationStatus) -> some View {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            Text("Concesso")
                .font(.caption)
                .foregroundStyle(.green)
        case .denied, .restricted:
            Text("Negato")
                .font(.caption)
                .foregroundStyle(.red)
        case .notDetermined:
            Text("Non richiesto")
                .font(.caption)
                .foregroundStyle(.secondary)
        @unknown default:
            Text("Sconosciuto")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func permissionBadge(forNotification status: UNAuthorizationStatus) -> some View {
        switch status {
        case .authorized, .provisional:
            Text("Concesso")
                .font(.caption)
                .foregroundStyle(.green)
        case .denied:
            Text("Negato")
                .font(.caption)
                .foregroundStyle(.red)
        case .notDetermined:
            Text("Non richiesto")
                .font(.caption)
                .foregroundStyle(.secondary)
        @unknown default:
            Text("Sconosciuto")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
