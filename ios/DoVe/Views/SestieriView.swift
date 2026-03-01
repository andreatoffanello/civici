import SwiftUI

struct SestieriView: View {
    @Environment(SearchViewModel.self) private var viewModel
    @Environment(\.strings) private var strings
    @State private var appeared = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    Image("logo-dove-alt")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)

                    Text(strings.tagline)
                        .font(.system(size: 15, weight: .regular, design: .serif))
                        .foregroundStyle(.secondary)
                        .italic()
                }
                .padding(.top, 16)
                .padding(.bottom, 28)
                .opacity(appeared ? 1 : 0)
                .scaleEffect(appeared ? 1 : 0.92)
                .animation(.easeOut(duration: 1.0), value: appeared)

                // Label
                Text(strings.selectSestiere)
                    .font(.system(size: 11, weight: .medium))
                    .tracking(2)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 8)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.8).delay(0.2), value: appeared)

                // Sestieri list
                VStack(spacing: 0) {
                    ForEach(Array(Sestiere.allCases.enumerated()), id: \.element) { index, sestiere in
                        let delay = 0.25 + Double(index) * 0.1

                        SestiereCard(
                            sestiere: sestiere,
                            action: { viewModel.selectSestiere(sestiere) },
                            appeared: appeared,
                            animationDelay: delay
                        )

                        if sestiere != Sestiere.allCases.last {
                            Divider()
                                .padding(.leading, 24)
                                .opacity(appeared ? 1 : 0)
                                .animation(.easeOut(duration: 0.4).delay(delay + 0.2), value: appeared)
                        }
                    }
                }

                // Zone centro storico label
                Text(strings.otherAreas)
                    .font(.system(size: 11, weight: .medium))
                    .tracking(2)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 8)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.8).delay(1.0), value: appeared)

                // Zone centro storico list
                VStack(spacing: 0) {
                    ForEach(Array(ZonaNormale.zoneCentro.enumerated()), id: \.element) { index, zona in
                        let delay = 1.05 + Double(index) * 0.1

                        ZonaNormaleCard(
                            zona: zona,
                            action: { viewModel.selectZona(zona) },
                            appeared: appeared,
                            animationDelay: delay
                        )

                        if zona != ZonaNormale.zoneCentro.last {
                            Divider()
                                .padding(.leading, 24)
                                .opacity(appeared ? 1 : 0)
                                .animation(.easeOut(duration: 0.4).delay(delay + 0.2), value: appeared)
                        }
                    }
                }

                // Isole label
                Text(strings.islands)
                    .font(.system(size: 11, weight: .medium))
                    .tracking(2)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 8)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.8).delay(1.3), value: appeared)

                // Isole list
                VStack(spacing: 0) {
                    ForEach(Array(ZonaNormale.isole.enumerated()), id: \.element) { index, zona in
                        let delay = 1.35 + Double(index) * 0.08

                        ZonaNormaleCard(
                            zona: zona,
                            action: { viewModel.selectZona(zona) },
                            appeared: appeared,
                            animationDelay: delay
                        )

                        if zona != ZonaNormale.isole.last {
                            Divider()
                                .padding(.leading, 24)
                                .opacity(appeared ? 1 : 0)
                                .animation(.easeOut(duration: 0.4).delay(delay + 0.15), value: appeared)
                        }
                    }
                }
            }
            .padding(.bottom, 40)
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if !appeared {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    appeared = true
                }
            }
        }
    }
}
