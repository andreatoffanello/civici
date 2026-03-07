import SwiftUI
import MapKit
import PhosphorSwift

struct WaterBusStopDetailView: View {
    let stop: WaterBusStop
    @Environment(WaterBusViewModel.self) private var vm
    @Environment(LocationManager.self) private var locationManager
    @Environment(\.strings) private var strings
    @State private var mapPosition: MapCameraPosition = .automatic
    private static let peekDetent = PresentationDetent.height(140)
    @State private var sheetDetent: PresentationDetent = .medium
    @State private var showSheet = false
    @State private var showFullSchedule = false

    // Trip state — quando non-nil, mappa e sheet mostrano la corsa
    @State private var activeTrip: TripNavigation?
    @State private var expandedStops: Set<String> = []

    private var tripData: (route: WaterBusRoute, direction: RouteDirection, stops: [TripStop])? {
        guard let nav = activeTrip else { return nil }
        return vm.reconstructTrip(departure: nav.departure, fromStop: nav.stop)
    }

    var body: some View {
        Map(position: $mapPosition) {
            // Stop pins (sempre visibili, sfumati durante trip)
            if stop.docks.isEmpty {
                Annotation(stop.name, coordinate: stop.coordinate) {
                    ZStack {
                        Circle()
                            .fill(Color.doVeNavigation)
                            .frame(width: 28, height: 28)
                        Ph.boat.fill
                            .frame(width: 14, height: 14)
                            .foregroundStyle(.white)
                    }
                    .opacity(activeTrip == nil ? 1 : 0.3)
                }
            } else {
                ForEach(stop.docks) { dock in
                    Annotation("", coordinate: dock.coordinate) {
                        StopDetailDockPin(stop: stop, dock: dock, vm: vm)
                            .opacity(activeTrip == nil ? 1 : 0.3)
                    }
                }
            }

            // Trip overlay — polyline + stop pins
            if let trip = tripData {
                let lineColor = resolveColor(trip.route.color)
                let origin = tripOriginIndex(in: trip.stops)

                if !trip.direction.coordinates.isEmpty {
                    MapPolyline(coordinates: trip.direction.coordinates)
                        .stroke(lineColor, lineWidth: 4)
                }

                ForEach(Array(trip.stops.enumerated()), id: \.element.id) { index, tripStop in
                    let isOrigin = index == origin
                    let isPast = index < origin
                    Annotation("", coordinate: tripStop.stop.coordinate) {
                        tripStopPin(color: lineColor, isOrigin: isOrigin, isPast: isPast)
                    }
                }
            }

            if let location = locationManager.userLocation {
                Annotation("", coordinate: location.coordinate) {
                    Circle()
                        .fill(.blue)
                        .frame(width: 12, height: 12)
                        .overlay(Circle().stroke(.white, lineWidth: 2))
                }
            }
        }
        .mapStyle(.standard(pointsOfInterest: .excludingAll))
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: sheetDetent == .large ? 0 : sheetDetent == .medium ? UIScreen.main.bounds.height * 0.5 : 140)
        }
        .ignoresSafeArea(edges: .bottom)
        .navigationTitle(activeTrip == nil ? stop.name : "Linea \(activeTrip!.departure.line)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarRole(.editor)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if activeTrip == nil {
                    Button {
                        withAnimation(.spring(duration: 0.3)) {
                            vm.toggleFavorite(stop)
                        }
                    } label: {
                        Image(systemName: vm.isFavorite(stop) ? "bookmark.fill" : "bookmark")
                            .foregroundStyle(vm.isFavorite(stop) ? Color.doVeNavigation : .secondary)
                            .symbolEffect(.bounce, value: vm.isFavorite(stop))
                    }
                }
            }
        }
        .onAppear {
            centerOnStop()
            showSheet = true
        }
        .onChange(of: activeTrip) { _, newTrip in
            if newTrip != nil {
                // Centra mappa sulla corsa
                if let trip = tripData {
                    centerOnTrip(trip)
                }
            } else {
                // Torna alla fermata
                expandedStops.removeAll()
                centerOnStop()
            }
        }
        .sheet(isPresented: $showSheet) {
            sheetContent
                .presentationDetents([Self.peekDetent, .medium, .large], selection: $sheetDetent)
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled(upThrough: .medium))
                .presentationCornerRadius(20)
                .interactiveDismissDisabled()
        }
    }

    // MARK: - Sheet Content (switch stop / trip)

    @ViewBuilder
    private var sheetContent: some View {
        if let nav = activeTrip, let trip = tripData {
            tripSheetContent(nav: nav, trip: trip)
                .fullScreenCover(isPresented: $showFullSchedule) {
                    FullScheduleView(stop: stop)
                }
        } else {
            stopSheetContent
                .fullScreenCover(isPresented: $showFullSchedule) {
                    FullScheduleView(stop: stop)
                }
        }
    }

    // MARK: - Stop Sheet Content

    private var stopSheetContent: some View {
        let next = vm.nextDepartures(for: stop, count: 5)

        return ScrollView {
            VStack(spacing: 0) {
                peekHeader
                linesSection

                if !next.isEmpty {
                    nextDeparturesSection(next)
                } else {
                    VStack(spacing: 8) {
                        Ph.boat.duotone
                            .renderingMode(.template)
                            .frame(width: 28, height: 28)
                            .foregroundColor(Color(.tertiaryLabel))
                        Text(strings.waterBusNoDepartures)
                            .font(.system(size: 14))
                            .foregroundColor(Color(.secondaryLabel))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                }

                // Full schedule button
                if !stop.departures.isEmpty {
                    Button {
                        showFullSchedule = true
                    } label: {
                        HStack(spacing: 6) {
                            Ph.calendarDots.duotone
                                .renderingMode(.template)
                                .frame(width: 16, height: 16)
                            Text(strings.waterBusFullSchedule)
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundStyle(Color.doVeNavigation)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.doVeNavigation.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                    .padding(.bottom, 20)
                }
            }
        }
    }

    // MARK: - Trip Sheet Content (no map — usa quella di sfondo)

    private func tripSheetContent(nav: TripNavigation, trip: (route: WaterBusRoute, direction: RouteDirection, stops: [TripStop])) -> some View {
        VStack(spacing: 0) {
            // Fixed header
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            activeTrip = nil
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                            Text(stop.name)
                                .font(.system(size: 15, weight: .medium))
                        }
                        .foregroundStyle(Color.doVeNavigation)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 4)

                tripInfoHeader(trip: trip, departure: nav.departure)
            }

            // Scrollable timeline
            if !trip.stops.isEmpty {
                ScrollViewReader { proxy in
                    ScrollView {
                        stopsTimeline(trip: trip, departure: nav.departure)
                        Color.clear.frame(height: 40)
                    }
                    .onAppear {
                        let origin = tripOriginIndex(in: trip.stops)
                        if origin < trip.stops.count {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    proxy.scrollTo(trip.stops[origin].id, anchor: .center)
                                }
                            }
                        }
                    }
                }
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
                Spacer()
            }
        }
    }

    // MARK: - Trip Info Header

    private func tripInfoHeader(trip: (route: WaterBusRoute, direction: RouteDirection, stops: [TripStop]), departure: Departure) -> some View {
        HStack(spacing: 12) {
            LineBadge(line: departure.line, vm: vm, size: .medium)

            VStack(alignment: .leading, spacing: 3) {
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

                HStack(spacing: 6) {
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

                    Text("·")
                        .foregroundColor(Color(.secondaryLabel))
                        .font(.system(size: 12))

                    OperatorLogo(trip.route.source == "alilaguna" ? "logo-alilaguna" : "logo-actv", height: 12)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    // MARK: - Stops Timeline

    private func stopsTimeline(trip: (route: WaterBusRoute, direction: RouteDirection, stops: [TripStop]), departure: Departure) -> some View {
        let lineColor = resolveColor(trip.route.color)
        let origin = tripOriginIndex(in: trip.stops)

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
                    HStack(spacing: 0) {
                        Text(tripStop.time)
                            .font(.system(size: 14, weight: isTerminal || isOrigin ? .bold : .regular, design: .monospaced))
                            .foregroundStyle(isPast ? Color(.tertiaryLabel) : isOrigin ? lineColor : .primary)
                            .frame(width: 52, alignment: .trailing)

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

                    if isExpanded {
                        connectionsView(stop: tripStop.stop, arrivalTime: tripStop.time, lineColor: lineColor, index: index, totalStops: trip.stops.count, origin: origin, departure: departure)
                    }
                }
                .id(tripStop.id)
            }
        }
    }

    // MARK: - Connections

    private func connectionsView(stop: WaterBusStop, arrivalTime: String, lineColor: Color, index: Int, totalStops: Int, origin: Int, departure: Departure) -> some View {
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

    // MARK: - Peek Header

    private var peekHeader: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(stop.name)
                    .font(.system(size: 22, weight: .bold))

                if let dist = locationManager.formattedDistance(to: stop.coordinate) {
                    Label(dist, systemImage: "location.fill")
                        .font(.system(size: 13))
                        .foregroundColor(Color(.secondaryLabel))
                }
            }

            Spacer()

            Button { openInMaps() } label: {
                Ph.navigationArrow.duotone
                    .renderingMode(.template)
                    .frame(width: 28, height: 28)
                    .foregroundStyle(Color.doVeNavigation)
                    .frame(width: 44, height: 44)
                    .background(Color.doVeNavigation.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 12)
    }

    // MARK: - Lines Section

    private var linesSection: some View {
        let groups = vm.linesBySource(for: stop)
        let hasAlilaguna = !groups.alilaguna.isEmpty

        return VStack(alignment: .leading, spacing: 10) {
            if !groups.actv.isEmpty {
                HStack(spacing: 8) {
                    OperatorLogo("logo-actv")
                    FlowLayout(spacing: 6) {
                        ForEach(groups.actv, id: \.self) { line in
                            LineBadge(line: line, vm: vm, size: .small)
                        }
                    }
                }
            }
            if hasAlilaguna {
                HStack(spacing: 8) {
                    OperatorLogo("logo-alilaguna")
                    FlowLayout(spacing: 6) {
                        ForEach(groups.alilaguna, id: \.self) { line in
                            LineBadge(line: line, vm: vm, size: .small)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }

    // MARK: - Next Departures (Hero)

    private func nextDeparturesSection(_ departures: [Departure]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(departures.enumerated()), id: \.element.id) { index, dep in
                let isFirst = index == 0

                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        activeTrip = TripNavigation(departure: dep, stop: stop)
                        sheetDetent = .medium
                    }
                } label: {
                    HStack(spacing: 0) {
                        HStack(spacing: 4) {
                            if dep.isImminent {
                                Circle()
                                    .fill(Color.doVeSoon)
                                    .frame(width: 6, height: 6)
                                    .modifier(PulseModifier())
                            }
                            Text(dep.countdownLabel)
                                .font(.system(size: isFirst ? 14 : 13, weight: isFirst ? .bold : .semibold))
                                .foregroundStyle(dep.isSoon ? Color.doVeSoon : .primary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                        }
                        .frame(width: 90, alignment: .leading)

                        LineBadge(line: dep.line, vm: vm, size: .small)
                            .padding(.trailing, 8)

                        let parsed = parseDock(from: dep.headsign)
                        Text(parsed.name)
                            .font(.system(size: isFirst ? 14 : 13))
                            .foregroundStyle(isFirst ? .primary : .secondary)
                            .lineLimit(1)

                        Spacer(minLength: 4)

                        Text(dep.time)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(Color(.tertiaryLabel))

                        // Dock di PARTENZA (non destinazione)
                        if let dock = vm.departureDock(for: dep, at: stop) {
                            DockBadge(letter: dock, size: .small)
                                .padding(.leading, 4)
                        }

                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Color(.tertiaryLabel))
                            .padding(.leading, 4)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, isFirst ? 14 : 10)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if index < departures.count - 1 {
                    Divider()
                        .padding(.leading, 20)
                }
            }
        }
        .background(Color(.secondarySystemBackground).opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }

    // MARK: - Trip Map Pin

    private func tripStopPin(color: Color, isOrigin: Bool, isPast: Bool) -> some View {
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

    // MARK: - Helpers

    private func resolveColor(_ color: Color) -> Color {
        color == Color(hex: "FFFFFF") ? .blue : color
    }

    private func tripOriginIndex(in stops: [TripStop]) -> Int {
        stops.firstIndex(where: { $0.stop.id == stop.id }) ?? 0
    }

    private func centerOnStop() {
        withAnimation(.easeInOut(duration: 0.4)) {
            mapPosition = .region(MKCoordinateRegion(
                center: stop.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.006, longitudeDelta: 0.006)
            ))
        }
    }

    private func centerOnTrip(_ trip: (route: WaterBusRoute, direction: RouteDirection, stops: [TripStop])) {
        guard !trip.direction.coordinates.isEmpty else { return }
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
        withAnimation(.easeInOut(duration: 0.4)) {
            mapPosition = .region(MKCoordinateRegion(center: center, span: span))
        }
    }

    private func openInMaps() {
        let coord = stop.coordinate
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coord))
        mapItem.name = stop.name
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking
        ])
    }
}

