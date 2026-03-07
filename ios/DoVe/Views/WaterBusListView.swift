import SwiftUI
import MapKit
import CoreLocation
import PhosphorSwift

// MARK: - Main View with Map/List Toggle

struct WaterBusListView: View {
    @Environment(WaterBusViewModel.self) private var vm
    @Environment(LocationManager.self) private var locationManager
    @Environment(\.strings) private var strings
    @State private var viewMode: ViewMode = .map
    @State private var contentMode: ContentMode = .stops
    @State private var appeared = false
    @FocusState private var isSearchFocused: Bool

    enum ViewMode: String { case map, list }
    enum ContentMode: String { case stops, lines }

    var body: some View {
        @Bindable var vm = vm

        ZStack(alignment: .top) {
            // MARK: Content layer
            switch contentMode {
            case .stops:
                switch viewMode {
                case .map:
                    WaterBusMapView(
                        stops: vm.stops,
                        vm: vm,
                        userLocation: locationManager.userLocation
                    )
                    .ignoresSafeArea(edges: .bottom)
                case .list:
                    WaterBusSearchListView(
                        vm: vm,
                        locationManager: locationManager,
                        appeared: appeared,
                        strings: strings
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

            // MARK: Top bar overlay
            VStack(spacing: 8) {
                // Segmented picker
                CapsuleSegmentedControl(
                    selection: $contentMode,
                    items: [
                        (.stops, strings.waterBusStops, Ph.mapPin),
                        (.lines, strings.waterBusLines, Ph.path)
                    ]
                )
                .padding(.horizontal, 16)
                .padding(.top, 10)

                if contentMode == .stops {
                    HStack(spacing: 10) {
                        if viewMode == .map {
                            // Fake search pill — tap switches to list
                            Button {
                                withAnimation(.smooth(duration: 0.2)) {
                                    viewMode = .list
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    isSearchFocused = true
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 14))
                                    Text(strings.waterBusSearchPlaceholder)
                                        .font(.system(size: 15))
                                        .lineLimit(1)
                                }
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .frame(height: 36)
                                .padding(.horizontal, 10)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                        } else {
                            // Real search bar in list mode
                            HStack(spacing: 8) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(isSearchFocused ? Color.doVeNavigation : .secondary)

                                TextField(strings.waterBusSearchPlaceholder, text: $vm.searchText)
                                    .font(.system(size: 15))
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                                    .focused($isSearchFocused)
                                    .submitLabel(.search)

                                if !vm.searchText.isEmpty {
                                    Button {
                                        withAnimation(.smooth(duration: 0.15)) { vm.searchText = "" }
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 16))
                                            .foregroundStyle(.secondary)
                                            .frame(width: 36, height: 36)
                                            .contentShape(Rectangle())
                                    }
                                }
                            }
                            .frame(height: 36)
                            .padding(.horizontal, 10)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(
                                        isSearchFocused ? Color.doVeNavigation.opacity(0.4) : .clear,
                                        lineWidth: 1.5
                                    )
                            )
                        }

                        // Map/list toggle
                        HStack(spacing: 2) {
                            toggleButton(icon: .mapTrifold, mode: .map)
                            toggleButton(icon: .listBullets, mode: .list)
                        }
                        .padding(2)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
                } else {
                    // Lines mode search
                    HStack(spacing: 6) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                        TextField(strings.waterBusSearchPlaceholder, text: $vm.searchText)
                            .font(.system(size: 15))
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                        if !vm.searchText.isEmpty {
                            Button { vm.searchText = "" } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(.secondary)
                                    .frame(width: 36, height: 36)
                                    .contentShape(Rectangle())
                            }
                        }
                    }
                    .frame(height: 36)
                    .padding(.horizontal, 10)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
                }
            }
            .contentShape(Rectangle())
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
            if let mode = vm.deepLinkViewMode {
                vm.deepLinkViewMode = nil
                viewMode = mode == "list" ? .list : .map
            }
            if let mode = vm.deepLinkContentMode {
                vm.deepLinkContentMode = nil
                contentMode = mode == "lines" ? .lines : .stops
            }
        }
        .onChange(of: viewMode) { _, newMode in
            if newMode == .map { vm.searchText = "" }
        }
        .onChange(of: vm.deepLinkViewMode) { _, mode in
            guard let mode else { return }
            vm.deepLinkViewMode = nil
            withAnimation(.smooth(duration: 0.2)) {
                if mode == "map" { viewMode = .map }
                else if mode == "list" { viewMode = .list }
            }
        }
        .onChange(of: vm.deepLinkContentMode) { _, mode in
            guard let mode else { return }
            vm.deepLinkContentMode = nil
            withAnimation(.smooth(duration: 0.2)) {
                if mode == "stops" { contentMode = .stops }
                else if mode == "lines" { contentMode = .lines }
            }
        }
    }

    private func toggleButton(icon: Ph, mode: ViewMode) -> some View {
        Button {
            withAnimation(.smooth(duration: 0.2)) { viewMode = mode }
        } label: {
            icon.duotone
                .renderingMode(.template)
                .frame(width: 16, height: 16)
                .foregroundStyle(viewMode == mode ? .white : .secondary)
                .frame(width: 36, height: 32)
                .background(viewMode == mode ? Color.doVeNavigation : .clear)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

// MARK: - Map View

private struct WaterBusMapView: View {
    let stops: [WaterBusStop]
    let vm: WaterBusViewModel
    let userLocation: CLLocation?
    private static let veniceCenter = CLLocationCoordinate2D(latitude: 45.4375, longitude: 12.3358)

    @State private var mapPosition: MapCameraPosition = .region(MKCoordinateRegion(
        center: veniceCenter,
        span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)
    ))
    @State private var zoomLevel: ZoomLevel = .far
    @State private var navigateToStop: WaterBusStop?

    enum ZoomLevel: Hashable {
        case far    // tutta Venezia — solo pin
        case medium // quartiere — pin + nome
        case close  // fermata — pin + nome + linee

        init(latitudeDelta: Double) {
            switch latitudeDelta {
            case ..<0.008: self = .close
            case ..<0.02:  self = .medium
            default:       self = .far
            }
        }
    }

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
                    let showDocks = zoomLevel == .close && !stop.docks.isEmpty

                    if showDocks {
                        ForEach(Array(stop.docks.enumerated()), id: \.element.id) { index, dock in
                            Annotation("", coordinate: dock.coordinate, anchor: .center) {
                                Button { navigateToStop = stop } label: {
                                    WaterBusDockPin(
                                        stop: stop,
                                        dock: dock,
                                        showName: index == 0,
                                        vm: vm
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    } else {
                        Annotation("", coordinate: stop.coordinate, anchor: .top) {
                            Button { navigateToStop = stop } label: {
                                WaterBusStopPin(
                                    stop: stop,
                                    zoomLevel: zoomLevel,
                                    vm: vm
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .mapStyle(.standard(pointsOfInterest: .excludingAll))
            .onMapCameraChange(frequency: .continuous) { context in
                let newZoom = ZoomLevel(latitudeDelta: context.region.span.latitudeDelta)
                if newZoom != zoomLevel {
                    zoomLevel = newZoom
                }
            }
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
                        Ph.crosshairSimple.duotone
                            .renderingMode(.template)
                            .frame(width: 18, height: 18)
                            .foregroundStyle(.primary)
                            .frame(width: 44, height: 44)
                            .background(.regularMaterial)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                    }
                    .padding(.trailing, 16)
                    .padding(.bottom, 16)
                }
            }
        }
        .navigationDestination(item: $navigateToStop) { stop in
            WaterBusStopDetailView(stop: stop)
        }
    }
}

// MARK: - Stop Map Pin

private struct WaterBusStopPin: View {
    let stop: WaterBusStop
    let zoomLevel: WaterBusMapView.ZoomLevel
    let vm: WaterBusViewModel

    private var iconSize: CGFloat {
        let count = stop.lines.count
        switch count {
        case 0...2: return 22
        case 3...5: return 26
        default:    return 30
        }
    }

    private var ferrySize: CGFloat {
        let count = stop.lines.count
        switch count {
        case 0...2: return 10
        case 3...5: return 12
        default:    return 14
        }
    }

    var body: some View {
        VStack(spacing: 3) {
            ZStack {
                Circle()
                    .fill(.white)
                    .frame(width: iconSize, height: iconSize)
                Circle()
                    .fill(Color.doVeNavigation)
                    .frame(width: iconSize - 3, height: iconSize - 3)
                Ph.boat.fill
                    .frame(width: ferrySize, height: ferrySize)
                    .foregroundStyle(.white)
            }
            .shadow(color: .black.opacity(0.2), radius: 2.5, y: 1)

            if zoomLevel != .far {
                Text(stop.name)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(.white.opacity(0.9))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .shadow(color: .black.opacity(0.1), radius: 2, y: 1)

                if zoomLevel == .close && stop.docks.isEmpty {
                    FlowLayout(spacing: 2) {
                        ForEach(stop.lines, id: \.self) { line in
                            LineBadge(line: line, vm: vm, size: .small)
                        }
                    }
                    .frame(maxWidth: 160)
                }
            }
        }
        .fixedSize()
        .frame(minWidth: 44, minHeight: 44)
        .contentShape(Rectangle())
        .animation(.easeInOut(duration: 0.2), value: zoomLevel)
    }
}

// MARK: - Dock Map Pin (imbarcadero con badge linee)

private struct WaterBusDockPin: View {
    let stop: WaterBusStop
    let dock: Dock
    let showName: Bool
    let vm: WaterBusViewModel

    var body: some View {
        let activeLines = vm.activeLinesForDock(stop: stop, dockLetter: dock.letter)

        VStack(spacing: 2) {
            if showName {
                Text(stop.name)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(.white.opacity(0.9))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
            }

            ZStack {
                Circle()
                    .fill(.white)
                    .frame(width: 22, height: 22)
                Circle()
                    .fill(Color(red: 1.0, green: 0.82, blue: 0.0))
                    .frame(width: 18, height: 18)
                Text(dock.letter)
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(.black)
            }
            .shadow(color: .black.opacity(0.2), radius: 2, y: 1)

            if !activeLines.isEmpty {
                HStack(spacing: 2) {
                    ForEach(activeLines, id: \.self) { line in
                        LineBadge(line: line, vm: vm, size: .tiny)
                    }
                }
            }
        }
        .fixedSize()
        .frame(minWidth: 36, minHeight: 36)
        .contentShape(Rectangle())
    }
}

// MARK: - Search + List View (Google Maps style)

private struct WaterBusSearchListView: View {
    @Bindable var vm: WaterBusViewModel
    let locationManager: LocationManager
    let appeared: Bool
    let strings: L10n.Strings

    private var results: [WaterBusStop] {
        vm.stopsSortedByDistance(from: locationManager.userLocation)
    }

    private var isSearching: Bool {
        !vm.searchText.isEmpty
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Spacer for top bar overlay (segmented + search + toggle)
                Color.clear.frame(height: 100)

                // Results
                if isSearching && results.isEmpty {
                    VStack(spacing: 8) {
                        Ph.magnifyingGlass.duotone
                            .renderingMode(.template)
                            .frame(width: 28, height: 28)
                            .foregroundColor(Color(.tertiaryLabel))
                        Text(strings.waterBusNoResults)
                            .font(.system(size: 15))
                            .foregroundColor(Color(.secondaryLabel))
                    }
                    .padding(.top, 40)
                } else {
                    if isSearching {
                        HStack {
                            Text("\(results.count) risultati")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color(.secondaryLabel))
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 6)
                    }

                    ForEach(results) { stop in
                        NavigationLink(value: stop) {
                            WaterBusStopRow(
                                stop: stop,
                                vm: vm,
                                locationManager: locationManager,
                                highlightQuery: isSearching ? vm.searchText : nil
                            )
                        }
                        .buttonStyle(.plain)

                        Divider().padding(.leading, 16)
                    }
                }

                Color.clear.frame(height: 120)
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }
}

// MARK: - Stop Row

private struct WaterBusStopRow: View {
    let stop: WaterBusStop
    let vm: WaterBusViewModel
    let locationManager: LocationManager
    var highlightQuery: String? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Left: name + line badges by company
            VStack(alignment: .leading, spacing: 6) {
                highlightedName
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(1)

                // Line badges organized by company, wrapping
                let groups = vm.linesBySource(for: stop)
                VStack(alignment: .leading, spacing: 5) {
                    if !groups.actv.isEmpty {
                        companyDivider(name: "ACTV")
                        FlowLayout(spacing: 4) {
                            ForEach(groups.actv, id: \.self) { line in
                                LineBadge(line: line, vm: vm, size: .small)
                            }
                        }
                    }
                    if !groups.alilaguna.isEmpty {
                        companyDivider(name: "Alilaguna")
                            .padding(.top, groups.actv.isEmpty ? 0 : 2)
                        FlowLayout(spacing: 4) {
                            ForEach(groups.alilaguna, id: \.self) { line in
                                LineBadge(line: line, vm: vm, size: .small)
                            }
                        }
                    }
                }
            }

            Spacer(minLength: 8)

            // Right: next departure block + distance
            VStack(alignment: .trailing, spacing: 6) {
                let next = vm.nextDepartures(for: stop, count: 1)
                if let dep = next.first {
                    VStack(alignment: .trailing, spacing: 2) {
                        HStack(spacing: 4) {
                            LineBadge(line: dep.line, vm: vm, size: .small)
                            Text(dep.time)
                                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                .foregroundStyle(.primary)
                        }
                        HStack(spacing: 4) {
                            if dep.isImminent {
                                Circle()
                                    .fill(Color.doVeSoon)
                                    .frame(width: 5, height: 5)
                                    .modifier(PulseModifier())
                            }
                            Text(dep.countdownLabel)
                                .font(.system(size: 12, weight: dep.isSoon ? .bold : .medium))
                                .foregroundStyle(dep.isSoon ? Color.doVeSoon : Color(.secondaryLabel))
                        }
                    }
                }

                if let dist = locationManager.formattedDistance(to: stop.coordinate) {
                    Text(dist)
                        .font(.system(size: 11))
                        .foregroundColor(Color(.tertiaryLabel))
                }
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(.tertiaryLabel))
                .padding(.top, 4)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func companyDivider(name: String) -> some View {
        HStack(spacing: 6) {
            Text(name.uppercased())
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .tracking(0.5)
                .foregroundColor(Color(.tertiaryLabel))
            Rectangle()
                .fill(Color(.separator).opacity(0.3))
                .frame(height: 0.5)
        }
    }

    /// Nome fermata con highlight della query di ricerca
    private var highlightedName: Text {
        guard let query = highlightQuery?.lowercased(), !query.isEmpty else {
            return Text(stop.name).foregroundColor(.primary)
        }
        let name = stop.name
        let lower = name.lowercased()
        guard let range = lower.range(of: query) else {
            return Text(name).foregroundColor(.primary)
        }
        let before = String(name[name.startIndex..<range.lowerBound])
        let match = String(name[range.lowerBound..<range.upperBound])
        let after = String(name[range.upperBound...])
        return Text(before).foregroundColor(.primary)
            + Text(match).foregroundColor(Color.doVeNavigation)
            + Text(after).foregroundColor(.primary)
    }
}

// MARK: - Line Badge

struct LineBadge: View {
    let line: String
    let vm: WaterBusViewModel
    let size: BadgeSize

    enum BadgeSize {
        case mini, tiny, small, medium

        var fontSize: CGFloat {
            switch self {
            case .mini: 7
            case .tiny: 9
            case .small: 11
            case .medium: 13
            }
        }

        var padding: EdgeInsets {
            switch self {
            case .mini: EdgeInsets(top: 1, leading: 3, bottom: 1, trailing: 3)
            case .tiny: EdgeInsets(top: 2, leading: 4, bottom: 2, trailing: 4)
            case .small: EdgeInsets(top: 3, leading: 6, bottom: 3, trailing: 6)
            case .medium: EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
            }
        }

        var cornerRadius: CGFloat {
            switch self {
            case .mini: 2
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
            .foregroundStyle(isWhiteRoute ? Color.black : fgColor)
            .padding(size.padding)
            .background(isWhiteRoute ? Color.white : bgColor)
            .clipShape(RoundedRectangle(cornerRadius: size.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: size.cornerRadius)
                    .strokeBorder(isWhiteRoute ? Color.black.opacity(0.15) : .clear, lineWidth: 1)
            )
    }
}

// MARK: - Operator Logo (ACTV / Alilaguna con sfondo bianco per dark mode)

struct OperatorLogo: View {
    let name: String
    let height: CGFloat

    init(_ name: String, height: CGFloat = 18) {
        self.name = name
        self.height = height
    }

    var body: some View {
        Image(name)
            .resizable()
            .scaledToFit()
            .frame(height: height)
            .padding(.horizontal, 4)
            .padding(.vertical, 3)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

// MARK: - Dock Badge (imbarcadero — sfondo giallo, testo nero, come segnaletica veneziana)

struct DockBadge: View {
    let letter: String
    let size: DockSize

    enum DockSize {
        case small, medium

        var fontSize: CGFloat {
            switch self {
            case .small: 12
            case .medium: 14
            }
        }

        var minWidth: CGFloat {
            switch self {
            case .small: 20
            case .medium: 24
            }
        }
    }

    var body: some View {
        Text(letter)
            .font(.system(size: size.fontSize, weight: .heavy, design: .rounded))
            .foregroundStyle(.black)
            .frame(minWidth: size.minWidth)
            .padding(.horizontal, 4)
            .padding(.vertical, 3)
            .background(Color(red: 1.0, green: 0.82, blue: 0.0))
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

/// Estrae la lettera dell'imbarcadero dalla fine di un headsign (pattern: `"X`)
/// Ritorna (nome pulito, lettera dock opzionale)
func parseDock(from headsign: String) -> (name: String, dock: String?) {
    // Pattern: `"X` o `"X"` alla fine (una lettera maiuscola dopo virgolette)
    let trimmed = headsign.hasSuffix("\"")
        ? String(headsign.dropLast()).trimmingCharacters(in: .whitespaces)
        : headsign
    guard let quoteRange = trimmed.range(of: " \"", options: .backwards),
          trimmed.distance(from: quoteRange.upperBound, to: trimmed.endIndex) <= 2 else {
        return (headsign, nil)
    }
    let letter = String(trimmed[quoteRange.upperBound...]).trimmingCharacters(in: .whitespaces)
    guard letter.count == 1, letter.first?.isUppercase == true else {
        return (headsign, nil)
    }
    let name = String(trimmed[..<quoteRange.lowerBound])
    return (name, letter)
}

// MARK: - Grouped Line Badges (ACTV | Alilaguna)

struct GroupedLineBadges: View {
    let stop: WaterBusStop
    let vm: WaterBusViewModel
    let size: LineBadge.BadgeSize
    var maxLines: Int = 0

    var body: some View {
        let groups = vm.linesBySource(for: stop)
        let actvLines = maxLines > 0 ? Array(groups.actv.prefix(maxLines)) : groups.actv
        let aliLines = groups.alilaguna

        HStack(spacing: 4) {
            ForEach(actvLines, id: \.self) { line in
                LineBadge(line: line, vm: vm, size: size)
            }

            if maxLines > 0 && groups.actv.count > maxLines {
                Text("+\(groups.actv.count - maxLines)")
                    .font(.system(size: size.fontSize))
                    .foregroundColor(Color(.secondaryLabel))
            }

            if !actvLines.isEmpty && !aliLines.isEmpty {
                Text("·")
                    .font(.system(size: size == .tiny ? 10 : 14, weight: .bold))
                    .foregroundColor(Color(.tertiaryLabel))
                    .padding(.horizontal, 1)
            }

            ForEach(aliLines, id: \.self) { line in
                LineBadge(line: line, vm: vm, size: size)
            }
        }
    }
}

// MARK: - Lines Content

private struct WaterBusLinesContent: View {
    let routes: [WaterBusRoute]
    let vm: WaterBusViewModel
    let appeared: Bool
    let strings: L10n.Strings

    private var groupedRoutes: [(source: String, routes: [WaterBusRoute])] {
        let dict = Dictionary(grouping: routes) { $0.source }
        let order = ["actv", "alilaguna"]
        return dict.sorted { a, b in
            let ia = order.firstIndex(of: a.key) ?? order.count
            let ib = order.firstIndex(of: b.key) ?? order.count
            return ia < ib
        }.map { (source: $0.key, routes: $0.value) }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                Color.clear.frame(height: 100)

                if routes.isEmpty {
                    Text(strings.waterBusNoLines)
                        .font(.system(size: 15))
                        .foregroundColor(Color(.secondaryLabel))
                        .padding(.top, 40)
                } else {
                    var globalIndex = 0
                    ForEach(groupedRoutes, id: \.source) { group in
                        // Section header
                        HStack(spacing: 8) {
                            OperatorLogo(group.source == "actv" ? "logo-actv" : "logo-alilaguna", height: 16)
                            Text(group.source.uppercased())
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .tracking(1)
                            Rectangle()
                                .fill(Color(.separator).opacity(0.3))
                                .frame(height: 0.5)
                        }
                        .foregroundColor(Color(.secondaryLabel))
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 4)

                        ForEach(Array(group.routes.enumerated()), id: \.element.id) { index, route in
                            let animIndex = globalIndex + index
                            NavigationLink(value: route) {
                                WaterBusRouteRow(route: route, vm: vm)
                            }
                            .buttonStyle(.plain)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 10)
                            .animation(.spring(duration: 0.35).delay(Double(animIndex) * 0.02), value: appeared)

                            if index < group.routes.count - 1 {
                                Divider().padding(.leading, 64)
                            }
                        }
                        let _ = { globalIndex += group.routes.count }()
                    }
                }

                Color.clear.frame(height: 120)
            }
        }
    }
}

// MARK: - Route Row

private struct WaterBusRouteRow: View {
    let route: WaterBusRoute
    let vm: WaterBusViewModel

    var body: some View {
        HStack(spacing: 14) {
            LineBadge(line: route.name, vm: vm, size: .medium)
                .frame(minWidth: 44)

            Text(cleanLongName)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.primary)
                .lineLimit(2)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(.tertiaryLabel))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    /// Rimuove le virgolette dock dal longName per una visualizzazione pulita
    private var cleanLongName: String {
        let parts = route.longName
            .components(separatedBy: " - ")
            .map { parseDock(from: $0).name }
        if parts.count == 2, parts[0] == parts[1] {
            return "\(parts[0]) (circolare)"
        }
        return parts.joined(separator: " – ")
    }
}

// MARK: - Capsule Segmented Control

struct CapsuleSegmentedControl<T: Hashable>: View {
    @Binding var selection: T
    let items: [(value: T, label: String, icon: Ph)]
    @Namespace private var ns

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                let isSelected = selection == item.value
                Button {
                    guard !isSelected else { return }
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        selection = item.value
                    }
                } label: {
                    HStack(spacing: 6) {
                        item.icon.duotone
                            .renderingMode(.template)
                            .frame(width: 15, height: 15)

                        Text(item.label)
                            .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                    }
                    .foregroundStyle(isSelected ? .primary : .secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background {
                        if isSelected {
                            Capsule()
                                .fill(.background)
                                .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 1)
                                .shadow(color: .black.opacity(0.04), radius: 1, x: 0, y: 0.5)
                                .matchedGeometryEffect(id: "seg", in: ns)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background {
            Capsule()
                .fill(Color(.systemGray6))
        }
    }
}
