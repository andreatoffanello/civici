import SwiftUI
import MapKit
import CoreLocation

// MARK: - Main View with Map/List Toggle

struct PharmacyListView: View {
    @Environment(PharmacyViewModel.self) private var pharmacyVM
    @Environment(LocationManager.self) private var locationManager
    @Environment(\.strings) private var strings
    @State private var viewMode: ViewMode = .map
    @State private var appeared = false
    @State private var selectedPharmacy: Pharmacy?

    enum ViewMode: String {
        case map, list
    }

    var body: some View {
        let sorted = pharmacyVM.sortedForDisplay(from: locationManager.userLocation)

        ZStack(alignment: .top) {
            // Content
            switch viewMode {
            case .map:
                PharmacyMapView(
                    pharmacies: pharmacyVM.pharmacies,
                    userLocation: locationManager.userLocation,
                    selectedPharmacy: $selectedPharmacy,
                    locationManager: locationManager,
                    strings: strings
                )
                .ignoresSafeArea(edges: .bottom)
            case .list:
                PharmacyListContent(
                    sorted: sorted,
                    total: pharmacyVM.pharmacies.count,
                    appeared: appeared,
                    locationManager: locationManager,
                    strings: strings
                )
            }

            // Top overlay: status + toggle
            VStack(spacing: 0) {
                // Status bar
                HStack {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(sorted.open.count > 0 ? Color(hex: "38A169") : Color(hex: "E53E3E"))
                            .frame(width: 8, height: 8)
                        Text(sorted.open.count > 0
                             ? strings.pharmaciesOpenCount(sorted.open.count, pharmacyVM.pharmacies.count)
                             : strings.pharmaciesAllClosed)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.primary)
                    }

                    Spacer()

                    // Toggle
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
        .navigationTitle(strings.pharmaciesTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .navigationDestination(for: Pharmacy.self) { pharmacy in
            PharmacyDetailView(pharmacy: pharmacy)
        }
        .onAppear {
            locationManager.startUpdating()
            if !appeared {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    appeared = true
                }
            }
        }
    }

    @ViewBuilder
    private func toggleButton(icon: String, mode: ViewMode) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewMode = mode
            }
        } label: {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(viewMode == mode ? .white : .secondary)
                .frame(width: 34, height: 30)
                .background(viewMode == mode ? Color.doVeAccent : .clear)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .padding(2)
    }
}

// MARK: - Map View

struct PharmacyMapView: View {
    let pharmacies: [Pharmacy]
    let userLocation: CLLocation?
    @Binding var selectedPharmacy: Pharmacy?
    let locationManager: LocationManager
    let strings: L10n.Strings

    @State private var mapPosition: MapCameraPosition
    @State private var showDetail = false

    private static let veniceCenter = CLLocationCoordinate2D(latitude: 45.4371, longitude: 12.3326)

