import Foundation

public extension String {
    /// Returns true if the string is empty or contains only whitespace
    var isBlank: Bool {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Returns nil if the string is blank, otherwise returns self
    var nilIfBlank: String? {
        isBlank ? nil : self
    }

    /// Truncates the string to the specified length, adding an ellipsis if needed
    func truncated(to length: Int, trailing: String = "…") -> String {
        guard count > length else { return self }
        return String(prefix(length - trailing.count)) + trailing
    }
}
