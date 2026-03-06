import SwiftUI
import MapKit

struct WaterBusStopDetailView: View {
    let stop: WaterBusStop
    @Environment(WaterBusViewModel.self) private var vm
    @Environment(LocationManager.self) private var locationManager
    @Environment(\.strings) private var strings
    @State private var selectedDayGroup: DayGroup?
    @State private var filterLine: String?

    var body: some View {
        let allDeps = currentDepartures
        let deps = filteredDepartures(allDeps)

        ScrollView {
            VStack(spacing: 0) {
                // Map header
                mapHeader

                // Stop info
                stopInfoSection

                // Day selector
                daySelector

                // Line filter
                lineFilter(allDeps: allDeps)

                // Departures board
                departuresBoard(deps)
            }
        }
        .navigationTitle(stop.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            // Default to today's day group
            let today = Date()
            selectedDayGroup = stop.departures.keys.first { $0.contains(date: today) }
                ?? stop.departures.keys.sorted().first
        }
    }

    // MARK: - Map Header

    private var mapHeader: some View {
        Map {
            Annotation(stop.name, coordinate: stop.coordinate) {
                ZStack {
                    Circle()
                        .fill(.blue)
                        .frame(width: 28, height: 28)
                    Image(systemName: "ferry.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.white)
                }
            }
        }
        .mapStyle(.standard(pointsOfInterest: .excludingAll))
        .frame(height: 180)
        .allowsHitTesting(false)
    }

    // MARK: - Stop Info

    private var stopInfoSection: some View {
        VStack(spacing: 12) {
            // Lines serving this stop
            HStack(spacing: 8) {
                Image(systemName: "ferry.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.blue)
                Text(strings.waterBusLines)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
                Spacer()
                if let dist = locationManager.formattedDistance(to: stop.coordinate) {
                    Label(dist, systemImage: "location.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }

            // Line badges
            FlowLayout(spacing: 6) {
                ForEach(stop.lines, id: \.self) { line in
                    LineBadge(line: line, vm: vm, size: .medium)
                }
            }

            // Next departures highlight
            let next = vm.nextDepartures(for: stop, count: 3)
            if !next.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(strings.waterBusNextDepartures)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)

                    ForEach(next) { dep in
                        HStack(spacing: 8) {
                            LineBadge(line: dep.line, vm: vm, size: .small)
                            Text(dep.time)
                                .font(.system(size: 17, weight: .semibold, design: .monospaced))
                            Text(dep.headsign)
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                            Spacer()
                            let mins = dep.minutesUntil()
                            Text(mins <= 1 ? "ora" : "\(mins) min")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(mins <= 5 ? Color(hex: "38A169") : .secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding(12)
                .background(Color(hex: "38A169").opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            // Navigate button
            Button {
                openInMaps()
            } label: {
                Label(strings.waterBusNavigate, systemImage: "arrow.triangle.turn.up.right.circle.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.doVeNavigation)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(16)
    }

    // MARK: - Day Selector

    private var daySelector: some View {
        let groups = stop.departures.keys.sorted()

        return ScrollView(.horizontal, showsIndicators: false) {
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
                            .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                            .foregroundStyle(isSelected ? .white : .primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(isSelected ? Color.doVeNavigation : Color(.systemGray5))
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Line Filter

    private func lineFilter(allDeps: [Departure]) -> some View {
        let lines = Set(allDeps.map(\.line)).sorted()
        guard lines.count > 1 else { return AnyView(EmptyView()) }

        return AnyView(
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    Button {
                        withAnimation(.smooth(duration: 0.2)) { filterLine = nil }
                    } label: {
                        Text(strings.waterBusAllLines)
                            .font(.system(size: 12, weight: filterLine == nil ? .semibold : .regular))
                            .foregroundStyle(filterLine == nil ? .white : .primary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(filterLine == nil ? Color.blue : Color(.systemGray5))
                            .clipShape(Capsule())
                    }

                    ForEach(lines, id: \.self) { line in
                        Button {
                            withAnimation(.smooth(duration: 0.2)) { filterLine = line }
                        } label: {
                            LineBadge(line: line, vm: vm, size: .small)
                                .opacity(filterLine == nil || filterLine == line ? 1 : 0.4)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        )
    }

    // MARK: - Departures Board

    private func departuresBoard(_ departures: [Departure]) -> some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(strings.waterBusTime)
                    .frame(width: 55, alignment: .leading)
                Text(strings.waterBusLine)
                    .frame(width: 40, alignment: .center)
                Text(strings.waterBusDirection)
                Spacer()
            }
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))

            // Rows
            if departures.isEmpty {
                Text(strings.waterBusNoDepartures)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .padding(20)
            } else {
                // Group by hour for visual separation
                let grouped = Dictionary(grouping: departures) { dep in
                    String(dep.time.prefix(2))
                }
                let hours = grouped.keys.sorted()

                ForEach(hours, id: \.self) { hour in
                    if let hourDeps = grouped[hour] {
                        // Hour separator
                        HStack {
                            Text("\(hour):00")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.tertiary)
                            Rectangle()
                                .fill(Color(.separator).opacity(0.3))
                                .frame(height: 0.5)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 6)

                        ForEach(hourDeps) { dep in
                            DepartureRow(dep: dep, vm: vm)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private var currentDepartures: [Departure] {
        guard let group = selectedDayGroup else { return [] }
        return stop.departures[group] ?? []
    }

    private func filteredDepartures(_ deps: [Departure]) -> [Departure] {
        guard let line = filterLine else { return deps }
        return deps.filter { $0.line == line }
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

// MARK: - Departure Row

private struct DepartureRow: View {
    let dep: Departure
    let vm: WaterBusViewModel

    var body: some View {
        HStack(spacing: 0) {
            Text(dep.time)
                .font(.system(size: 15, weight: .medium, design: .monospaced))
                .frame(width: 55, alignment: .leading)

            LineBadge(line: dep.line, vm: vm, size: .small)
                .frame(width: 40)

            Text(dep.headsign)
                .font(.system(size: 14))
                .foregroundStyle(.primary)
                .lineLimit(1)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 5)
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