    init(pharmacies: [Pharmacy], userLocation: CLLocation?, selectedPharmacy: Binding<Pharmacy?>, locationManager: LocationManager, strings: L10n.Strings) {
        self.pharmacies = pharmacies
        self.userLocation = userLocation
        self._selectedPharmacy = selectedPharmacy
        self.locationManager = locationManager
        self.strings = strings

        let center = userLocation?.coordinate ?? Self.veniceCenter
        let region = MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: 0.025, longitudeDelta: 0.025)
        )
        _mapPosition = State(initialValue: .region(region))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(position: $mapPosition, interactionModes: [.pan, .zoom, .rotate]) {
                // User location
                if let location = userLocation {
                    Annotation("", coordinate: location.coordinate) {
                        Circle()
                            .fill(.blue)
                            .frame(width: 14, height: 14)
                            .overlay {
                                Circle().stroke(.white, lineWidth: 2.5)
                            }
                            .shadow(color: .blue.opacity(0.3), radius: 4)
                    }
                }

                // Pharmacy markers
                ForEach(pharmacies) { pharmacy in
                    Annotation(pharmacy.name, coordinate: pharmacy.coordinate) {
                        PharmacyMapPin(
                            pharmacy: pharmacy,
                            isSelected: selectedPharmacy?.id == pharmacy.id
                        )
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3)) {
                                selectedPharmacy = pharmacy
                            }
                        }
                    }
                }
            }
            .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .excluding([.pharmacy])))

            // Center on user button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        withAnimation {
                            let center = userLocation?.coordinate ?? Self.veniceCenter
                            mapPosition = .region(MKCoordinateRegion(
                                center: center,
                                span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
                            ))
                        }
                    } label: {
                        Image(systemName: "location.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.primary)
                            .frame(width: 40, height: 40)
                            .background(.regularMaterial)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.12), radius: 6, y: 2)
                    }
                    .padding(.trailing, 16)
                    .padding(.bottom, selectedPharmacy != nil ? 220 : 16)
                }
            }

            // Bottom card for selected pharmacy
            if let pharmacy = selectedPharmacy {
                PharmacyMapCard(
                    pharmacy: pharmacy,
                    locationManager: locationManager,
                    strings: strings,
                    onDismiss: {
                        withAnimation(.spring(response: 0.3)) {
                            selectedPharmacy = nil
                        }
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onTapGesture {
            if selectedPharmacy != nil {
                withAnimation(.spring(response: 0.3)) {
                    selectedPharmacy = nil
                }
            }
        }
    }
}

// MARK: - Map Pin

struct PharmacyMapPin: View {
    let pharmacy: Pharmacy
    let isSelected: Bool

    var body: some View {
        let isOpen = pharmacy.isOpen()
        let color = isOpen ? Color(hex: "38A169") : Color(hex: "E53E3E")

        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: isSelected ? 36 : 28, height: isSelected ? 36 : 28)
                    .shadow(color: color.opacity(0.4), radius: isSelected ? 6 : 3, y: 2)

                Image(systemName: "cross.case.fill")
                    .font(.system(size: isSelected ? 16 : 12, weight: .medium))
                    .foregroundStyle(.white)
            }
            .animation(.spring(response: 0.3), value: isSelected)

            // Pin point
            Triangle()
                .fill(color)
                .frame(width: 10, height: 5)
        }
    }
}

// MARK: - Map Card (selected pharmacy)

struct PharmacyMapCard: View {
    let pharmacy: Pharmacy
    let locationManager: LocationManager
    let strings: L10n.Strings
    let onDismiss: () -> Void

