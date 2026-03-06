import SwiftUI
import MapKit
import CoreLocation

// MARK: - Main View with Map/List Toggle

struct WaterBusListView: View {
    @Environment(WaterBusViewModel.self) private var vm
    @Environment(LocationManager.self) private var locationManager
    @Environment(\.strings) private var strings
    @State private var viewMode: ViewMode = .map
    @State private var contentMode: ContentMode = .stops
    @State private var appeared = false

    enum ViewMode: String {
        case map, list
    }

    enum ContentMode: String {
        case stops, lines
    }

    var body: some View {
        @Bindable var vm = vm
        let sorted = vm.stopsSortedByDistance(from: locationManager.userLocation)

        ZStack(alignment: .top) {
            switch contentMode {
            case .stops:
                switch viewMode {
                case .map:
                    WaterBusMapView(
                        stops: vm.filteredStops,
                        vm: vm,
                        userLocation: locationManager.userLocation,
                        locationManager: locationManager
                    )
                    .ignoresSafeArea(edges: .bottom)
                case .list:
                    WaterBusListContent(
                        stops: sorted,
                        vm: vm,
                        appeared: appeared,
                        locationManager: locationManager
                    )
                }
            case .lines:
                WaterBusLinesContent(
                    routes: vm.filteredRoutes,
                    vm: vm,
                    appeared: appeared,
                    strings: strings
                )
            }

            // Top overlay: segmented + search + toggle
            VStack(spacing: 8) {
                // Segmented control: Fermate / Linee
                Picker("", selection: $contentMode) {
                    Text(strings.waterBusStops).tag(ContentMode.stops)
                    Text(strings.waterBusLines).tag(ContentMode.lines)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.top, 10)

                HStack(spacing: 10) {
                    // Search field
                    HStack(spacing: 6) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                        TextField(strings.waterBusSearchPlaceholder, text: $vm.searchText)
                            .font(.system(size: 15))
                            .autocorrectionDisabled()
                        if !vm.searchText.isEmpty {
                            Button {
                                vm.searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                    // Toggle map/list (only for stops mode)
                    if contentMode == .stops {
                        HStack(spacing: 0) {
                            toggleButton(icon: "map.fill", mode: .map)
                            toggleButton(icon: "list.bullet", mode: .list)
                        }
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 10)
            }
            .background(.regularMaterial)
        }
        .navigationTitle(strings.waterBusTitle)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: WaterBusStop.self) { stop in
            WaterBusStopDetailView(stop: stop)
        }
        .navigationDestination(for: WaterBusRoute.self) { route in
            WaterBusLineDetailView(route: route)
        }
        .onAppear {
            vm.loadData()
            locationManager.requestPermission()
            locationManager.startUpdating()
            withAnimation(.easeIn(duration: 0.3).delay(0.15)) { appeared = true }
        }
    }

    private func toggleButton(icon: String, mode: ViewMode) -> some View {
        Button {
            withAnimation(.smooth(duration: 0.2)) { viewMode = mode }
        } label: {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(viewMode == mode ? .white : .secondary)
                .frame(width: 32, height: 28)
                .background(viewMode == mode ? Color.doVeNavigation : .clear)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .padding(2)
    }
}

// MARK: - Map View

private struct WaterBusMapView: View {
    let stops: [WaterBusStop]
    let vm: WaterBusViewModel
    let userLocation: CLLocation?
    let locationManager: LocationManager
    private static let veniceCenter = CLLocationCoordinate2D(latitude: 45.4375, longitude: 12.3358)

    @State private var mapPosition: MapCameraPosition = .region(MKCoordinateRegion(
        center: veniceCenter,
        span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)
    ))
    @State private var selectedStop: WaterBusStop?

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(position: $mapPosition) {
                if let userLocation {
                    Annotation("", coordinate: userLocation.coordinate) {
                        Circle()
                            .fill(.blue)
                            .frame(width: 12, height: 12)
                            .overlay(Circle().stroke(.white, lineWidth: 2))
                    }
                }

                ForEach(stops) { stop in
                    Annotation(stop.name, coordinate: stop.coordinate) {
                        WaterBusMapPin(
                            stop: stop,
                            isSelected: selectedStop?.id == stop.id,
                            vm: vm
                        )
                        .onTapGesture {
                            withAnimation(.spring(duration: 0.25)) {
                                selectedStop = stop
                            }
                        }
                    }
                }
            }
            .mapStyle(.standard(pointsOfInterest: .excludingAll))
            .onAppear {
                let veniceLocation = CLLocation(latitude: Self.veniceCenter.latitude, longitude: Self.veniceCenter.longitude)
                if let userLocation, userLocation.distance(from: veniceLocation) < 20_000 {
                    mapPosition = .region(MKCoordinateRegion(
                        center: userLocation.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                    ))
                } else {
                    mapPosition = .region(MKCoordinateRegion(
                        center: Self.veniceCenter,
                        span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)
                    ))
                }
            }

            // Bottom card for selected stop
            if let stop = selectedStop {
                WaterBusMapCard(stop: stop, vm: vm, locationManager: locationManager)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.horizontal, 16)
                    .padding(.bottom, 90)
            }

