import SwiftUI

struct ServicesView: View {
    @Environment(\.strings) private var strings
    @Environment(PharmacyViewModel.self) private var pharmacyVM
    @State private var appeared = false
    @State private var showPharmacies = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "building.2.crop.circle")
                        .font(.system(size: 48, weight: .light))
                        .foregroundStyle(Color.doVeAccent)
                        .symbolRenderingMode(.hierarchical)

                    Text(strings.servicesTitle)
                        .font(.custom("Sotoportego-Medium", size: 28))

                    Text(strings.servicesSubtitle)
                        .font(.system(size: 14, weight: .regular, design: .serif))
                        .foregroundStyle(.secondary)
                        .italic()
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.top, 24)
                .padding(.bottom, 36)
                .opacity(appeared ? 1 : 0)
                .scaleEffect(appeared ? 1 : 0.92)
                .animation(.easeOut(duration: 0.8), value: appeared)

                // Services label
                Text(strings.servicesAvailable)
                    .font(.system(size: 11, weight: .medium))
                    .tracking(2)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 12)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.8).delay(0.2), value: appeared)

                // Pharmacy card
                Button {
                    showPharmacies = true
                } label: {
                    ServiceCard(
                        icon: "cross.case.fill",
                        iconColor: Color(hex: "38A169"),
                        title: strings.pharmaciesTitle,
                        subtitle: pharmacySummary,
                        badge: pharmacyBadge
                    )
                }
                .buttonStyle(ServiceCardButtonStyle())
                .padding(.horizontal, 16)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.35), value: appeared)

                // Coming soon
                VStack(spacing: 12) {
                    Text(strings.servicesComingSoon)
                        .font(.system(size: 11, weight: .medium))
                        .tracking(2)
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)

                    comingSoonCard(icon: "drop.fill", color: Color(hex: "4A90B8"), title: strings.serviceAcquaAlta)
                    comingSoonCard(icon: "calendar", color: Color(hex: "8B7BB8"), title: strings.serviceEventi)
                }
                .padding(.top, 28)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.8).delay(0.55), value: appeared)
            }
            .padding(.bottom, 40)
        }
        .navigationTitle(strings.tabServices)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showPharmacies) {
            PharmacyListView()
        }
        .onAppear {
            pharmacyVM.loadData()
            if !appeared {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    appeared = true
                }
            }
        }
    }

    // MARK: - Helpers

    private var pharmacySummary: String {
        let openCount = pharmacyVM.openPharmacies.count
        let total = pharmacyVM.pharmacies.count
        if total == 0 { return "" }
        return strings.pharmaciesOpenCount(openCount, total)
    }

    private var pharmacyBadge: String? {
        let count = pharmacyVM.openPharmacies.count
        return count > 0 ? "\(count)" : nil
    }

    @ViewBuilder
    private func comingSoonCard(icon: String, color: Color, title: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(color.opacity(0.4))
                .frame(width: 40, height: 40)
                .background(color.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.tertiary)

            Spacer()

            Text(strings.comingSoonBadge)
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.5)
                .foregroundStyle(.quaternary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.quaternary.opacity(0.08))
                .clipShape(Capsule())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
    }
}

// MARK: - ServiceCard

struct ServiceCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let badge: String?

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(iconColor)
                .frame(width: 52, height: 52)
                .background(iconColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 14))

            // Text
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.custom("Sotoportego-Medium", size: 20))
                    .foregroundStyle(.primary)

                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Badge + chevron
            HStack(spacing: 8) {
                if let badge {
                    Text(badge)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(minWidth: 24, minHeight: 24)
                        .padding(.horizontal, 4)
                        .background(Color(hex: "38A169"))
                        .clipShape(Circle())
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.background)
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(.quaternary.opacity(0.5), lineWidth: 0.5)
        }
    }
}

// MARK: - Button Style

struct ServiceCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
