//
//  ChatistNotificationViewWrapper.swift
//  Example-SwiftUI
//
//  SwiftUI wrapper for ChatistNotificationView (UIKit component)
//

import ChatistSdk
import SwiftUI
import UIKit

/// A SwiftUI wrapper for the UIKit-based ChatistNotificationView
/// This allows us to use the SDK's notification view within SwiftUI layouts
struct ChatistNotificationViewWrapper: UIViewRepresentable {

    // MARK: Properties

    /// The notification data to display
    let notification: ChatistNotification

    /// Callback when the user taps on the notification
    let onTap: () -> Void

    /// Callback when the user closes the notification
    let onClose: () -> Void

    // MARK: UIViewRepresentable

    /// Creates the UIKit view instance
    func makeUIView(context: Context) -> ChatistNotificationView {
        let view = ChatistNotificationView(
            notification: notification,
            onTap: onTap,
            onClose: onClose
        )

        // Set content hugging and compression resistance for proper sizing
        view.setContentHuggingPriority(.required, for: .vertical)
        view.setContentCompressionResistancePriority(.required, for: .vertical)

        return view
    }

    /// Updates the UIKit view when SwiftUI state changes
    /// Note: Since we recreate the view for each new notification,
    /// this method doesn't need to do anything
    func updateUIView(_ uiView: ChatistNotificationView, context: Context) {
        // No updates needed - the view is recreated for each new notification
    }
}

// MARK: - Preview

#Preview {
    // Preview is not available without a real ChatistNotification instance
    // This is just a placeholder for the preview provider
    Color.clear
}

