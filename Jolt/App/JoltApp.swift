import SwiftUI

@main
struct JoltApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var subscriptionViewModel = SubscriptionViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .environmentObject(subscriptionViewModel)
                .preferredColorScheme(.none) // Respect system setting
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                HomeView()
            } else {
                WelcomeView()
            }
        }
        .animation(.easeInOut, value: authViewModel.isAuthenticated)
    }
}
