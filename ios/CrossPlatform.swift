#if canImport(UIKit)
import UIKit
#endif

/// Cross-platform haptics. No-ops on macOS, which has no equivalent for the
/// feedback generators. ponytail: one shim beats an #if at every call site.
enum Haptics {
    static func impact(_ style: Style = .light) {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: style.uiKit).impactOccurred()
        #endif
    }

    static func warning() {
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        #endif
    }

    enum Style {
        case light, medium

        #if canImport(UIKit)
        var uiKit: UIImpactFeedbackGenerator.FeedbackStyle {
            switch self {
            case .light: .light
            case .medium: .medium
            }
        }
        #endif
    }
}

#if os(macOS)
import SwiftUI

/// macOS no-op stand-ins for iOS-only text-field modifiers, so the shared views
/// compile unchanged on both platforms.
/// ponytail: shims beat editing six call sites across five view files.
enum KeyboardType {
    case numberPad, decimalPad, emailAddress
}

enum NavigationBarTitleDisplayMode {
    case inline, large, automatic
}

extension View {
    func keyboardType(_ type: KeyboardType) -> some View { self }
    func autocapitalization(_ style: Any?) -> some View { self }
    func navigationBarTitleDisplayMode(_ mode: NavigationBarTitleDisplayMode) -> some View { self }
}
#endif

import SwiftUI

extension Color {
    /// `secondarySystemBackground` has no macOS twin; `underPageBackgroundColor`
    /// is the closest AppKit equivalent.
    static var secondaryBackground: Color {
        #if os(macOS)
        Color(nsColor: .underPageBackgroundColor)
        #else
        Color(.secondarySystemBackground)
        #endif
    }
}

extension View {
    /// macOS sheets size to their content, which clipped long labels. Give them room; no-op on iOS.
    @ViewBuilder func macSheetSize() -> some View {
        #if os(macOS)
        frame(minWidth: 520, idealWidth: 560, minHeight: 600, idealHeight: 640)
        #else
        self
        #endif
    }
}
