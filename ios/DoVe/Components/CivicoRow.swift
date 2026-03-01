import SwiftUI

struct CivicoRow: View {
    let number: String
    let sestiere: Sestiere
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 0) {
                // Targa civica veneziana
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
    }
}
