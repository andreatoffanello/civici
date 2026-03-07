import SwiftUI
import MapKit
import PhosphorSwift

struct WaterBusLineDetailView: View {
    let route: WaterBusRoute
    @Environment(WaterBusViewModel.self) private var vm
    @Environment(LocationManager.self) private var locationManager
    @Environment(\.strings) private var strings
    @State private var selectedDirection: Int = 0
    @State private var mapPosition: MapCameraPosition = .automatic
    private static let peekDetent = PresentationDetent.height(130)
    @State private var sheetDetent: PresentationDetent = .medium
    @State private var showSheet = false

    var body: some View {
        let direction = route.directions.first { $0.id == selectedDirection }
        let stops = vm.stopsForRoute(route, direction: selectedDirection)

        routeMap(direction: direction, stops: stops)
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: sheetDetent == .large ? 0 : sheetDetent == .medium ? UIScreen.main.bounds.height * 0.5 : 130)
            }
            .ignoresSafeArea(edges: .bottom)
            .navigationTitle(route.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .tabBar)
            .onAppear {
                centerMapOnRoute(direction: direction)
                showSheet = true
            }
            .onChange(of: selectedDirection) { _, newDir in
                let dir = route.directions.first { $0.id == newDir }
                centerMapOnRoute(direction: dir)
            }
            .sheet(isPresented: $showSheet) {
                sheetContent(direction: direction, stops: stops)
                    .presentationDetents([Self.peekDetent, .medium, .large], selection: $sheetDetent)
                    .presentationDragIndicator(.visible)
                    .presentationBackgroundInteraction(.enabled(upThrough: .medium))
                    .presentationCornerRadius(20)
                    .interactiveDismissDisabled()
            }
    }

    // MARK: - Sheet Content

    @State private var navigateToStop: WaterBusStop?

    private func sheetContent(direction: RouteDirection?, stops: [WaterBusStop]) -> some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // MARK: Peek header (static route info + picker)
                    peekHeader(stopsCount: stops.count)

                    // Direction picker
                    if route.directions.count > 1 {
                        directionPicker
                            .padding(.horizontal, 20)
                            .padding(.bottom, 12)
                    }

                    // Headsign for single-direction routes (no picker shown)
                    if route.directions.count <= 1, let direction {
                        let parsed = parseDock(from: direction.headsign)
                        HStack(spacing: 5) {
                            Ph.arrowRight.bold
                                .renderingMode(.template)
                                .frame(width: 11, height: 11)
                                .foregroundColor(Color(.secondaryLabel))
                            Text(parsed.name)
                                .font(.system(size: 15, weight: .semibold))
                                .lineLimit(1)
                            if let dock = parsed.dock {
                                DockBadge(letter: dock, size: .medium)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)
                    }

                    // Stops list
                    if !stops.isEmpty {
                        stopsSection(stops: stops)
                    }

                    Color.clear.frame(height: 40)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationDestination(item: $navigateToStop) { stop in
                WaterBusStopDetailView(stop: stop)
            }
        }
    }

    // MARK: - Peek Header

    private func peekHeader(stopsCount: Int) -> some View {
        HStack(spacing: 12) {
            LineBadge(line: route.name, vm: vm, size: .medium)

            VStack(alignment: .leading, spacing: 3) {
                routeNameView
                    .font(.system(size: 16, weight: .semibold))

                HStack(spacing: 6) {
                    Text(strings.waterBusStopsCount(stopsCount))
                        .font(.system(size: 12))
                        .foregroundColor(Color(.secondaryLabel))

                    Text("·")
                        .foregroundColor(Color(.secondaryLabel))
                        .font(.system(size: 12))

                    Image(route.source == "actv" ? "logo-actv" : "logo-alilaguna")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 12)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 12)
    }

    // MARK: - Map

    @ViewBuilder
    private func routeMap(direction: RouteDirection?, stops: [WaterBusStop]) -> some View {
        Map(position: $mapPosition, interactionModes: [.pan, .zoom, .rotate]) {
            if let direction, !direction.coordinates.isEmpty {
                MapPolyline(coordinates: direction.coordinates)
                    .stroke(route.color == Color(hex: "FFFFFF") ? .blue : route.color, lineWidth: 4)
            }

            ForEach(stops) { stop in
                Annotation("", coordinate: stop.coordinate) {
                    stopPin
                }
            }

            if let location = locationManager.userLocation {
                Annotation("", coordinate: location.coordinate) {
                    Circle()
                        .fill(.blue)
                        .frame(width: 12, height: 12)
                        .overlay(Circle().stroke(.white, lineWidth: 2))
                        .shadow(color: .blue.opacity(0.3), radius: 4)
                }
            }
        }
        .mapStyle(.standard(pointsOfInterest: .excludingAll))
    }

    private var stopPin: some View {
        let color = route.color == Color(hex: "FFFFFF") ? Color.blue : route.color
        return ZStack {
            Circle()
                .fill(.white)
                .frame(width: 14, height: 14)
                .shadow(color: .black.opacity(0.15), radius: 2, y: 1)
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
        }
    }

    // MARK: - Direction Picker

    private var directionPicker: some View {
        Picker("", selection: $selectedDirection) {
            ForEach(route.directions) { dir in
                Text(dir.headsign)
                    .lineLimit(1)
                    .tag(dir.id)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Stops Section

    @ViewBuilder
    private func stopsSection(stops: [WaterBusStop]) -> some View {
        let lineColor = route.color == Color(hex: "FFFFFF") ? Color.blue : route.color

        VStack(alignment: .leading, spacing: 0) {
            Divider()
                .padding(.horizontal, 20)
                .padding(.bottom, 4)

            ForEach(Array(stops.enumerated()), id: \.element.id) { index, stop in
                let isTerminal = index == 0 || index == stops.count - 1
                let dotSize: CGFloat = isTerminal ? 12 : 8

                Button {
                    navigateToStop = stop
                } label: {
                    HStack(spacing: 0) {
                        // Timeline column
                        ZStack {
                            // Continuous line
                            VStack(spacing: 0) {
                                Rectangle()
                                    .fill(index > 0 ? lineColor : .clear)
                                    .frame(width: 3)
                                Rectangle()
                                    .fill(index < stops.count - 1 ? lineColor : .clear)
                                    .frame(width: 3)
                            }

                            // Dot
                            Circle()
                                .fill(lineColor)
                                .frame(width: dotSize, height: dotSize)
                                .overlay(
                                    Circle()
                                        .fill(.white)
                                        .frame(width: isTerminal ? 5 : 0)
                                )
                        }
                        .frame(width: 20, height: 40)

                        // Stop info
                        VStack(alignment: .leading, spacing: 1) {
                            Text(stop.name)
                                .font(.system(size: 15, weight: isTerminal ? .semibold : .regular))
                                .foregroundStyle(.primary)
                                .lineLimit(1)

                            if let dist = locationManager.formattedDistance(to: stop.coordinate) {
                                Text(dist)
                                    .font(.system(size: 11))
                                    .foregroundColor(Color(.secondaryLabel))
                            }
                        }
                        .padding(.leading, 12)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color(.tertiaryLabel))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 2)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Route Name with Dock Badges

    @ViewBuilder
    private var routeNameView: some View {
        let parts = route.longName.components(separatedBy: " - ")
        if parts.count == 2 {
            let p1 = parseDock(from: parts[0])
            let p2 = parseDock(from: parts[1])
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(p1.name).lineLimit(1)
                    if let d = p1.dock { DockBadge(letter: d, size: .medium) }
                }
                HStack(spacing: 4) {
                    Text(p2.name).lineLimit(1)
                    if let d = p2.dock { DockBadge(letter: d, size: .medium) }
                }
            }
        } else {
            let parsed = parseDock(from: route.longName)
            HStack(spacing: 4) {
                Text(parsed.name).lineLimit(2)
                if let d = parsed.dock { DockBadge(letter: d, size: .medium) }
            }
        }
    }

    // MARK: - Helpers

    private func centerMapOnRoute(direction: RouteDirection?) {
        guard let direction, !direction.coordinates.isEmpty else { return }
        let lats = direction.coordinates.map(\.latitude)
        let lngs = direction.coordinates.map(\.longitude)
        guard let minLat = lats.min(), let maxLat = lats.max(),
              let minLng = lngs.min(), let maxLng = lngs.max() else { return }

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLng + maxLng) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: (maxLat - minLat) * 1.3 + 0.005,
            longitudeDelta: (maxLng - minLng) * 1.3 + 0.005
        )
        withAnimation(.easeInOut(duration: 0.4)) {
            mapPosition = .region(MKCoordinateRegion(center: center, span: span))
        }
    }
}
