import SwiftUI

struct StreetListView: View {
    @Environment(SearchViewModel.self) private var viewModel
    @FocusState private var isSearchFocused: Bool
    @State private var appeared = false

    var body: some View {
        @Bindable var vm = viewModel

        VStack(spacing: 0) {
            // Zona header
            if let zona = viewModel.selectedZona {
                HStack(spacing: 14) {
                    Group {
                        if UIImage(named: zona.silhouetteAsset) != nil {
                            Image(zona.silhouetteAsset)
                                .renderingMode(.template)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } else {
                            Image(systemName: zona.symbolName)
                                .font(.system(size: 24, weight: .light))
                        }
                    }
                    .foregroundStyle(zona.color)
                    .frame(width: 44, height: 36)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(zona.name.uppercased())
                            .font(.custom("Sotoportego-Medium", size: 22))
                            .foregroundStyle(zona.color)

                        Text("\(viewModel.streets.count) vie")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button {
                        viewModel.reset()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 32, height: 32)
                            .glassEffect(
                                .regular.interactive(),
                                in: .circle
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 16)
            }

            // Search field
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("Cerca via, calle, fondamenta...", text: $vm.streetSearchText)
                    .focused($isSearchFocused)
                    .font(.body)

                if !viewModel.streetSearchText.isEmpty {
                    Button {
                        viewModel.streetSearchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .glassEffect(
                .regular,
                in: RoundedRectangle(cornerRadius: 16)
            )
            .padding(.horizontal, 20)

            // Streets list
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(viewModel.streets.enumerated()), id: \.element) { index, street in
                        Button {
                            viewModel.selectStreet(street)
                        } label: {
                            HStack {
                                Text(street.uppercased())
                                    .font(.custom("Sotoportego-Medium", size: 18))
                                    .foregroundStyle(Color(hex: "2A2A2A"))

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 14)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 10)
                        .animation(
                            .spring(duration: 0.4, bounce: 0.2).delay(Double(min(index, 15)) * 0.02),
                            value: appeared
                        )

                        if index < viewModel.streets.count - 1 {
                            Divider()
                                .padding(.leading, 24)
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            isSearchFocused = true
            withAnimation {
                appeared = true
            }
        }
    }
}
