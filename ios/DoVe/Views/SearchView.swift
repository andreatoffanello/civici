import SwiftUI

struct SearchView: View {
    @Environment(SearchViewModel.self) private var viewModel
    @Environment(\.strings) private var strings
    @FocusState private var isSearchFocused: Bool
    @State private var appeared = false

    var body: some View {
        @Bindable var vm = viewModel

        VStack(spacing: 0) {
            // Sestiere header
            if let sestiere = viewModel.selectedSestiere {
                HStack(spacing: 14) {
                    Group {
                        if UIImage(named: sestiere.silhouetteAsset) != nil {
                            Image(sestiere.silhouetteAsset)
                                .renderingMode(.template)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } else {
                            Image(systemName: sestiere.symbolName)
                                .font(.system(size: 24, weight: .light))
                        }
                    }
                    .foregroundStyle(sestiere.color)
                    .frame(width: 44, height: 36)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(sestiere.name.uppercased())
                            .font(.custom("Sotoportego-Medium", size: 22))
                            .foregroundStyle(sestiere.color)

                        Text(strings.civiciLabel(viewModel.totalCount))
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
                            .adaptiveGlassEffect(interactive: true, in: Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 16)
            }

            // Search field
            HStack(spacing: 10) {
                Image(systemName: "number")
                    .foregroundStyle(.secondary)

                TextField(strings.civicNumberPlaceholder, text: $vm.searchText)
                    .keyboardType(.numberPad)
                    .focused($isSearchFocused)
                    .font(.title3)

                if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.clearSearch()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .adaptiveGlassEffect(in: RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 20)

            // Result count
            if !viewModel.searchText.isEmpty {
                HStack {
                    Text(strings.resultsLabel(viewModel.resultCount))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // Results list
            ScrollView {
                LazyVStack(spacing: 8) {
                    if let sestiere = viewModel.selectedSestiere {
                    ForEach(Array(viewModel.displayedNumbers.enumerated()), id: \.element) { index, number in
                        CivicoRow(
                            number: number,
                            sestiere: sestiere
                        ) {
                            viewModel.selectNumber(number)
                        }
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)
                        .animation(
                            .spring(duration: 0.4, bounce: 0.2).delay(Double(min(index, 10)) * 0.03),
                            value: appeared
                        )
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.95)),
                            removal: .opacity
                        ))
                    }

                    if viewModel.hasMoreResults {
                        Text(strings.keepTypingToFilter)
                            .font(.footnote)
                            .foregroundStyle(.tertiary)
                            .padding(.vertical, 20)
                    }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .animation(.smooth(duration: 0.3), value: viewModel.displayedNumbers)
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
