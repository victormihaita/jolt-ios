import SwiftUI

struct SplashView: View {
    @Binding var isActive: Bool
    @State private var logoScale: CGFloat = 1.0
    @State private var logoOpacity: Double = 1.0
    @State private var textOpacity: Double = 0.0
    @State private var ringScale: CGFloat = 0.8
    @State private var ringOpacity: Double = 0.0

    var body: some View {
        ZStack {
            // Background gradient matching WelcomeView
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.3),
                    Color.purple.opacity(0.2),
                    Color.pink.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: Theme.Spacing.lg) {
                Spacer()

                ZStack {
                    // Animated ring behind logo
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.blue.opacity(0.5), .purple.opacity(0.3), .pink.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 160, height: 160)
                        .scaleEffect(ringScale)
                        .opacity(ringOpacity)

                    // App Logo
                    Image("AppLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                }

                // App name with fade-in
                VStack(spacing: Theme.Spacing.xs) {
                    Text("Power Reminders")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.primary, .primary.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text("Never forget what matters")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .opacity(textOpacity)

                Spacer()
                Spacer()
            }
        }
        .onAppear {
            // Animate ring expansion
            withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
                ringScale = 1.0
                ringOpacity = 1.0
            }

            // Animate logo pulse
            withAnimation(.easeInOut(duration: 0.5).delay(0.2)) {
                logoScale = 1.05
            }

            withAnimation(.easeInOut(duration: 0.3).delay(0.5)) {
                logoScale = 1.0
            }

            // Fade in text
            withAnimation(.easeOut(duration: 0.5).delay(0.4)) {
                textOpacity = 1.0
            }

            // Fade out ring
            withAnimation(.easeIn(duration: 0.3).delay(0.9)) {
                ringOpacity = 0.0
            }

            // Transition to main app
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                withAnimation(.easeInOut(duration: 0.4)) {
                    isActive = false
                }
            }
        }
    }
}

#Preview {
    SplashView(isActive: .constant(true))
}
