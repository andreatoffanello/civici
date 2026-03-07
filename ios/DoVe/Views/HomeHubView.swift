import SwiftUI
import PhosphorSwift

struct HomeHubView: View {
    @Environment(\.strings) private var strings
    @Environment(PharmacyViewModel.self) private var pharmacyVM
    @Environment(WaterBusViewModel.self) private var waterBusVM
    @Binding var selectedTab: AppTab
    @State private var appeared = false
    @State private var showSettings = false

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // MARK: - Header
                VStack(spacing: 12) {
                    Image("logo-dove-alt")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)

                    Text(strings.homeTagline)
                        .font(.system(size: 15, weight: .regular, design: .serif))
                        .foregroundStyle(.secondary)
                        .italic()
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding(.top, 20)
                .padding(.bottom, 32)
                .opacity(appeared ? 1 : 0)
                .scaleEffect(appeared ? 1 : 0.92)
                .animation(.easeOut(duration: 0.7), value: appeared)

                // MARK: - Feature Cards
                VStack(spacing: 14) {
                    // Civici + Vaporetti
                    HStack(spacing: 14) {
                        Button { selectedTab = .search } label: {
                            CompactSectionCard(
                                icon: .magnifyingGlass,
                                bgIcon: .mapTrifold,
                                bgColor: Color.doVeAccent,
                                title: strings.homeCiviciTitle
                            )
                        }
                        .buttonStyle(CardPressStyle())
                        .staggeredHub(appeared: appeared, index: 0)

                        Button { selectedTab = .waterBus } label: {
                            CompactSectionCard(
                                icon: .boat,
                                bgIcon: .waves,
                                bgColor: Color.doVeNavigation,
                                title: strings.waterBusTitle
                            )
                        }
                        .buttonStyle(CardPressStyle())
                        .staggeredHub(appeared: appeared, index: 1)
                    }

                    // Servizi full-width
                    Button { selectedTab = .services } label: {
                        WideSectionCard(
                            icon: .firstAidKit,
                            bgIcon: .heartbeat,
                            bgColor: Color.doVeServices,
                            title: strings.tabServices,
                            subtitle: pharmacySummary,
                            badge: pharmacyBadge
                        )
                    }
                    .buttonStyle(CardPressStyle())
                    .staggeredHub(appeared: appeared, index: 2)
                }
                .padding(.horizontal, 16)

                // MARK: - Favorite Stops
                if !waterBusVM.favoriteStops.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 6) {
                            Ph.bookmarkSimple.fill
                                .frame(width: 13, height: 13)
                                .foregroundStyle(Color.doVeNavigation)
                            Text(strings.waterBusFavorites)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 4)

                        ForEach(waterBusVM.favoriteStops) { stop in
                            NavigationLink(value: stop) {
                                FavoriteStopCard(stop: stop, vm: waterBusVM)
                            }
                            .buttonStyle(CardPressStyle())
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.5), value: appeared)
                }

                // MARK: - Settings
                Button {
                    showSettings = true
                } label: {
                    HStack(spacing: 12) {
                        Ph.gear.duotone
                            .renderingMode(.template)
                            .frame(width: 18, height: 18)
                            .foregroundStyle(.tertiary)

                        Text(strings.tabSettings)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.quaternary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.top, 24)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.6).delay(0.6), value: appeared)

                // MARK: - Credits
                VStack(spacing: 8) {
                    Link(destination: URL(string: "https://andreatoffanello.com")!) {
                        HStack(spacing: 6) {
                            Text("Crafted in Venice by")
                                .font(.footnote)
                            Image("at-logo")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 16)
                        }
                        .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)

                    Text("v\(appVersion)")
                        .font(.caption2)
                        .foregroundStyle(.quaternary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 20)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.6).delay(0.7), value: appeared)
            }
            .padding(.bottom, 40)
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $showSettings) {
            SettingsView()
        }
        .navigationDestination(for: WaterBusStop.self) { stop in
            WaterBusStopDetailView(stop: stop)
        }
        .onAppear {
            waterBusVM.loadData()
            pharmacyVM.loadData()
            if !appeared {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    appeared = true
                }
            }
        }
    }

    private var pharmacyBadge: String? {
        let count = pharmacyVM.openPharmacies.count
        return count > 0 ? "\(count)" : nil
    }

    private var pharmacySummary: String {
        let count = pharmacyVM.openPharmacies.count
        let total = pharmacyVM.pharmacies.count
        guard total > 0 else { return "" }
        return strings.pharmaciesOpenCount(count, total)
    }
}

