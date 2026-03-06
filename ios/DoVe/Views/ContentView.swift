import SwiftUI

struct ContentView: View {
    @Environment(\.strings) private var strings
    @State private var selectedTab: AppTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(strings.tabHome, systemImage: "house.fill", value: .home) {
                NavigationStack {
                    HomeHubView(selectedTab: $selectedTab)
                }
            }

            Tab(strings.tabSearch, systemImage: "magnifyingglass", value: .search) {
                NavigationStack {
                    SearchFlowView()
                }
            }

            Tab(strings.waterBusTitle, systemImage: "ferry.fill", value: .waterBus) {
                NavigationStack {
                    WaterBusListView()
                }
            }

            Tab(strings.tabServices, systemImage: "cross.case.fill", value: .services) {
                NavigationStack {
                    ServicesView()
                }
            }
        }
        .tint(Color.doVeAccent)
    }
}

enum AppTab: Hashable {
    case home
    case search
    case waterBus
    case services
}