            // Center on user button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        if let loc = userLocation {
                            withAnimation {
                                mapPosition = .region(MKCoordinateRegion(
                                    center: loc.coordinate,
                                    span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
                                ))
                            }
                        }
                    } label: {
                        Image(systemName: "location.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.primary)
                            .frame(width: 40, height: 40)
                            .background(.regularMaterial)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                    }
                    .padding(.trailing, 16)
                    .padding(.bottom, selectedStop != nil ? 200 : 16)
                }
            }
        }
    }
}

// MARK: - Map Pin

private struct WaterBusMapPin: View {
    let stop: WaterBusStop
    let isSelected: Bool
    let vm: WaterBusViewModel

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(pinColor)
                    .frame(width: isSelected ? 32 : 24, height: isSelected ? 32 : 24)
                Image(systemName: "ferry.fill")
                    .font(.system(size: isSelected ? 14 : 10))
                    .foregroundStyle(.white)
            }
            // Pin point
            PinPointer()
                .fill(pinColor)
                .frame(width: 10, height: 6)
        }
        .animation(.spring(duration: 0.2), value: isSelected)
    }

    private var pinColor: Color {
        Color.doVeNavigation
    }
}

// MARK: - Pin Pointer Shape

private struct PinPointer: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.midX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            p.closeSubpath()
        }
    }
}

// MARK: - Map Card

private struct WaterBusMapCard: View {
    let stop: WaterBusStop
    let vm: WaterBusViewModel
    let locationManager: LocationManager
    @Environment(\.strings) private var strings