// MARK: - Button Style

private struct CardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .brightness(configuration.isPressed ? -0.03 : 0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Wide Section Card (full-width, horizontal layout)

private struct WideSectionCard: View {
    let icon: Ph
    let bgIcon: Ph
    let bgColor: Color
    let title: String
    var subtitle: String = ""
    var badge: String? = nil

    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [bgColor, bgColor.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            bgIcon.duotone
                .frame(width: 60, height: 60)
                .foregroundStyle(.white.opacity(0.1))
                .rotationEffect(.degrees(-10))
                .offset(x: 220, y: 0)

            HStack(spacing: 14) {
                icon.duotone
                    .frame(width: 22, height: 22)
                    .foregroundStyle(.white)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)

                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.75))
                    }
                }

                Spacer()

                if let badge {
                    Text(badge)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(bgColor)
                        .frame(minWidth: 24, minHeight: 24)
                        .padding(.horizontal, 4)
                        .background(.white)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: bgColor.opacity(0.3), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Compact Section Card (half-width, fully colored)

private struct CompactSectionCard: View {
    let icon: Ph
    let bgIcon: Ph
    let bgColor: Color
    let title: String
    var badge: String? = nil

    var body: some View {
        ZStack(alignment: .leading) {
            // Background gradient
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [bgColor, bgColor.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            // Decorative oversized icon
            bgIcon.duotone
                .frame(width: 72, height: 72)
                .foregroundStyle(.white.opacity(0.1))
                .rotationEffect(.degrees(15))
                .offset(x: 50, y: 30)

            // Content
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    icon.duotone
                        .frame(width: 22, height: 22)
                        .foregroundStyle(.white)

                    Spacer()

                    if let badge {
                        Text(badge)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(bgColor)
                            .frame(minWidth: 22, minHeight: 22)
                            .padding(.horizontal, 3)
                            .background(.white)
                            .clipShape(Circle())
                    }
                }

                Text(title)
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(.white)
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .leading)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: bgColor.opacity(0.3), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Favorite Stop Card

private struct FavoriteStopCard: View {
    let stop: WaterBusStop
    let vm: WaterBusViewModel

    var body: some View {
        let next = vm.nextDepartures(for: stop, count: 3)

        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack(spacing: 8) {
                Ph.boat.fill
                    .frame(width: 14, height: 14)
                    .foregroundStyle(Color.doVeNavigation)

                Text(stop.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 11))
                    .foregroundStyle(.quaternary)
            }

            // Departures
            if next.isEmpty {
                Text("Nessuna partenza prevista")
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(next.enumerated()), id: \.element.id) { index, dep in
                        HStack(spacing: 6) {
                            LineBadge(line: dep.line, vm: vm, size: .small)
                            Text(dep.time)
                                .font(.system(size: 14, weight: .medium, design: .monospaced))
                                .foregroundStyle(.primary)
                            Spacer()
                            if dep.isImminent {
                                Circle()
                                    .fill(Color.doVeSoon)
                                    .frame(width: 5, height: 5)
                                    .modifier(PulseModifier())
                            }
                            Text(dep.countdownLabel)
                                .font(.system(size: 12, weight: dep.isSoon ? .bold : .medium))
                                .foregroundStyle(dep.isSoon ? Color.doVeSoon : .secondary)
                        }
                        .padding(.vertical, 5)

                        if index < next.count - 1 {
                            Divider()
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Staggered Animation

private extension View {
    func staggeredHub(appeared: Bool, index: Int) -> some View {
        self
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 16)
            .scaleEffect(appeared ? 1 : 0.96)
            .animation(
                .spring(response: 0.55, dampingFraction: 0.78)
                    .delay(0.25 + Double(index) * 0.12),
                value: appeared
            )
    }
}
