import SwiftUI

struct SplashScreenView: View {
    @State private var scale: CGFloat = 0.85
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            Color(hex: "C2452D")
                .ignoresSafeArea()

            Image("logo-dove-bianco")
                .resizable()
                .scaledToFit()
                .frame(width: 180)
                .scaleEffect(scale)
                .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}

#Preview {
    SplashScreenView()
}
