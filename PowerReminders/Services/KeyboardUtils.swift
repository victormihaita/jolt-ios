import SwiftUI
import UIKit

// MARK: - Keyboard Dismissal Utilities

/// A UIViewRepresentable that adds a tap gesture to dismiss the keyboard
/// without blocking button taps (cancelsTouchesInView = false).
private struct KeyboardDismissView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = KeyboardDismissUIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

/// Custom UIView subclass that expands to fill its parent via Auto Layout.
private class KeyboardDismissUIView: UIView {
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        guard let superview = superview else { return }
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: superview.topAnchor),
            bottomAnchor.constraint(equalTo: superview.bottomAnchor),
            leadingAnchor.constraint(equalTo: superview.leadingAnchor),
            trailingAnchor.constraint(equalTo: superview.trailingAnchor)
        ])
    }
}

extension View {
    /// Dismisses the keyboard when the background is tapped, without blocking button taps.
    func dismissKeyboardOnTap() -> some View {
        self.background(KeyboardDismissView())
    }

    /// Dismisses the keyboard when the view appears (useful for navigation)
    func dismissKeyboardOnAppear() -> some View {
        self.onAppear {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                          to: nil, from: nil, for: nil)
        }
    }

    /// Dismisses the keyboard when the view disappears
    func dismissKeyboardOnDisappear() -> some View {
        self.onDisappear {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                          to: nil, from: nil, for: nil)
        }
    }
}

// MARK: - Keyboard Avoidance

extension View {
    /// Adds proper keyboard avoidance behavior
    func keyboardAvoiding() -> some View {
        self.ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

// MARK: - Focus Management

enum FormField: Hashable, CaseIterable {
    case title
    case notes
    case searchText
    case email
    case password
    
    var submitLabel: SubmitLabel {
        switch self {
        case .title, .notes:
            return .done
        case .searchText:
            return .search
        case .email:
            return .next
        case .password:
            return .done
        }
    }
}

// MARK: - Animated Keyboard Observer

@MainActor
class KeyboardObserver: ObservableObject {
    @Published var keyboardHeight: CGFloat = 0
    @Published var isKeyboardVisible: Bool = false
    
    init() {
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
                  let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
                return
            }
            
            withAnimation(.easeOut(duration: duration)) {
                self.keyboardHeight = keyboardFrame.height
                self.isKeyboardVisible = true
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
                return
            }
            
            withAnimation(.easeOut(duration: duration)) {
                self.keyboardHeight = 0
                self.isKeyboardVisible = false
            }
        }
    }
}

// MARK: - Keyboard-aware View Modifier

struct KeyboardAwareModifier: ViewModifier {
    @StateObject private var keyboardObserver = KeyboardObserver()
    
    func body(content: Content) -> some View {
        content
            .padding(.bottom, keyboardObserver.keyboardHeight)
            .animation(.easeOut(duration: 0.3), value: keyboardObserver.keyboardHeight)
            .environmentObject(keyboardObserver)
    }
}

extension View {
    func keyboardAware() -> some View {
        modifier(KeyboardAwareModifier())
    }
}