import SwiftUI

// MARK: - Adaptive glass effect modifier
// iOS 26+: Liquid Glass via .glassEffect()
// iOS 17/18/25: ultraThinMaterial fallback

extension View {
    @ViewBuilder
    func adaptiveGlassEffect(interactive: Bool = false, in shape: some Shape) -> some View {
        if #available(iOS 26, *) {
            if interactive {
                self.glassEffect(.regular.interactive(), in: shape)
            } else {
                self.glassEffect(.regular, in: shape)
            }
        } else {
            self
                .background(.ultraThinMaterial, in: shape)
        }
    }
}

// MARK: - Adaptive GlassEffectContainer
// iOS 26+: GlassEffectContainer (enables shared Liquid Glass rendering)
// iOS 17/18/25: passthrough (children render independently with material fallback)

struct AdaptiveGlassContainer<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        if #available(iOS 26, *) {
            GlassEffectContainer {
                content
            }
        } else {
            content
        }
    }
}
