import SwiftUI
import UIKit

struct KeyboardDismissModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                             to: nil,
                                             from: nil,
                                             for: nil)
            }
    }
}

extension View {
    func dismissKeyboardOnTap() -> some View {
        modifier(KeyboardDismissModifier())
    }
} 