    var body: some View {
        NavigationLink(value: stop) {
            VStack(alignment: .leading, spacing: 8) {
                // Drag indicator
                Capsule()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(width: 36, height: 4)
                    .frame(maxWidth: .infinity)

                // Name + distance
                HStack {
                    Image(systemName: "ferry.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.doVeNavigation)

                    Text(stop.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)

                    Spacer()

                    if let dist = locationManager.formattedDistance(to: stop.coordinate) {
                        Text(dist)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                }

                // Lines badges
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(stop.lines, id: \.self) { line in
                            LineBadge(line: line, vm: vm, size: .small)
                        }
                    }
                }

                // Next departures
                let next = vm.nextDepartures(for: stop, count: 3)
                if !next.isEmpty {
                    HStack(spacing: 12) {
                        ForEach(next) { dep in
                            HStack(spacing: 4) {
                                LineBadge(line: dep.line, vm: vm, size: .tiny)
                                Text(dep.time)
                                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                                    .foregroundStyle(.primary)
                            }
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .padding(14)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - List Content

private struct WaterBusListContent: View {
    let stops: [WaterBusStop]
    let vm: WaterBusViewModel
    let appeared: Bool
    let locationManager: LocationManager
    @Environment(\.strings) private var strings

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Spacer for top bar
                Color.clear.frame(height: 56)

                if stops.isEmpty {
                    Text(strings.waterBusNoResults)
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                        .padding(.top, 40)
                } else {
                    ForEach(Array(stops.enumerated()), id: \.element.id) { index, stop in
                        NavigationLink(value: stop) {
                            WaterBusStopRow(stop: stop, vm: vm, locationManager: locationManager)
                        }
                        .buttonStyle(.plain)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 10)
                        .animation(.spring(duration: 0.35).delay(Double(index) * 0.02), value: appeared)

                        if index < stops.count - 1 {
                            Divider().padding(.leading, 52)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Stop Row

private struct WaterBusStopRow: View {
    let stop: WaterBusStop
    let vm: WaterBusViewModel
    let locationManager: LocationManager

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.doVeNavigation.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: "ferry.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.doVeNavigation)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(stop.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                // Line badges
                HStack(spacing: 3) {
                    ForEach(stop.lines.prefix(8), id: \.self) { line in
                        LineBadge(line: line, vm: vm, size: .tiny)
                    }
                    if stop.lines.count > 8 {
                        Text("+\(stop.lines.count - 8)")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                }

                // Next departure
                let next = vm.nextDepartures(for: stop, count: 1)
                if let dep = next.first {
                    let mins = dep.minutesUntil()
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 10))
                        if mins <= 1 {
                            Text("In partenza")
                                .foregroundStyle(Color(hex: "38A169"))
                        } else {
                            Text("\(dep.time) (\(mins) min)")
                        }
                    }
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Distance
            if let dist = locationManager.formattedDistance(to: stop.coordinate) {
                Text(dist)
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundStyle(.quaternary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

// MARK: - Line Badge

struct LineBadge: View {
    let line: String
    let vm: WaterBusViewModel
    let size: BadgeSize

    enum BadgeSize {
        case tiny, small, medium

        var fontSize: CGFloat {
            switch self {
            case .tiny: 9
            case .small: 11
            case .medium: 13
            }
        }

        var padding: EdgeInsets {
            switch self {
            case .tiny: EdgeInsets(top: 2, leading: 4, bottom: 2, trailing: 4)
            case .small: EdgeInsets(top: 3, leading: 6, bottom: 3, trailing: 6)
            case .medium: EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
            }
        }

        var cornerRadius: CGFloat {
            switch self {
            case .tiny: 3
            case .small: 4
            case .medium: 6
            }
        }
    }

    private var isWhiteRoute: Bool {
        guard let route = vm.route(for: line) else { return false }
        return route.color == Color(hex: "FFFFFF")
    }

    var body: some View {
        let route = vm.route(for: line)
        let bgColor = route?.color ?? .gray
        let fgColor = route?.textColor ?? .white

        Text(line)
            .font(.system(size: size.fontSize, weight: .bold, design: .rounded))
            .foregroundStyle(isWhiteRoute ? .primary : fgColor)
            .padding(size.padding)
            .background(isWhiteRoute ? Color(.systemBackground) : bgColor)
            .clipShape(RoundedRectangle(cornerRadius: size.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: size.cornerRadius)
                    .strokeBorder(isWhiteRoute ? Color.primary.opacity(0.6) : .clear, lineWidth: 1)
            )
    }
}

// MARK: - Lines Content

private struct WaterBusLinesContent: View {
    let routes: [WaterBusRoute]
    let vm: WaterBusViewModel
    let appeared: Bool
    let strings: L10n.Strings

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Spacer for top bar (segmented + search)
                Color.clear.frame(height: 100)

                if routes.isEmpty {
                    Text(strings.waterBusNoLines)
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                        .padding(.top, 40)
                } else {
                    ForEach(Array(routes.enumerated()), id: \.element.id) { index, route in
                        NavigationLink(value: route) {
                            WaterBusRouteRow(route: route, vm: vm)
                        }
                        .buttonStyle(.plain)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 10)
                        .animation(.spring(duration: 0.35).delay(Double(index) * 0.02), value: appeared)

                        if index < routes.count - 1 {
                            Divider().padding(.leading, 60)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Route Row

private struct WaterBusRouteRow: View {
    let route: WaterBusRoute
    let vm: WaterBusViewModel

    var body: some View {
        HStack(spacing: 12) {
            // Line badge
            LineBadge(line: route.name, vm: vm, size: .medium)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 3) {
                Text(route.longName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    if let dir = route.directions.first {
                        Text(dir.headsign)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Text(route.source.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundStyle(.quaternary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}
