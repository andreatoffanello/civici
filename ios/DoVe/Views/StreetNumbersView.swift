import SwiftUI

struct StreetNumbersView: View {
    @Environment(SearchViewModel.self) private var viewModel
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            // Street header
            if let zona = viewModel.selectedZona, let street = viewModel.selectedStreet {
                HStack(spacing: 14) {
                    Button {
                        viewModel.selectedStreet = nil
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 32, height: 32)
                            .glassEffect(
                                .regular.interactive(),
                                in: .circle
                            )
                    }
                    .buttonStyle(.plain)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(zona.name.uppercased())
                            .font(.custom("Sotoportego-Medium", size: 13))
                            .foregroundStyle(.secondary)

                        Text(street.uppercased())
                            .font(.custom("Sotoportego-Medium", size: 20))
                            .foregroundStyle(zona.color)
                    }

                    Spacer()

                    Text("\(viewModel.streetNumbers.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 16)
            }

            // Numbers list
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(Array(viewModel.streetNumbers.enumerated()), id: \.element) { index, number in
                        Button {
                            viewModel.selectZonaNumber(number)
                        } label: {
                            HStack(spacing: 0) {
                                Text(number)
                                    .font(.system(size: 20, weight: .bold, design: .serif))
                                    .monospacedDigit()
                                    .foregroundStyle(Color(hex: "C2452D"))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color(hex: "F5F0E6"))
                                    .clipShape(NiziolettoShape())
                                    .overlay(
                                        NiziolettoShape()
                                            .stroke(Color(hex: "C2452D").opacity(0.3), lineWidth: 1)
                                    )

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.horizontal, 4)
                            .padding(.vertical, 4)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(NiziolettoButtonStyle())
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)
                        .animation(
                            .spring(duration: 0.4, bounce: 0.2).delay(Double(min(index, 10)) * 0.03),
                            value: appeared
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            withAnimation {
                appeared = true
            }
        }
    }
}
