import SwiftUI
import PhosphorSwift

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
            NavigationStack {
                HomeHubView(selectedTab: $selectedTab)
            }
            .tabItem {
                PhIcon(.house)
                Text(strings.tabHome)
            }
            .tag(AppTab.home)

            NavigationStack {
                SearchFlowView()
            }
            .tabItem {
                PhIcon(.magnifyingGlass)
                Text(strings.tabSearch)
            }
            .tag(AppTab.search)

            NavigationStack(path: $waterBusPath) {
                WaterBusListView()
            }
            .tabItem {
                PhIcon(.boat)
                Text(strings.waterBusTitle)
            }
            .tag(AppTab.waterBus)

            NavigationStack {
                ServicesView()
            }
            .tabItem {
                PhIcon(.firstAidKit)
                Text(strings.tabServices)
            }
            .tag(AppTab.services)
        }
        .tabViewStyle(.tabBarOnly)
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

/// Renders a Phosphor duotone icon as a fixed-size template UIImage suitable for tab bars
struct PhIcon: View {
    let uiImage: UIImage?

    init(_ icon: Ph) {
        let renderer = ImageRenderer(content:
            icon.duotone
                .frame(width: 25, height: 25)
        )
        renderer.scale = 3
        self.uiImage = renderer.uiImage
    }

    var body: some View {
        if let uiImage {
            Image(uiImage: uiImage)
                .renderingMode(.template)
        }
    }
}
