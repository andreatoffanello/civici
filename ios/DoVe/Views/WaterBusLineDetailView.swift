import SwiftUI
import MapKit

struct WaterBusLineDetailView: View {
    let route: WaterBusRoute
    @Environment(WaterBusViewModel.self) private var vm
    @Environment(LocationManager.self) private var locationManager
    @Environment(\.strings) private var strings
    @State private var selectedDirection: Int = 0
    @State private var mapPosition: MapCameraPosition = .automatic

    var body: some View {
        let direction = route.directions.first { $0.id == selectedDirection }
        let stops = vm.stopsForRoute(route, direction: selectedDirection)

        ScrollView {
            VStack(spacing: 0) {
                // Map with polyline
                routeMap(direction: direction, stops: stops)
                    .frame(height: 300)

                // Direction picker
                if route.directions.count > 1 {
                    directionPicker
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                }

                // Route info
                routeHeader(direction: direction, stopsCount: stops.count)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                // Stops list
                if !stops.isEmpty {
                    stopsSection(stops: stops)
                        .padding(.top, 20)
                }
            }
            .padding(.bottom, 40)
        }
        .navigationTitle(route.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .navigationDestination(for: WaterBusStop.self) { stop in
            WaterBusStopDetailView(stop: stop)
        }
        .onAppear {
            centerMapOnRoute(direction: direction)
        }
        .onChange(of: selectedDirection) { _, newDir in
            let dir = route.directions.first { $0.id == newDir }
            centerMapOnRoute(direction: dir)
        }
    }

    // MARK: - Map

    @ViewBuilder
    private func routeMap(direction: RouteDirection?, stops: [WaterBusStop]) -> some View {
        Map(position: $mapPosition, interactionModes: [.pan, .zoom, .rotate]) {
            // Route polyline
            if let direction, !direction.coordinates.isEmpty {
                MapPolyline(coordinates: direction.coordinates)
                    .stroke(route.color == Color(hex: "FFFFFF") ? .blue : route.color, lineWidth: 4)
            }

            // Stop annotations
            ForEach(stops) { stop in
                Annotation(stop.name, coordinate: stop.coordinate) {
                    NavigationLink(value: stop) {
                        stopPin
                    }
                    .buttonStyle(.plain)
                }
            }

            // User location
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

    // MARK: - Route Header

    @ViewBuilder
    private func routeHeader(direction: RouteDirection?, stopsCount: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Line badge + name
            HStack(spacing: 10) {
                LineBadge(line: route.name, vm: vm, size: .medium)

                VStack(alignment: .leading, spacing: 2) {
                    Text(route.longName)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    HStack(spacing: 6) {
                        Text(strings.waterBusStopsCount(stopsCount))
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)

                        Text("·")
                            .foregroundStyle(.quaternary)

                        Text(route.source.uppercased())
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            if let direction {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 11))
                    Text(direction.headsign)
                        .font(.system(size: 13))
                }
                .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Stops Section

    @ViewBuilder
    private func stopsSection(stops: [WaterBusStop]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(strings.waterBusRouteStops)
                .font(.system(size: 11, weight: .medium))
                .tracking(1.5)
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 20)
                .padding(.bottom, 10)

            let lineColor = route.color == Color(hex: "FFFFFF") ? Color.blue : route.color

            ForEach(Array(stops.enumerated()), id: \.element.id) { index, stop in
                NavigationLink(value: stop) {
                    HStack(spacing: 14) {
                        // Timeline indicator
                        VStack(spacing: 0) {
                            if index > 0 {
                                Rectangle()
                                    .fill(lineColor.opacity(0.3))
                                    .frame(width: 2)
                            } else {
                                Spacer().frame(width: 2)
                            }

                            Circle()
                                .fill(lineColor)
                                .frame(width: 10, height: 10)
                                .overlay(
                                    Circle()
                                        .stroke(.white, lineWidth: 1.5)
                                )

                            if index < stops.count - 1 {
                                Rectangle()
                                    .fill(lineColor.opacity(0.3))
                                    .frame(width: 2)
                            } else {
                                Spacer().frame(width: 2)
                            }
                        }
                        .frame(width: 10, height: 44)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(stop.name)
                                .font(.system(size: 15, weight: index == 0 || index == stops.count - 1 ? .semibold : .regular))
                                .foregroundStyle(.primary)
                                .lineLimit(1)

                            if let dist = locationManager.formattedDistance(to: stop.coordinate) {
                                Text(dist)
                                    .font(.system(size: 12))
                                    .foregroundStyle(.tertiary)
                            }
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 11))
                            .foregroundStyle(.quaternary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
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
