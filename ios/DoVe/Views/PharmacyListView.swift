import SwiftUI
import CoreLocation

struct PharmacyListView: View {
    @Environment(PharmacyViewModel.self) private var pharmacyVM
    @Environment(LocationManager.self) private var locationManager
    @Environment(\.strings) private var strings
    @State private var appeared = false

    var body: some View {
        let sorted = pharmacyVM.sortedForDisplay(from: locationManager.userLocation)

        ScrollView {
            VStack(spacing: 0) {
                // Status header
                pharmacyStatusHeader(openCount: sorted.open.count, total: pharmacyVM.pharmacies.count)
                    .padding(.top, 8)
                    .padding(.bottom, 20)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.6), value: appeared)

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
                                Divider()
                                    .padding(.leading, 76)
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
                                Divider()
                                    .padding(.leading, 76)
                            }
                        }
                    }
                }
            }
            .padding(.bottom, 40)
        }
        .navigationTitle(strings.pharmaciesTitle)
        .navigationBarTitleDisplayMode(.inline)
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

    // MARK: - Subviews

    @ViewBuilder
    private func pharmacyStatusHeader(openCount: Int, total: Int) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Circle()
                    .fill(openCount > 0 ? Color(hex: "38A169") : Color(hex: "E53E3E"))
                    .frame(width: 8, height: 8)

                Text(openCount > 0 ? strings.pharmaciesOpenCount(openCount, total) : strings.pharmaciesAllClosed)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Text(currentTimeFormatted)
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundStyle(.tertiary)
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

    private var currentTimeFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: Date())
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
            // Status indicator
            VStack(spacing: 4) {
                Image(systemName: "cross.case.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(isOpen ? Color(hex: "38A169") : Color.gray.opacity(0.5))
                    .frame(width: 44, height: 44)
                    .background(isOpen ? Color(hex: "38A169").opacity(0.1) : Color.secondary.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.leading, 16)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(pharmacy.name)
                    .font(.custom("Sotoportego-Medium", size: 17))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(pharmacy.address)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    // Open/closed badge
                    Text(isOpen ? strings.pharmacyOpen : strings.pharmacyClosed)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(isOpen ? Color(hex: "38A169") : Color(hex: "E53E3E"))

                    // Today hours
                    if let hours = pharmacy.todayHoursFormatted() {
                        Text(hours)
                            .font(.system(size: 11, weight: .regular, design: .monospaced))
                            .foregroundStyle(.tertiary)
                    }

                    // Distance
                    if let distance {
                        Text("·")
                            .foregroundStyle(.quaternary)
                        Text(distance)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Spacer(minLength: 4)

            // Chevron
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
