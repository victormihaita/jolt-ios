import SwiftUI

// MARK: - Standardized Loading States

struct LoadingView: View {
    let message: String
    
    init(_ message: String = "Loading...") {
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.2)
            
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

// MARK: - Standardized Error Presentation

struct ErrorBannerView: View {
    let message: String
    let action: (() -> Void)?
    
    init(_ message: String, action: (() -> Void)? = nil) {
        self.message = message
        self.action = action
    }
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(.red)
            
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.primary)
            
            Spacer()
            
            if let action = action {
                Button("Retry") {
                    action()
                }
                .font(.subheadline)
                .foregroundStyle(Color.accentColor)
            }
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Success Feedback

struct SuccessFeedback {
    static func show(_ message: String = "Success") {
        Haptics.success()
        // You could integrate with a toast system here
    }
}

// MARK: - Better Sheet Presentations

extension View {
    /// Presents a sheet with proper iOS styling and keyboard handling
    func presentationSheet<Content: View>(
        isPresented: Binding<Bool>,
        detents: Set<PresentationDetent> = [.medium, .large],
        dragIndicator: Bool = true,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        self.sheet(isPresented: isPresented) {
            content()
                .presentationDetents(detents)
                .presentationDragIndicator(dragIndicator ? .visible : .hidden)
                .dismissKeyboardOnTap()
        }
    }
    
    /// Presents a full screen cover with proper keyboard handling
    func presentationFullScreen<Content: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        self.fullScreenCover(isPresented: isPresented) {
            content()
                .dismissKeyboardOnDisappear()
        }
    }
}

// MARK: - Improved Animations

extension Animation {
    /// Standard iOS transition animation
    static let iOSTransition = Animation.easeInOut(duration: 0.35)
    
    /// Smooth keyboard animation
    static let keyboard = Animation.easeOut(duration: 0.25)
    
    /// Quick feedback animation
    static let feedback = Animation.easeInOut(duration: 0.2)
}

// MARK: - Pull to Refresh Enhancement

struct EnhancedRefreshableModifier: ViewModifier {
    let action: () async -> Void
    @State private var isRefreshing = false
    
    func body(content: Content) -> some View {
        content
            .refreshable {
                isRefreshing = true
                await action()
                isRefreshing = false
                Haptics.light() // Feedback when refresh completes
            }
            .overlay(alignment: .top) {
                if isRefreshing {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.8)
                        .padding(.top, 8)
                }
            }
    }
}

extension View {
    func enhancedRefreshable(action: @escaping () async -> Void) -> some View {
        modifier(EnhancedRefreshableModifier(action: action))
    }
}

// MARK: - Form Validation

struct FormValidationModifier: ViewModifier {
    let isValid: Bool
    let errorMessage: String?
    
    func body(content: Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            content
            
            if let errorMessage = errorMessage, !isValid {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.feedback, value: isValid)
    }
}

extension View {
    func formValidation(isValid: Bool, errorMessage: String? = nil) -> some View {
        modifier(FormValidationModifier(isValid: isValid, errorMessage: errorMessage))
    }
}

// MARK: - Safe Area Keyboard Handling

struct SafeAreaKeyboardModifier: ViewModifier {
    @StateObject private var keyboardObserver = KeyboardObserver()
    
    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom) {
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: keyboardObserver.keyboardHeight)
            }
            .animation(.keyboard, value: keyboardObserver.keyboardHeight)
    }
}

extension View {
    func safeAreaKeyboard() -> some View {
        modifier(SafeAreaKeyboardModifier())
    }
}