// MARK: - Full Schedule View

struct FullScheduleView: View {
    let stop: WaterBusStop
    @Environment(WaterBusViewModel.self) private var vm
    @Environment(\.strings) private var strings
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDayGroup: DayGroup?
    @State private var filterLine: String?

    init(stop: WaterBusStop) {
        self.stop = stop
        let today = Date()
        let initial = stop.departures.keys.first { $0.contains(date: today) }
            ?? stop.departures.keys.sorted().first
        _selectedDayGroup = State(initialValue: initial)
    }

    private var currentDepartures: [Departure] {
        guard let group = selectedDayGroup else { return [] }
        return stop.departures[group] ?? []
    }

    private var filteredDepartures: [Departure] {
        let deps = currentDepartures
        guard let line = filterLine else { return deps }
        return deps.filter { $0.line == line }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    daySelector
                    lineFilter
                    departuresBoard
                }
            }
            .navigationTitle(stop.name)
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: TripNavigation.self) { nav in
                TripDetailView(departure: nav.departure, fromStop: nav.stop)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Day Selector

    private var daySelector: some View {
        let groups = stop.departures.keys.sorted()
        guard groups.count > 1 else { return AnyView(EmptyView()) }

        return AnyView(
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(groups, id: \.key) { group in
                        let isSelected = selectedDayGroup == group
                        Button {
                            withAnimation(.smooth(duration: 0.2)) {
                                selectedDayGroup = group
                                filterLine = nil
                            }
                        } label: {
                            Text(group.localizedLabel)
                                .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                                .foregroundStyle(isSelected ? .white : .primary)
                                .padding(.horizontal, 16)
                                .frame(height: 44)
                                .background(isSelected ? Color.doVeNavigation : Color(.systemGray6))
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
            }
        )
    }

    // MARK: - Line Filter

    private var lineFilter: some View {
        let lines = Set(currentDepartures.map(\.line)).sorted()
        guard lines.count > 1 else { return AnyView(EmptyView()) }

        return AnyView(
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Button {
                        withAnimation(.smooth(duration: 0.2)) { filterLine = nil }
                    } label: {
                        Text(strings.waterBusAllLines)
                            .font(.system(size: 14, weight: filterLine == nil ? .semibold : .medium))
                            .foregroundStyle(filterLine == nil ? .white : .primary)
                            .padding(.horizontal, 16)
                            .frame(height: 36)
                            .background(filterLine == nil ? Color.doVeNavigation : Color(.systemGray6))
                            .clipShape(Capsule())
                    }

                    ForEach(lines, id: \.self) { line in
                        Button {
                            withAnimation(.smooth(duration: 0.2)) { filterLine = line }
                        } label: {
                            LineBadge(line: line, vm: vm, size: .medium)
                                .opacity(filterLine == nil || filterLine == line ? 1 : 0.4)
                        }
                        .frame(minHeight: 36)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
            }
        )
    }

    // MARK: - Departures Board

    private var departuresBoard: some View {
        let departures = filteredDepartures

        return VStack(spacing: 0) {
            if departures.isEmpty {
                VStack(spacing: 8) {
                    Ph.boat.duotone
                        .renderingMode(.template)
                        .frame(width: 28, height: 28)
                        .foregroundColor(Color(.tertiaryLabel))
                    Text(strings.waterBusNoDepartures)
                        .font(.system(size: 14))
                        .foregroundColor(Color(.secondaryLabel))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                let grouped = Dictionary(grouping: departures) { dep in
                    String(dep.time.prefix(2))
                }
                let hours = grouped.keys.sorted()

                ForEach(hours, id: \.self) { hour in
                    if let hourDeps = grouped[hour] {
                        HStack(spacing: 6) {
                            Text(hour)
                                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                .foregroundColor(Color(.secondaryLabel))
                                .frame(width: 24, alignment: .trailing)
                            Rectangle()
                                .fill(Color(.separator).opacity(0.2))
                                .frame(height: 0.5)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        .padding(.bottom, 2)

                        ForEach(hourDeps) { dep in
                            NavigationLink(value: TripNavigation(departure: dep, stop: stop)) {
                                HStack(spacing: 10) {
                                    Text(dep.time)
                                        .font(.system(size: 15, weight: .medium, design: .monospaced))
                                        .foregroundStyle(.primary)
                                        .frame(width: 52, alignment: .leading)

                                    LineBadge(line: dep.line, vm: vm, size: .small)

                                    let depParsed = parseDock(from: dep.headsign)
                                    Text(depParsed.name)
                                        .font(.system(size: 14))
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)

                                    Spacer()

                                    // Dock di PARTENZA
                                    if let depDock = vm.departureDock(for: dep, at: stop) {
                                        DockBadge(letter: depDock, size: .small)
                                    }

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(Color(.quaternaryLabel))
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 6)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Color.clear.frame(height: 40)
            }
        }
    }
}

// MARK: - Stop Detail Dock Pin

private struct StopDetailDockPin: View {
    let stop: WaterBusStop
    let dock: Dock
    let vm: WaterBusViewModel

    var body: some View {
        let activeLines = vm.activeLinesForDock(stop: stop, dockLetter: dock.letter)

        VStack(spacing: 3) {
            ZStack {
                Circle()
                    .fill(.white)
                    .frame(width: 26, height: 26)
                Circle()
                    .fill(Color(red: 1.0, green: 0.82, blue: 0.0))
                    .frame(width: 22, height: 22)
                Text(dock.letter)
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(.black)
            }
            .shadow(color: .black.opacity(0.2), radius: 3, y: 1)

            if !activeLines.isEmpty {
                HStack(spacing: 2) {
                    ForEach(activeLines, id: \.self) { line in
                        LineBadge(line: line, vm: vm, size: .tiny)
                    }
                }
            }
        }
        .fixedSize()
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }

        return CGSize(width: width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX && x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
