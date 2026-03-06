import SwiftUI

struct InfoView: View {
    @Environment(\.strings) private var strings

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {

                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("DoVe")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.doVeAccent)

                    Text(strings.tagline)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)

                // Nizioleto
                InfoSection(
                    title: strings.whatIsNizioleto,
                    icon: "text.quote",
                    content: strings.whatIsNizioletoCont
                )

                // I due sistemi di indirizzamento
                InfoSection(
                    title: strings.twoAddressingSystems,
                    icon: "number",
                    content: strings.twoAddressingSystemsContent
                )

                // Come funziona
                InfoSection(
                    title: strings.howItWorks,
                    icon: "sparkles",
                    content: strings.howItWorksContent
                )

                // Numerazione per sestiere
                VStack(alignment: .leading, spacing: 12) {
                    Text(strings.numberingBySestiere)
                        .font(.headline)

                    let sestieri = Sestiere.allCases.filter { $0 != .giudecca }
                    let tuttiSestieri = sestieri + [.giudecca]
                    AdaptiveGlassContainer {
                        VStack(spacing: 0) {
                            ForEach(tuttiSestieri) { sestiere in
                                HStack {
                                    Text(sestiere.name)
                                        .font(.body)

                                    Spacer()

                                    if sestiere == .giudecca {
                                        Text(strings.islandLabel)
                                            .font(.caption)
                                            .foregroundStyle(.tertiary)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)

                                if sestiere != tuttiSestieri.last {
                                    Divider()
                                        .padding(.leading, 16)
                                }
                            }
                        }
                        .adaptiveGlassEffect(in: RoundedRectangle(cornerRadius: 16))
                    }
                }

                // Toponomastica ordinaria
                VStack(alignment: .leading, spacing: 12) {
                    Text(strings.ordinaryToponymy)
                        .font(.headline)

                    AdaptiveGlassContainer {
                        VStack(spacing: 0) {
                            let allZone = ZonaNormale.isole + ZonaNormale.zoneCentro
                            ForEach(allZone) { zona in
                                HStack {
                                    Text(zona.name)
                                        .font(.body)

                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)

                                if zona.id != allZone.last?.id {
                                    Divider()
                                        .padding(.leading, 16)
                                }
                            }
                        }
                        .adaptiveGlassEffect(in: RoundedRectangle(cornerRadius: 16))
                    }
                }

                // Storia del sistema
                VStack(alignment: .leading, spacing: 20) {
                    Text(strings.historyTitle)
                        .font(.title3.weight(.semibold))

                    InfoSection(
                        title: strings.historyOralTitle,
                        icon: "text.bubble",
                        content: strings.historyOralContent
                    )

                    InfoSection(
                        title: strings.historyNamingTitle,
                        icon: "mappin.and.ellipse",
                        content: strings.historyNamingContent
                    )

                    InfoSection(
                        title: strings.historyNapoleonTitle,
                        icon: "crown",
                        content: strings.historyNapoleonContent
                    )

                    InfoSection(
                        title: strings.historyAustrianTitle,
                        icon: "building.columns",
                        content: strings.historyAustrianContent
                    )
                }

                Spacer()
                    .frame(height: 32)
            }
            .padding(.horizontal, 20)
        }
        .navigationTitle(strings.tabInfo)
        .navigationBarTitleDisplayMode(.large)
        .toolbar(.hidden, for: .tabBar)
    }
}

struct InfoSection: View {
    let title: String
    let icon: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.headline)

            Text(content)
                .font(.body)
                .foregroundStyle(.secondary)
                .lineSpacing(4)
        }
    }
}
