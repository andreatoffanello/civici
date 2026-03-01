import SwiftUI
import UIKit

extension Color {
    /// Corallo principale — più chiaro in dark mode per leggibilità
    static let doVeAccent = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.878, green: 0.427, blue: 0.318, alpha: 1) // #E06D51
            : UIColor(red: 0.761, green: 0.271, blue: 0.176, alpha: 1) // #C2452D
    })

    /// Sfondo delle card nizioleto — crema caldo in light, scuro caldo in dark
    static let niziolettoBackground = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.165, green: 0.145, blue: 0.125, alpha: 1) // #2A2520
            : UIColor(red: 0.961, green: 0.941, blue: 0.902, alpha: 1) // #F5F0E6
    })

    /// Testo e bordi sui nizioleti — quasi-nero in light, quasi-bianco caldo in dark
    static let niziolettoText = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.941, green: 0.922, blue: 0.878, alpha: 1) // #F0EBE0
            : UIColor(red: 0.165, green: 0.165, blue: 0.165, alpha: 1) // #2A2A2A
    })

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
