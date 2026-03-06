import SwiftUI
import MapKit
import CoreLocation

// MARK: - Main View with Map/List Toggle

struct WaterBusListView: View {
    @Environment(WaterBusViewModel.self) private var vm
    @Environment(LocationManager.self) private var locationManager
    @Environment(\.strings) private var strings
    @State private var viewMode: ViewMode = .map
    @State private var appeared = false

    enum ViewMode: String {
        case map, list
    }

    var body: some View {
        @Bindable var vm = vm
        let sorted = vm.stopsSortedByDistance(from: locationManager.userLocation)

        ZStack(alignment: .top) {
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

            // Top overlay: search + toggle
            VStack(spacing: 0) {
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

                    // Toggle map/list
                    HStack(spacing: 0) {
                        toggleButton(icon: "map.fill", mode: .map)
                        toggleButton(icon: "list.bullet", mode: .list)
                    }
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.regularMaterial)
            }
        }
        .navigationTitle(strings.waterBusTitle)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: WaterBusStop.self) { stop in
            WaterBusStopDetailView(stop: stop)
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
                .background(viewMode == mode ? Color.doVeAccent : .clear)
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
    @State private var mapPosition: MapCameraPosition = .automatic
    @State private var selectedStop: WaterBusStop?

    private static let veniceCenter = CLLocationCoordinate2D(latitude: 45.4375, longitude: 12.3358)

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
                if let userLocation {
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
                    .padding(.bottom, 16)
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
                    .padding(.bottom, selectedStop != nil ? 130 : 16)
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
        // Use the color of the main line serving this stop
        if let firstLine = stop.lines.first,
           let route = vm.route(for: firstLine) {
            return route.color == Color(hex: "FFFFFF") ? .blue : route.color
        }
        return .blue
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
                        .foregroundStyle(.blue)

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
                    .fill(.blue.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: "ferry.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.blue)
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

    var body: some View {
        let route = vm.route(for: line)
        let bgColor = route.map { $0.color == Color(hex: "FFFFFF") ? .blue : $0.color } ?? .blue
        let fgColor = route?.textColor ?? .white

        Text(line)
            .font(.system(size: size.fontSize, weight: .bold, design: .rounded))
            .foregroundStyle(fgColor)
            .padding(size.padding)
            .background(bgColor)
            .clipShape(RoundedRectangle(cornerRadius: size.cornerRadius))
    }
}
