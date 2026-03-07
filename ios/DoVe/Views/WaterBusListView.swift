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
                        userLocation: locationManager.userLocation,
                        locationManager: locationManager
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
                Picker("", selection: $contentMode) {
                    Text(strings.waterBusStops).tag(ContentMode.stops)
                    Text(strings.waterBusLines).tag(ContentMode.lines)
                }
                .pickerStyle(.segmented)
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
                            toggleButton(icon: "map.fill", mode: .map)
                            toggleButton(icon: "list.bullet", mode: .list)
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

    private func toggleButton(icon: String, mode: ViewMode) -> some View {
        Button {
            withAnimation(.smooth(duration: 0.2)) { viewMode = mode }
        } label: {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
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
                    Annotation("", coordinate: stop.coordinate) {
                        WaterBusStopPin(
                            stop: stop,
                            isSelected: selectedStop?.id == stop.id
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
            .onTapGesture {
                if selectedStop != nil {
                    withAnimation(.spring(duration: 0.25)) {
                        selectedStop = nil
                    }
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
                            .frame(width: 44, height: 44)
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

// MARK: - Stop Map Pin

private struct WaterBusStopPin: View {
    let stop: WaterBusStop
    let isSelected: Bool

    /// Pin size scales with number of lines (importance of the hub)
    private var dotSize: CGFloat {
        if isSelected { return 30 }
        let count = stop.lines.count
        switch count {
        case 0...2: return 14
        case 3...5: return 17
        default:    return 20
        }
    }

    private var innerSize: CGFloat {
        isSelected ? 12 : dotSize * 0.4
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(.white)
                .frame(width: dotSize, height: dotSize)

            Circle()
                .fill(Color.doVeNavigation)
                .frame(width: dotSize - 3, height: dotSize - 3)

            Circle()
                .fill(.white)
                .frame(width: innerSize, height: innerSize)
        }
        .shadow(color: .black.opacity(0.2), radius: isSelected ? 5 : 2.5, y: isSelected ? 2 : 1)
        .animation(.spring(duration: 0.2), value: isSelected)
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
            VStack(alignment: .leading, spacing: 10) {
                // Name + distance
                HStack(spacing: 10) {
                    Image(systemName: "ferry.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.doVeNavigation)

                    Text(stop.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Spacer()

                    if let dist = locationManager.formattedDistance(to: stop.coordinate) {
                        Text(dist)
                            .font(.system(size: 13))
                            .foregroundColor(Color(.secondaryLabel))
                    }

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(.tertiaryLabel))
                }

                // Lines badges
                ScrollView(.horizontal, showsIndicators: false) {
                    GroupedLineBadges(stop: stop, vm: vm, size: .small)
                }

                // Next departures
                let next = vm.nextDepartures(for: stop, count: 3)
                if !next.isEmpty {
                    HStack(spacing: 14) {
                        ForEach(next) { dep in
                            HStack(spacing: 5) {
                                LineBadge(line: dep.line, vm: vm, size: .small)
                                VStack(alignment: .leading, spacing: 0) {
                                    Text(dep.time)
                                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                                        .foregroundStyle(.primary)
                                    Text(dep.countdownLabel)
                                        .font(.system(size: 11))
                                        .foregroundStyle(dep.isSoon ? AnyShapeStyle(Color(hex: "38A169")) : AnyShapeStyle(Color(.secondaryLabel)))
                                }
                            }
                        }
                        Spacer()
                    }
                }
            }
            .padding(16)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
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
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 28))
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

                    ForEach(Array(results.enumerated()), id: \.element.id) { index, stop in
                        NavigationLink(value: stop) {
                            WaterBusStopRow(
                                stop: stop,
                                vm: vm,
                                locationManager: locationManager,
                                highlightQuery: isSearching ? vm.searchText : nil
                            )
                        }
                        .buttonStyle(.plain)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 10)
                        .animation(
                            .spring(duration: 0.35).delay(Double(min(index, 15)) * 0.02),
                            value: appeared
                        )

                        if index < results.count - 1 {
                            Divider().padding(.leading, 56)
                        }
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
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.doVeNavigation.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: "ferry.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.doVeNavigation)
            }

            VStack(alignment: .leading, spacing: 5) {
                highlightedName
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(1)

                // Line badges
                GroupedLineBadges(stop: stop, vm: vm, size: .small, maxLines: 6)

                // Next departure
                let next = vm.nextDepartures(for: stop, count: 1)
                if let dep = next.first {
                    HStack(spacing: 5) {
                        if dep.isImminent {
                            Circle()
                                .fill(Color(hex: "38A169"))
                                .frame(width: 6, height: 6)
                                .modifier(PulseModifier())
                        } else {
                            Image(systemName: "clock")
                                .font(.system(size: 11))
                        }
                        Text(dep.time)
                            .foregroundColor(dep.isSoon ? Color(hex: "38A169") : Color(.secondaryLabel))
                        Text(dep.countdownLabel)
                            .foregroundStyle(dep.isSoon ? AnyShapeStyle(Color(hex: "38A169")) : AnyShapeStyle(Color(.secondaryLabel)))
                    }
                    .font(.system(size: 12, weight: dep.isSoon ? .semibold : .regular))
                }
            }

            Spacer()

            // Distance
            if let dist = locationManager.formattedDistance(to: stop.coordinate) {
                Text(dist)
                    .font(.system(size: 12))
                    .foregroundColor(Color(.secondaryLabel))
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(.tertiaryLabel))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
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

// MARK: - Dock Badge (imbarcadero — sfondo giallo, testo nero, come segnaletica veneziana)

struct DockBadge: View {
    let letter: String
    let size: DockSize

    enum DockSize {
        case small, medium

        var fontSize: CGFloat {
            switch self {
            case .small: 10
            case .medium: 12
            }
        }

        var minWidth: CGFloat {
            switch self {
            case .small: 16
            case .medium: 20
            }
        }
    }

    var body: some View {
        Text(letter)
            .font(.system(size: size.fontSize, weight: .heavy, design: .rounded))
            .foregroundStyle(.black)
            .frame(minWidth: size.minWidth)
            .padding(.horizontal, 3)
            .padding(.vertical, 2)
            .background(Color(red: 1.0, green: 0.82, blue: 0.0))
            .clipShape(RoundedRectangle(cornerRadius: 3))
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
                            Image(group.source == "actv" ? "logo-actv" : "logo-alilaguna")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 16)
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

            VStack(alignment: .leading, spacing: 4) {
                if route.directions.count == 2 {
                    VStack(alignment: .leading, spacing: 2) {
                        headsignRow(route.directions[0].headsign, color: .primary)
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.arrow.down")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(Color(.tertiaryLabel))
                            headsignRow(route.directions[1].headsign, color: Color(.secondaryLabel))
                        }
                    }
                    .font(.system(size: 14, weight: .medium))
                } else if let dir = route.directions.first {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Color(.secondaryLabel))
                        headsignRow(dir.headsign, color: .primary)
                    }
                    .font(.system(size: 14, weight: .medium))
                } else {
                    Text(route.longName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(.tertiaryLabel))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func headsignRow(_ headsign: String, color: Color) -> some View {
        let parsed = parseDock(from: headsign)
        HStack(spacing: 4) {
            Text(parsed.name)
                .lineLimit(1)
                .foregroundColor(color)
            if let dock = parsed.dock {
                DockBadge(letter: dock, size: .small)
            }
        }
    }
}
