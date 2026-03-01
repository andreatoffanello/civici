import SwiftUI

struct ContentView: View {
    @Environment(SearchViewModel.self) private var viewModel

    var body: some View {
        TabView {
            Tab("Cerca", systemImage: "magnifyingglass") {
                NavigationStack {
                    SearchFlowView()
                }
            }

            Tab("Info", systemImage: "info.circle") {
                NavigationStack {
                    InfoView()
                }
            }

            Tab("Impostazioni", systemImage: "gearshape") {
                NavigationStack {
                    SettingsView()
                }
            }
        }
        .tint(Color(hex: "C2452D"))
    }
}
