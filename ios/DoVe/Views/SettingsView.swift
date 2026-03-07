import SwiftUI
import CoreLocation
import UserNotifications
import PhosphorSwift

enum PreferredNavApp: String, CaseIterable, Identifiable {
    case alwaysAsk = "ask"
    case appleMaps = "apple"
    case googleMaps = "google"
    case waze = "waze"

    var id: String { rawValue }

    func displayName(strings: L10n.Strings) -> String {
        switch self {
        case .alwaysAsk: strings.alwaysAsk
        case .appleMaps: "Apple Maps"
        case .googleMaps: "Google Maps"
        case .waze: "Waze"
        }
    }

    var iconName: String {
        switch self {
        case .alwaysAsk: "questionmark.circle"
        case .appleMaps: "map"
        case .googleMaps: "globe"
        case .waze: "car"
        }
    }
}

enum AppColorScheme: String, CaseIterable, Identifiable {
    case light = "light"
    case dark = "dark"
    case system = "system"

    var id: String { rawValue }

    func displayName(strings: L10n.Strings) -> String {
        switch self {
        case .light: strings.themeLight
        case .dark: strings.themeDark
        case .system: strings.themeSystem
        }
    }

    var iconName: String {
        switch self {
        case .light: "sun.max"
        case .dark: "moon"
        case .system: "circle.lefthalf.filled"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .light: .light
        case .dark: .dark
        case .system: nil
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
    @Environment(\.strings) private var strings

    @AppStorage("preferredNavApp") private var preferredNavApp: String = PreferredNavApp.appleMaps.rawValue
    @AppStorage("defaultMapView") private var defaultMapView: String = DefaultMapView.threeD.rawValue
    @AppStorage("appLanguage") private var appLanguage: String = AppLanguage.italian.rawValue
    @AppStorage("appColorScheme") private var appColorScheme: String = AppColorScheme.light.rawValue

    var body: some View {
        List {
            // Appearance section
            Section {
                Picker(selection: $appColorScheme) {
                    ForEach(AppColorScheme.allCases) { scheme in
                        Text(scheme.displayName(strings: strings)).tag(scheme.rawValue)
                    }
                } label: {
                    PhLabel(strings.theme, icon: .palette)
                }
            } header: {
                Text(strings.sectionAppearance)
            }

            // Map section
            Section {
                Picker(selection: $defaultMapView) {
                    ForEach(DefaultMapView.allCases) { option in
                        Text(option.displayName).tag(option.rawValue)
                    }
                } label: {
                    PhLabel(strings.mapView, icon: .cube)
                }

                Picker(selection: $preferredNavApp) {
                    ForEach(PreferredNavApp.allCases) { app in
                        Text(app.displayName(strings: strings)).tag(app.rawValue)
                    }
                } label: {
                    PhLabel(strings.navigationLabel, icon: .navigationArrow)
                }
            } header: {
                Text(strings.sectionMap)
            } footer: {
                Text(strings.navFooter)
            }

            // Language section
            Section {
                Picker(selection: $appLanguage) {
                    ForEach(AppLanguage.allCases) { lang in
                        Text("\(lang.flag) \(lang.displayName)").tag(lang.rawValue)
                    }
                } label: {
                    PhLabel(strings.languageLabel, icon: .globeHemisphereEast)
                }
            } header: {
                Text(strings.sectionLanguage)
            } footer: {
                Text(strings.languageFooter)
            }

            // Permissions section
            Section {
                HStack {
                    PhLabel(strings.locationLabel, icon: .mapPin)
                    Spacer()
                    permissionBadge(for: locationManager.authorizationStatus)
                }

                HStack {
                    PhLabel(strings.notificationsLabel, icon: .bell)
                    Spacer()
                    permissionBadge(forNotification: notificationManager.authorizationStatus)
                }
            } header: {
                Text(strings.sectionPermissions)
            } footer: {
                Text(strings.permissionsFooter)
            }

            // About section
            Section {
                HStack {
                    Text(strings.versionLabel)
                    Spacer()
                    Text("1.0")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text(strings.sectionAbout)
            }
        }
        .navigationTitle(strings.settingsNavTitle)
        .navigationBarTitleDisplayMode(.large)
        .toolbar(.hidden, for: .tabBar)
        .task {
            await notificationManager.refreshStatus()
        }
    }

    @ViewBuilder
    private func permissionBadge(for status: CLAuthorizationStatus) -> some View {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            Text(strings.permissionGranted)
                .font(.caption)
                .foregroundStyle(.green)
        case .denied, .restricted:
            Text(strings.permissionDenied)
                .font(.caption)
                .foregroundStyle(.red)
        case .notDetermined:
            Text(strings.permissionNotRequested)
                .font(.caption)
                .foregroundStyle(.secondary)
        @unknown default:
            Text(strings.permissionUnknown)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func permissionBadge(forNotification status: UNAuthorizationStatus) -> some View {
        switch status {
        case .authorized, .provisional:
            Text(strings.permissionGranted)
                .font(.caption)
                .foregroundStyle(.green)
        case .denied:
            Text(strings.permissionDenied)
                .font(.caption)
                .foregroundStyle(.red)
        case .notDetermined:
            Text(strings.permissionNotRequested)
                .font(.caption)
                .foregroundStyle(.secondary)
        @unknown default:
            Text(strings.permissionUnknown)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

/// Label with Phosphor duotone icon for settings rows
private struct PhLabel: View {
    let text: String
    let icon: Ph

    init(_ text: String, icon: Ph) {
        self.text = text
        self.icon = icon
    }

    var body: some View {
        Label {
            Text(text)
        } icon: {
            icon.duotone
                .renderingMode(.template)
                .frame(width: 18, height: 18)
        }
    }
}