    var body: some View {
        let isOpen = pharmacy.isOpen()

        NavigationLink(value: pharmacy) {
            VStack(spacing: 0) {
                // Drag indicator
                Capsule()
                    .fill(.quaternary)
                    .frame(width: 36, height: 4)
                    .padding(.top, 10)
                    .padding(.bottom, 12)

                HStack(spacing: 14) {
                    // Icon
                    VStack(spacing: 4) {
                        Image(systemName: "cross.case.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(isOpen ? Color(hex: "38A169") : Color.gray.opacity(0.5))
                            .frame(width: 44, height: 44)
                            .background(isOpen ? Color(hex: "38A169").opacity(0.1) : Color.secondary.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // Content
                    VStack(alignment: .leading, spacing: 4) {
                        Text(pharmacy.name)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        Text(pharmacy.address)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)

                        HStack(spacing: 8) {
                            Text(isOpen ? strings.pharmacyOpen : strings.pharmacyClosed)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(isOpen ? Color(hex: "38A169") : Color(hex: "E53E3E"))

                            if let hours = pharmacy.todayHoursFormatted() {
                                Text(hours)
                                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                                    .foregroundStyle(.tertiary)
                            }

                            if let distance = locationManager.formattedDistance(to: pharmacy.coordinate) {
                                Text("·").foregroundStyle(.quaternary)
                                Text(distance)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }

                    Spacer(minLength: 4)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.quaternary)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .buttonStyle(.plain)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.1), radius: 12, y: -4)
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }
}

// MARK: - List Content (extracted from previous full list)

struct PharmacyListContent: View {
    let sorted: (open: [Pharmacy], closed: [Pharmacy])
    let total: Int
    let appeared: Bool
    let locationManager: LocationManager
    let strings: L10n.Strings

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Spacer for the top overlay
                Spacer().frame(height: 52)

                // Open pharmacies
                if !sorted.open.isEmpty {
                    sectionLabel(strings.pharmaciesOpenNow)
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeOut(duration: 0.6).delay(0.1), value: appeared)

                    VStack(spacing: 0) {
                        ForEach(Array(sorted.open.enumerated()), id: \.element.id) { index, pharmacy in
                            let delay = 0.15 + Double(index) * 0.06

                            NavigationLink(value: pharmacy) {
                                PharmacyRow(
                                    pharmacy: pharmacy,
                                    isOpen: true,
                                    distance: locationManager.formattedDistance(to: pharmacy.coordinate),
                                    strings: strings
                                )
                            }
                            .buttonStyle(PharmacyRowButtonStyle())
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 8)
                            .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(delay), value: appeared)

                            if index < sorted.open.count - 1 {
                                Divider().padding(.leading, 76)
                            }
                        }
                    }
                }

                // Closed pharmacies
                if !sorted.closed.isEmpty {
                    sectionLabel(strings.pharmaciesClosedNow)
                        .padding(.top, sorted.open.isEmpty ? 0 : 24)
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeOut(duration: 0.6).delay(0.3), value: appeared)

                    VStack(spacing: 0) {
                        ForEach(Array(sorted.closed.enumerated()), id: \.element.id) { index, pharmacy in
                            let delay = 0.35 + Double(index) * 0.04

                            NavigationLink(value: pharmacy) {
                                PharmacyRow(
                                    pharmacy: pharmacy,
                                    isOpen: false,
                                    distance: locationManager.formattedDistance(to: pharmacy.coordinate),
                                    strings: strings
                                )
                            }
                            .buttonStyle(PharmacyRowButtonStyle())
                            .opacity(appeared ? 1 : 0)
                            .animation(.easeOut(duration: 0.5).delay(delay), value: appeared)

                            if index < sorted.closed.count - 1 {
                                Divider().padding(.leading, 76)
                            }
                        }
                    }
                }
            }
            .padding(.bottom, 40)
        }
    }

    @ViewBuilder
    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .tracking(2)
            .foregroundStyle(.tertiary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
    }
}

// MARK: - PharmacyRow

struct PharmacyRow: View {
    let pharmacy: Pharmacy
    let isOpen: Bool
    let distance: String?
    let strings: L10n.Strings

    var body: some View {
        HStack(spacing: 14) {
            VStack(spacing: 4) {
                Image(systemName: "cross.case.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(isOpen ? Color(hex: "38A169") : Color.gray.opacity(0.5))
                    .frame(width: 44, height: 44)
                    .background(isOpen ? Color(hex: "38A169").opacity(0.1) : Color.secondary.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.leading, 16)

            VStack(alignment: .leading, spacing: 4) {
                Text(pharmacy.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(pharmacy.address)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(isOpen ? strings.pharmacyOpen : strings.pharmacyClosed)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(isOpen ? Color(hex: "38A169") : Color(hex: "E53E3E"))

                    if let hours = pharmacy.todayHoursFormatted() {
                        Text(hours)
                            .font(.system(size: 11, weight: .regular, design: .monospaced))
                            .foregroundStyle(.tertiary)
                    }

                    if let distance {
                        Text("·").foregroundStyle(.quaternary)
                        Text(distance)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Spacer(minLength: 4)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.quaternary)
                .padding(.trailing, 16)
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

struct PharmacyRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Color.primary.opacity(0.04) : .clear)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
