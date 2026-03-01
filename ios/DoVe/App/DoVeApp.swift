import SwiftUI

@main
struct DoVeApp: App {
    @State private var searchViewModel = SearchViewModel()
    @State private var locationManager = LocationManager()
    @State private var notificationManager = NotificationManager()
    @AppStorage("appColorScheme") private var appColorScheme: String = AppColorScheme.light.rawValue
    @AppStorage("appLanguage") private var appLanguage: String = AppLanguage.italian.rawValue
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environment(searchViewModel)
                    .environment(locationManager)
                    .environment(notificationManager)
                    .environment(\.strings, L10n.strings(for: appLanguage))
                    .preferredColorScheme(AppColorScheme(rawValue: appColorScheme)?.colorScheme)
                    .onAppear {
                        locationManager.requestPermission()
                    }

                if showSplash {
                    SplashScreenView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .animation(.easeOut(duration: 0.45), value: showSplash)
            .task {
                try? await Task.sleep(for: .seconds(1.6))
                showSplash = false
            }
        }
    }
}
