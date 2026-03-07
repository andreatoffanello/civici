import SwiftUI
import MapKit
import PhosphorSwift

struct TripDetailView: View {
    let departure: Departure
    let fromStop: WaterBusStop
    @Environment(WaterBusViewModel.self) private var vm
    @Environment(LocationManager.self) private var locationManager
    @State private var mapPosition: MapCameraPosition = .automatic
    @State private var expandedStops: Set<String> = []

    var body: some View {
        let trip = vm.reconstructTrip(departure: departure, fromStop: fromStop)

        ScrollView {
            VStack(spacing: 0) {
                // Map header
                tripMapHeader(trip: trip)

                // Trip info header
                tripInfoHeader(trip: trip)

                // Timeline
                if let trip, !trip.stops.isEmpty {
                    stopsTimeline(trip: trip)
                } else {
                    VStack(spacing: 8) {
                        Ph.boat.duotone
                            .renderingMode(.template)
                            .frame(width: 28, height: 28)
                            .foregroundColor(Color(.tertiaryLabel))
                        Text("Impossibile ricostruire la corsa")
                            .font(.system(size: 14))
                            .foregroundColor(Color(.secondaryLabel))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                }

                Color.clear.frame(height: 40)
            }
        }
        .navigationTitle("Linea \(departure.line)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .onAppear { centerMap(trip: trip) }
    }

    // MARK: - Origin Index

    private func originIndex(in stops: [TripStop]) -> Int {
        stops.firstIndex(where: { $0.stop.id == fromStop.id }) ?? 0
    }

    // MARK: - Map Header

    private func tripMapHeader(trip: (route: WaterBusRoute, direction: RouteDirection, stops: [TripStop])?) -> some View {
        Map(position: $mapPosition, interactionModes: [.pan, .zoom, .rotate]) {
            if let trip {
                let lineColor = resolveColor(trip.route.color)
                let origin = originIndex(in: trip.stops)

                if !trip.direction.coordinates.isEmpty {
                    MapPolyline(coordinates: trip.direction.coordinates)
                        .stroke(lineColor, lineWidth: 4)
                }

                ForEach(Array(trip.stops.enumerated()), id: \.element.id) { index, tripStop in
                    let isOrigin = index == origin
                    let isPast = index < origin
                    Annotation("", coordinate: tripStop.stop.coordinate) {
                        stopPin(color: lineColor, isOrigin: isOrigin, isPast: isPast)
                    }
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
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private func stopPin(color: Color, isOrigin: Bool, isPast: Bool) -> some View {
        ZStack {
            Circle()
                .fill(.white)
                .frame(width: isOrigin ? 18 : 14, height: isOrigin ? 18 : 14)
                .shadow(color: .black.opacity(0.15), radius: 2, y: 1)
            Circle()
                .fill(isPast ? color.opacity(0.35) : color)
                .frame(width: isOrigin ? 10 : 8, height: isOrigin ? 10 : 8)
        }
    }

    // MARK: - Trip Info Header

    private func tripInfoHeader(trip: (route: WaterBusRoute, direction: RouteDirection, stops: [TripStop])?) -> some View {
        HStack(spacing: 12) {
            LineBadge(line: departure.line, vm: vm, size: .medium)

            VStack(alignment: .leading, spacing: 3) {
                if let trip {
                    let headsignParsed = parseDock(from: trip.direction.headsign)
                    HStack(spacing: 5) {
                        Ph.arrowRight.bold
                            .renderingMode(.template)
                            .frame(width: 11, height: 11)
                            .foregroundColor(Color(.secondaryLabel))
                        Text(headsignParsed.name)
                            .font(.system(size: 16, weight: .semibold))
                            .lineLimit(1)
                        if let dock = headsignParsed.dock {
                            DockBadge(letter: dock, size: .medium)
                        }
                    }
                }

                HStack(spacing: 6) {
                    if let trip {
                        Text("\(trip.stops.count) fermate")
                            .font(.system(size: 12))
                            .foregroundColor(Color(.secondaryLabel))

                        if let first = trip.stops.first, let last = trip.stops.last {
                            Text("·")
                                .foregroundColor(Color(.secondaryLabel))
                                .font(.system(size: 12))
                            Text("\(first.time) – \(last.time)")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(Color(.secondaryLabel))
                        }
                    }

                    Text("·")
                        .foregroundColor(Color(.secondaryLabel))
                        .font(.system(size: 12))

                    Image(trip?.route.source == "alilaguna" ? "logo-alilaguna" : "logo-actv")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 12)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    // MARK: - Timeline

    private func stopsTimeline(trip: (route: WaterBusRoute, direction: RouteDirection, stops: [TripStop])) -> some View {
        let lineColor = resolveColor(trip.route.color)
        let origin = originIndex(in: trip.stops)

        return VStack(alignment: .leading, spacing: 0) {
            Divider()
                .padding(.horizontal, 20)
                .padding(.bottom, 4)

            ForEach(Array(trip.stops.enumerated()), id: \.element.id) { index, tripStop in
                let isTerminal = index == 0 || index == trip.stops.count - 1
                let isOrigin = index == origin
                let isPast = index < origin
                let dotSize: CGFloat = isTerminal || isOrigin ? 12 : 8
                let otherLines = tripStop.stop.lines.filter { $0 != departure.line }
                let isExpanded = expandedStops.contains(tripStop.id)

                VStack(spacing: 0) {
                    // Main row
                    HStack(spacing: 0) {
                        // Time column
                        Text(tripStop.time)
                            .font(.system(size: 14, weight: isTerminal || isOrigin ? .bold : .regular, design: .monospaced))
                            .foregroundStyle(isPast ? Color(.tertiaryLabel) : isOrigin ? lineColor : .primary)
                            .frame(width: 52, alignment: .trailing)

                        // Timeline column
                        ZStack {
                            VStack(spacing: 0) {
                                Rectangle()
                                    .fill(index > 0 ? (isPast ? lineColor.opacity(0.25) : lineColor) : .clear)
                                    .frame(width: 3)
                                Rectangle()
                                    .fill(index < trip.stops.count - 1 ? (index < origin ? lineColor.opacity(0.25) : lineColor) : .clear)
                                    .frame(width: 3)
                            }

                            Circle()
                                .fill(isPast ? lineColor.opacity(0.35) : lineColor)
                                .frame(width: dotSize, height: dotSize)
                                .overlay(
                                    Circle()
                                        .fill(.white)
                                        .frame(width: isTerminal || isOrigin ? 5 : 0)
                                )
                        }
                        .frame(width: 20)
                        .frame(minHeight: 40)
                        .padding(.horizontal, 8)

                        // Stop info
                        VStack(alignment: .leading, spacing: 2) {
                            Text(tripStop.stop.name)
                                .font(.system(size: 15, weight: isTerminal || isOrigin ? .semibold : .regular))
                                .foregroundStyle(isPast ? Color(.tertiaryLabel) : isOrigin ? lineColor : .primary)
                                .lineLimit(1)

                            if let dist = locationManager.formattedDistance(to: tripStop.stop.coordinate) {
                                Text(dist)
                                    .font(.system(size: 11))
                                    .foregroundColor(Color(.tertiaryLabel))
                            }

                            // Connection badges on separate row
                            if !otherLines.isEmpty && !isPast {
                                HStack(spacing: 3) {
                                    Ph.arrowsLeftRight.bold
                                        .renderingMode(.template)
                                        .frame(width: 8, height: 8)
                                        .foregroundColor(Color(.tertiaryLabel))
                                    ForEach(otherLines.prefix(5), id: \.self) { line in
                                        LineBadge(line: line, vm: vm, size: .tiny)
                                    }
                                    if otherLines.count > 5 {
                                        Text("+\(otherLines.count - 5)")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundColor(Color(.secondaryLabel))
                                    }
                                }
                                .padding(.top, 1)
                            }
                        }

                        Spacer(minLength: 6)

                        // Dock badge + chevron aligned right
                        VStack(spacing: 4) {
                            if let dock = tripStop.dock {
                                DockBadge(letter: dock, size: .small)
                                    .opacity(isPast ? 0.4 : 1)
                            }
                            if !otherLines.isEmpty && !isPast {
                                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(Color(.tertiaryLabel))
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, !otherLines.isEmpty && !isPast ? 6 : 2)
                    .background(isOrigin ? lineColor.opacity(0.05) : .clear)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        guard !otherLines.isEmpty, !isPast else { return }
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if expandedStops.contains(tripStop.id) {
                                expandedStops.remove(tripStop.id)
                            } else {
                                expandedStops.insert(tripStop.id)
                            }
                        }
                    }

                    // Expanded connections
                    if isExpanded {
                        connectionsView(stop: tripStop.stop, arrivalTime: tripStop.time, lineColor: lineColor, index: index, totalStops: trip.stops.count, origin: origin)
                    }
                }
            }
        }
    }

    // MARK: - Connections

    private func connectionsView(stop: WaterBusStop, arrivalTime: String, lineColor: Color, index: Int, totalStops: Int, origin: Int) -> some View {
        let conns = vm.connections(at: stop, arrivalTime: arrivalTime, excludingLine: departure.line)

        return HStack(spacing: 0) {
            Color.clear.frame(width: 52)

            ZStack {
                Rectangle()
                    .fill(index < totalStops - 1 ? (index < origin ? lineColor.opacity(0.25) : lineColor) : .clear)
                    .frame(width: 3)
            }
            .frame(width: 20)
            .padding(.horizontal, 8)

            VStack(alignment: .leading, spacing: 0) {
                if conns.isEmpty {
                    Text("Nessuna coincidenza entro 30 min")
                        .font(.system(size: 11))
                        .foregroundColor(Color(.tertiaryLabel))
                        .padding(.vertical, 6)
                } else {
                    Text("COINCIDENZE")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .tracking(0.5)
                        .foregroundColor(Color(.tertiaryLabel))
                        .padding(.top, 6)
                        .padding(.bottom, 4)

                    ForEach(Array(conns.enumerated()), id: \.element.departure.id) { i, conn in
                        let parsed = parseDock(from: conn.departure.headsign)
                        HStack(spacing: 0) {
                            LineBadge(line: conn.line, vm: vm, size: .small)
                                .frame(width: 38, alignment: .leading)

                            Text(conn.departure.time)
                                .font(.system(size: 13, weight: .medium, design: .monospaced))
                                .foregroundStyle(.primary)
                                .frame(width: 48, alignment: .leading)

                            Text(parsed.name)
                                .font(.system(size: 13))
                                .foregroundColor(Color(.secondaryLabel))
                                .lineLimit(1)

                            Spacer(minLength: 4)

                            if let dock = parsed.dock {
                                DockBadge(letter: dock, size: .small)
                            }
                        }
                        .padding(.vertical, 5)
                        if i < conns.count - 1 {
                            Divider()
                        }
                    }
                }
            }
            .padding(.vertical, 2)
            .padding(.horizontal, 12)
            .background(Color(.systemGray6).opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.trailing, 20)
            .padding(.bottom, 4)
        }
        .padding(.leading, 20)
    }

    // MARK: - Helpers

    private func resolveColor(_ color: Color) -> Color {
        color == Color(hex: "FFFFFF") ? .blue : color
    }

    private func centerMap(trip: (route: WaterBusRoute, direction: RouteDirection, stops: [TripStop])?) {
        guard let trip, !trip.direction.coordinates.isEmpty else { return }
        let lats = trip.direction.coordinates.map(\.latitude)
        let lngs = trip.direction.coordinates.map(\.longitude)
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
        mapPosition = .region(MKCoordinateRegion(center: center, span: span))
    }
}
