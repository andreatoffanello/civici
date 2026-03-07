import SwiftUI

struct ContentView: View {
    @Environment(\.strings) private var strings
    @Environment(WaterBusViewModel.self) private var waterBusVM
    @State private var selectedTab: AppTab = .home
    @State private var waterBusPath = NavigationPath()

    private var tabTintColor: Color {
        switch selectedTab {
        case .home, .search: Color.doVeAccent
        case .waterBus: Color.doVeNavigation
        case .services: Color.doVeServices
        }
    }

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
                NavigationStack(path: $waterBusPath) {
                    WaterBusListView()
                }
            }

            Tab(strings.tabServices, systemImage: "cross.case.fill", value: .services) {
                NavigationStack {
                    ServicesView()
                }
            }
        }
        .tint(tabTintColor)
        .onOpenURL { url in
            handleDeepLink(url)
        }
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "dove" else { return }
        let host = url.host() ?? ""
        let pathParts = url.pathComponents.filter { $0 != "/" }

        switch host {
        case "tab":
            if let tabName = pathParts.first {
                switch tabName {
                case "home": selectedTab = .home
                case "search": selectedTab = .search
                case "waterBus", "vaporetti":
                    selectedTab = .waterBus
                    waterBusPath = NavigationPath()
                case "services", "servizi": selectedTab = .services
                default: break
                }
            }
        case "stop":
            if let stopId = pathParts.first {
                waterBusVM.loadData()
                if let stop = waterBusVM.stops.first(where: { $0.id == stopId }) {
                    selectedTab = .waterBus
                    waterBusPath = NavigationPath()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        waterBusPath.append(stop)
                    }
                }
            }
        case "line":
            if let lineId = pathParts.first {
                waterBusVM.loadData()
                if let route = waterBusVM.routes.first(where: { $0.id == lineId || $0.name == lineId }) {
                    selectedTab = .waterBus
                    waterBusPath = NavigationPath()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        waterBusPath.append(route)
                    }
                }
            }
        case "back":
            if !waterBusPath.isEmpty {
                waterBusPath.removeLast()
            }
        case "view":
            // dove://view/map, dove://view/list, dove://view/lines, dove://view/stops
            selectedTab = .waterBus
            if !waterBusPath.isEmpty { waterBusPath = NavigationPath() }
            for part in pathParts {
                switch part {
                case "map", "list":
                    waterBusVM.deepLinkViewMode = part
                case "stops", "lines":
                    waterBusVM.deepLinkContentMode = part
                default: break
                }
            }
        default:
            break
        }
    }
}

enum AppTab: Hashable {
    case home
    case search
    case waterBus
    case services
}
