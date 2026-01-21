import SwiftUI

@main
struct PRApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var subscriptionViewModel = SubscriptionViewModel()
    @AppStorage("appearance") private var appearance = 0 // 0: System, 1: Light, 2: Dark

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .environmentObject(subscriptionViewModel)
                .preferredColorScheme(colorScheme)
        }
    }

    private var colorScheme: ColorScheme? {
        switch appearance {
        case 1: return .light
        case 2: return .dark
        default: return nil // System
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showSplash = true

    var body: some View {
        ZStack {
            // Main content
            Group {
                if authViewModel.isAuthenticated {
                    NewHomeView()
                } else {
                    WelcomeView()
                }
            }
            .animation(.easeInOut, value: authViewModel.isAuthenticated)

            // Splash screen overlay
            if showSplash {
                SplashView(isActive: $showSplash)
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
    }
}
