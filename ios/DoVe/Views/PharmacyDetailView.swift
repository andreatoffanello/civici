import SwiftUI
import MapKit
import PhosphorSwift

struct PharmacyDetailView: View {
    let pharmacy: Pharmacy
    @Environment(LocationManager.self) private var locationManager
    @Environment(\.strings) private var strings
    @AppStorage("preferredNavApp") private var preferredNavApp: String = PreferredNavApp.alwaysAsk.rawValue
    @State private var mapPosition: MapCameraPosition
    @State private var showNavSheet = false
    @State private var appeared = false

    init(pharmacy: Pharmacy) {
        self.pharmacy = pharmacy
        let region = MKCoordinateRegion(
            center: pharmacy.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.004, longitudeDelta: 0.004)
        )
        _mapPosition = State(initialValue: .region(region))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Map
            Map(position: $mapPosition, interactionModes: [.pan, .zoom, .rotate]) {
                Annotation(pharmacy.name, coordinate: pharmacy.coordinate) {
                    pharmacyMarker
                }

                if let location = locationManager.userLocation {
                    Annotation("", coordinate: location.coordinate) {
                        Circle()
                            .fill(.blue)
                            .frame(width: 12, height: 12)
                            .overlay {
                                Circle()
                                    .stroke(.white, lineWidth: 2)
                            }
                            .shadow(color: .blue.opacity(0.3), radius: 4)
                    }
                }
            }
            .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .including([.pharmacy])))
            .ignoresSafeArea(edges: .top)

            // Bottom card
            pharmacyCard
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 40)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2), value: appeared)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        .confirmationDialog(
            strings.openNavigationWith,
            isPresented: $showNavSheet,
            titleVisibility: .visible
        ) {
            navigationDialogButtons
        }
        .onAppear {
            locationManager.startUpdating()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                appeared = true
            }
        }
    }

    // MARK: - Pharmacy Marker

    private var pharmacyMarker: some View {
        VStack(spacing: 0) {
            VStack(spacing: 2) {
                Ph.firstAidKit.duotone
                    .renderingMode(.template)
                    .frame(width: 18, height: 18)
                    .foregroundStyle(pharmacy.isOpen() ? Color.doVeServices : Color(hex: "E53E3E"))

                if let distance = locationManager.formattedDistance(to: pharmacy.coordinate) {
                    Text(distance)
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.regularMaterial)
                    .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
            }

            // Arrow
            Triangle()
                .fill(.regularMaterial)
                .frame(width: 12, height: 6)
                .shadow(color: .black.opacity(0.08), radius: 2, y: 2)
        }
    }

    // MARK: - Bottom Card

    private var pharmacyCard: some View {
        VStack(spacing: 0) {
            // Drag indicator
            Capsule()
                .fill(.quaternary)
                .frame(width: 36, height: 4)
                .padding(.top, 10)
                .padding(.bottom, 14)

            // Name and status
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(pharmacy.name)
                        .font(.system(size: 22, weight: .bold))

                    Text(pharmacy.address)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Status badge
                statusBadge
            }
            .padding(.horizontal, 20)

            // Info rows
            VStack(spacing: 0) {
                // Hours
                infoRow(
                    icon: .clock,
                    title: strings.pharmacyHoursLabel,
                    value: pharmacy.nextOpeningDescription(strings: strings)
                )

                Divider().padding(.leading, 52)

                // Phone
                infoRow(
                    icon: .phone,
                    title: strings.pharmacyPhoneLabel,
                    value: pharmacy.phone
                )

                Divider().padding(.leading, 52)

                // Area
                infoRow(
                    icon: .mapPin,
                    title: strings.pharmacyAreaLabel,
                    value: pharmacy.areaName
                )
            }
            .padding(.top, 16)

            // Action buttons
            HStack(spacing: 12) {
                // Call button
                Button {
                    callPharmacy()
                } label: {
                    HStack(spacing: 6) {
                        Ph.phone.fill
                            .frame(width: 16, height: 16)
                        Text(strings.pharmacyCall)
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.secondary.opacity(0.1))
                    .foregroundStyle(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                // Navigate button
                Button {
                    navigateToPharmacy()
                } label: {
                    HStack(spacing: 6) {
                        Ph.navigationArrow.fill
                            .frame(width: 16, height: 16)
                        Text(strings.navigate)
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.doVeAccent)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 8)
        }
        .padding(.bottom, 16)
        .background {
            RoundedRectangle(cornerRadius: 24)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.08), radius: 16, y: -4)
                .ignoresSafeArea(edges: .bottom)
        }
    }

    private var statusBadge: some View {
        let isOpen = pharmacy.isOpen()
        return HStack(spacing: 5) {
            Circle()
                .fill(isOpen ? Color.doVeServices : Color(hex: "E53E3E"))
                .frame(width: 7, height: 7)
            Text(isOpen ? strings.pharmacyOpen : strings.pharmacyClosed)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(isOpen ? Color.doVeServices : Color(hex: "E53E3E"))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background((isOpen ? Color.doVeServices : Color(hex: "E53E3E")).opacity(0.1))
        .clipShape(Capsule())
    }

    @ViewBuilder
    private func infoRow(icon: Ph, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            icon.duotone
                .renderingMode(.template)
                .frame(width: 16, height: 16)
                .foregroundStyle(.secondary)
                .frame(width: 28, alignment: .center)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.tertiary)
                    .textCase(.uppercase)
                    .tracking(0.5)

                Text(value)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.primary)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    // MARK: - Actions

    private func callPharmacy() {
        let cleaned = pharmacy.phone.replacingOccurrences(of: " ", with: "")
        if let url = URL(string: "tel:\(cleaned)") {
            UIApplication.shared.open(url)
        }
    }

    private func navigateToPharmacy() {
        let navPref = PreferredNavApp(rawValue: preferredNavApp) ?? .alwaysAsk
        switch navPref {
        case .alwaysAsk:
            showNavSheet = true
        case .appleMaps:
            openAppleMaps()
        case .googleMaps:
            openGoogleMaps()
        case .waze:
            openWaze()
        }
    }

    @ViewBuilder
    private var navigationDialogButtons: some View {
        Button("Apple Maps") { openAppleMaps() }
        Button("Google Maps") { openGoogleMaps() }
        Button("Waze") { openWaze() }
        Button(strings.cancel, role: .cancel) {}
    }

    private func openAppleMaps() {
        let placemark = MKPlacemark(coordinate: pharmacy.coordinate)
        let item = MKMapItem(placemark: placemark)
        item.name = pharmacy.name
        item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking])
    }

    private func openGoogleMaps() {
        let urlStr = "comgooglemaps://?daddr=\(pharmacy.coordinate.latitude),\(pharmacy.coordinate.longitude)&directionsmode=walking"
        if let url = URL(string: urlStr), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            openAppleMaps()
        }
    }

    private func openWaze() {
        let urlStr = "waze://?ll=\(pharmacy.coordinate.latitude),\(pharmacy.coordinate.longitude)&navigate=yes"
        if let url = URL(string: urlStr), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            openAppleMaps()
        }
    }
}
