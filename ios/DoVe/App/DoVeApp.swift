import SwiftUI

@main
struct DoVeApp: App {
    @State private var searchViewModel = SearchViewModel()
    @State private var locationManager = LocationManager()
    @State private var notificationManager = NotificationManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(searchViewModel)
                .environment(locationManager)
                .environment(notificationManager)
                .onAppear {
                    locationManager.requestPermission()
                }
        }
    }
}
