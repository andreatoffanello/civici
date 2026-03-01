import SwiftUI

/// La forma caratteristica dei nizioleti veneziani:
/// rettangolo con angoli leggermente arrotondati e bordi sottilmente
/// irregolari, come dipinto a mano su un muro.
struct NiziolettoShape: Shape {
    func path(in rect: CGRect) -> Path {
        // Nizioleto: rettangolo con angoli arrotondati dolcemente,
        // proporzioni leggermente più larghe che alte
        let cornerRadius: CGFloat = min(rect.width, rect.height) * 0.35
        return Path(roundedRect: rect, cornerRadius: cornerRadius)
    }
}

/// Bordo decorativo doppio tipico dei nizioleti:
/// una linea esterna e una interna con un piccolo gap.
struct NiziolettoBorder: View {
    let color: Color
    let lineWidth: CGFloat

    init(color: Color = .primary.opacity(0.6), lineWidth: CGFloat = 1.5) {
        self.color = color
        self.lineWidth = lineWidth
    }

    var body: some View {
        ZStack {
            // Bordo esterno
            NiziolettoShape()
                .stroke(color, lineWidth: lineWidth)

            // Bordo interno (il tipico doppio bordo dei nizioleti)
            NiziolettoShape()
                .stroke(color.opacity(0.4), lineWidth: lineWidth * 0.7)
                .padding(lineWidth * 3)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        Text("CALLE LARGA\nDEI BOTTERI")
            .font(.system(size: 14, weight: .regular, design: .serif))
            .multilineTextAlignment(.center)
            .tracking(1)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color(hex: "F5F0E6"))
            .overlay(NiziolettoBorder())
            .clipShape(NiziolettoShape())
            .frame(width: 180)

        Text("S. MARCO")
            .font(.system(size: 14, weight: .regular, design: .serif))
            .tracking(1)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color(hex: "F5F0E6"))
            .overlay(NiziolettoBorder())
            .clipShape(NiziolettoShape())
    }
    .padding()
}
