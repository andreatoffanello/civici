import SwiftUI
import MapKit

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

    var body: some View {
        Map(position: $mapPosition) {
            Annotation(stop.name, coordinate: stop.coordinate) {
                ZStack {
                    Circle()
                        .fill(Color.doVeNavigation)
                        .frame(width: 28, height: 28)
                    Image(systemName: "ferry.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.white)
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
        .navigationTitle(stop.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    withAnimation(.spring(duration: 0.3)) {
                        vm.toggleFavorite(stop)
                    }
                } label: {
                    Image(systemName: vm.isFavorite(stop) ? "star.fill" : "star")
                        .foregroundStyle(vm.isFavorite(stop) ? .yellow : .secondary)
                        .symbolEffect(.bounce, value: vm.isFavorite(stop))
                }
            }
        }
        .onAppear {
            mapPosition = .region(MKCoordinateRegion(
                center: stop.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.006, longitudeDelta: 0.006)
            ))
            showSheet = true
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

    // MARK: - Sheet Content

    private var sheetContent: some View {
        let next = vm.nextDepartures(for: stop, count: 5)

        return ScrollView {
            VStack(spacing: 0) {
                peekHeader
                linesSection

                if !next.isEmpty {
                    nextDeparturesSection(next)
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "ferry")
                            .font(.system(size: 28))
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
                            Image(systemName: "calendar.badge.clock")
                                .font(.system(size: 14))
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
        .fullScreenCover(isPresented: $showFullSchedule) {
            FullScheduleView(stop: stop)
        }
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
                Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(Color.doVeNavigation)
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
                    Image("logo-actv")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 18)
                    FlowLayout(spacing: 6) {
                        ForEach(groups.actv, id: \.self) { line in
                            LineBadge(line: line, vm: vm, size: .small)
                        }
                    }
                }
            }
            if hasAlilaguna {
                HStack(spacing: 8) {
                    Image("logo-alilaguna")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 18)
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

                HStack(spacing: 0) {
                    // Countdown
                    HStack(spacing: 4) {
                        if dep.isImminent {
                            Circle()
                                .fill(Color(hex: "38A169"))
                                .frame(width: 6, height: 6)
                                .modifier(PulseModifier())
                        }
                        Text(dep.countdownLabel)
                            .font(.system(size: isFirst ? 16 : 14, weight: isFirst ? .bold : .semibold))
                            .foregroundStyle(dep.isSoon ? Color(hex: "38A169") : .primary)
                    }
                    .frame(width: 110, alignment: .leading)

                    LineBadge(line: dep.line, vm: vm, size: .small)
                        .padding(.trailing, 10)

                    let parsed = parseDock(from: dep.headsign)
                    Text(parsed.name)
                        .font(.system(size: isFirst ? 14 : 13))
                        .foregroundStyle(isFirst ? .primary : .secondary)
                        .lineLimit(1)

                    Spacer(minLength: 8)

                    Text(dep.time)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(Color(.secondaryLabel))

                    if let dock = parsed.dock {
                        DockBadge(letter: dock, size: .small)
                            .padding(.leading, 6)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, isFirst ? 14 : 10)

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

    // MARK: - Helpers

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
                    Image(systemName: "ferry")
                        .font(.system(size: 28))
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

                                if let depDock = depParsed.dock {
                                    DockBadge(letter: depDock, size: .small)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 6)
                        }
                    }
                }

                Color.clear.frame(height: 40)
            }
        }
    }
}

// MARK: - Flow Layout

private struct FlowLayout: Layout {
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
