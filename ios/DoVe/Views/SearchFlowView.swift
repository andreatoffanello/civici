import SwiftUI

struct SearchFlowView: View {
    @Environment(SearchViewModel.self) private var viewModel
    @Environment(\.strings) private var strings
    @State private var showInfo = false

    var body: some View {
        Group {
            if viewModel.selectedCivico != nil {
                // Mappa risultato (sia sestiere che zona normale)
                ResultView()
                    .transition(.opacity)
            } else if viewModel.selectedZona != nil {
                // Flusso zona normale
                if viewModel.selectedStreet != nil {
                    StreetNumbersView()
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                } else {
                    StreetListView()
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            } else if viewModel.selectedSestiere != nil {
                // Flusso sestiere classico
                SearchView()
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                // Lista sestieri/zone
                SestieriView()
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }
        }
        .animation(.smooth(duration: 0.28), value: viewModel.selectedSestiere?.id)
        .animation(.smooth(duration: 0.28), value: viewModel.selectedZona?.id)
        .animation(.smooth(duration: 0.28), value: viewModel.selectedStreet)
        .animation(.smooth(duration: 0.28), value: viewModel.selectedCivico?.id)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showInfo = true
                } label: {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationDestination(isPresented: $showInfo) {
            InfoView()
        }
    }
}
