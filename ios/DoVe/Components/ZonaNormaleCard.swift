import SwiftUI

struct ZonaNormaleCard: View {
    let zona: ZonaNormale
    let action: () -> Void
    var appeared: Bool = true
    var animationDelay: Double = 0

    var body: some View {
        Button(action: action) {
            HStack(spacing: 0) {
                // Nome zona
                Text(zona.name.lowercased())
                    .font(.custom("Sotoportego-Medium", size: 28))
                    .tracking(0.5)
                    .foregroundStyle(zona.color)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 24)
                    .opacity(appeared ? 1 : 0)
                    .offset(x: appeared ? 0 : -20)
                    .blur(radius: appeared ? 0 : 3)
                    .animation(
                        .timingCurve(0.16, 1, 0.3, 1, duration: 0.9).delay(animationDelay),
                        value: appeared
                    )

                // Silhouette o icona
                Group {
                    if UIImage(named: zona.silhouetteAsset) != nil {
                        Image(zona.silhouetteAsset)
                            .renderingMode(.template)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else {
                        Image(systemName: zona.symbolName)
                            .font(.system(size: 36, weight: .light))
                    }
                }
                .foregroundStyle(zona.color.opacity(0.35))
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
