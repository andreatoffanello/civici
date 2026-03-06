import SwiftUI

struct ContentView: View {
    @Environment(SearchViewModel.self) private var viewModel
    @Environment(\.strings) private var strings

    var body: some View {
        TabView {
            Tab(strings.tabSearch, systemImage: "magnifyingglass") {
                NavigationStack {
                    SearchFlowView()
                }
            }

            Tab(strings.waterBusTitle, systemImage: "ferry") {
                NavigationStack {
                    WaterBusListView()
                }
            }

            Tab(strings.tabServices, systemImage: "building.2.crop.circle") {
                NavigationStack {
                    ServicesView()
                }
            }

            Tab(strings.tabInfo, systemImage: "info.circle") {
                NavigationStack {
                    InfoView()
                }
            }

            Tab(strings.tabSettings, systemImage: "gearshape") {
                NavigationStack {
                    SettingsView()
                }
            }
        }
        .tint(Color.doVeAccent)
    }
}
