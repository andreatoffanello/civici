import SwiftUI

struct SestiereCard: View {
    let sestiere: Sestiere
    let action: () -> Void
    var appeared: Bool = true
    var animationDelay: Double = 0

    var body: some View {
        Button(action: action) {
            HStack(spacing: 0) {
                // Nome sestiere
                Text(sestiere.name.lowercased())
                    .font(.custom("Sotoportego-Medium", size: 28))
                    .tracking(0.5)
                    .foregroundStyle(sestiere.color)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 24)
                    .opacity(appeared ? 1 : 0)
                    .offset(x: appeared ? 0 : -20)
                    .blur(radius: appeared ? 0 : 3)
                    .animation(
                        .timingCurve(0.16, 1, 0.3, 1, duration: 0.9).delay(animationDelay),
                        value: appeared
                    )

                // Silhouette geografica o icona
                Group {
                    if UIImage(named: sestiere.silhouetteAsset) != nil {
                        Image(sestiere.silhouetteAsset)
                            .renderingMode(.template)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else {
                        Image(systemName: sestiere.symbolName)
                            .font(.system(size: 36, weight: .light))
                    }
                }
                .foregroundStyle(sestiere.color.opacity(0.35))
                .frame(width: 110, height: 75)
                .padding(.trailing, 20)
                    .opacity(appeared ? 1 : 0)
                    .offset(x: appeared ? 0 : 20)
                    .scaleEffect(appeared ? 1 : 0.8)
                    .blur(radius: appeared ? 0 : 4)
                    .animation(
                        .timingCurve(0.16, 1, 0.3, 1, duration: 1.1).delay(animationDelay + 0.12),
                        value: appeared
                    )
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .contentShape(Rectangle())
        }
        .buttonStyle(NiziolettoButtonStyle())
    }
}

/// Button style con press feedback
struct NiziolettoButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
