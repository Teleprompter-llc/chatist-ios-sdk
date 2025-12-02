# Chatist iOS SDK Example App

This is a comprehensive example iOS application demonstrating the integration and usage of the Chatist iOS SDK. The app showcases how to properly implement the SDK in your iOS project, including customer management, push notifications via Apple Push Notification service (APNs), and the complete chat UI.

## 📱 Features

- **Complete Chatist SDK Integration**: Full implementation of customer support chat functionality
- **Customer Session Management**: Login/logout functionality with session persistence
- **Push Notifications**: APNs integration for real-time message notifications
- **In-App Notifications**: Beautiful notification overlay for incoming messages
- **Unread Message Tracking**: Real-time count of unread support messages via Combine
- **Deep Linking**: Support for opening specific tickets from notifications
- **Analytics Support**: Optional analytics event delegate integration

## 🛠️ Requirements

- iOS 14.0+
- Mac Catalyst 14.0+
- Swift 6.0+
- Xcode 16+
- Chatist SDK: 1.0.0+

## 🔧 Setup

### 1. SDK Dependency

The Chatist iOS SDK is available via Swift Package Manager. Add the dependency to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/Teleprompter-llc/chatist-ios-sdk.git", .upToNextMajor(from: "1.0.0"))
]
```

Or add it through Xcode:
1. File → Add Package Dependencies
2. Enter the repository URL: `https://github.com/Teleprompter-llc/chatist-ios-sdk.git`
3. Select version: 1.0.0 or later

### 2. API Key Configuration

Update the API key in your `AppDelegate`:

```swift
Chatist.initialize(key: "Your API Key")  // Replace with your actual API key
```

### 3. Push Notifications Configuration

The Chatist iOS SDK uses Apple Push Notification service (APNs) directly. Simply ensure your app has the proper push notification entitlements configured in Xcode.

## 🚀 Core Implementation

### SDK Initialization and Login

The SDK initialization and customer login happen in the `AppDelegate` class:

```swift
import UIKit
import ChatistSdk
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Enable SDK logging for debugging
        Chatist.enableLogging(true)

        // Initialize the SDK with your API key
        Chatist.initialize(key: "Your API Key")

        // Setup analytics delegate (optional)
        Chatist.setAnalyticsDelegate(self)

        // Login the customer to enable notifications
        Chatist.login()

        // Setup push notifications
        setupPushNotifications(application)

        return true
    }
}
```

**Important**: The `login()` call is essential for:
- Enabling push notifications for support messages
- Establishing customer session with the backend
- Associating the device with the customer
- Accessing conversation history

### Main View Controller Implementation

Example implementation showing how to integrate the chat UI:

```swift
import UIKit
import ChatistSdk
import Combine

class ViewController: UIViewController {
    private var cancellables = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUnreadCountObserver()
        setupNotificationObserver()
    }

    @objc func openChatist() {
        Chatist.open()
    }

    private func setupUnreadCountObserver() {
        Chatist.getUnreadMessagesCount()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] count in
                // Update your UI with unread count
                print("Unread messages: \(count)")
            }
            .store(in: &cancellables)
    }

    private func setupNotificationObserver() {
        Chatist.observeNotifications()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.showInAppNotification(notification)
            }
            .store(in: &cancellables)
    }
}
```

## 🍎 Apple Push Notification Service (APNs) Integration

### AppDelegate Push Notification Setup

The Chatist iOS SDK uses APNs for push notifications (no Firebase required):

```swift
extension AppDelegate {
    private func setupPushNotifications(_ application: UIApplication) {
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.delegate = self

        Task {
            do {
                let granted = try await notificationCenter.requestAuthorization(
                    options: [.alert, .sound, .badge]
                )
                if granted {
                    print("✅ Push notification permission granted")
                    await MainActor.run {
                        application.registerForRemoteNotifications()
                    }
                } else {
                    print("❌ Push notification permission denied")
                }
            } catch {
                print("❌ Error requesting push notification permission: \(error)")
            }
        }
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        print("✅ Device token received")
        Chatist.setDeviceToken(deviceToken)
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("❌ Failed to register for remote notifications: \(error)")
    }
}
```

### UNUserNotificationCenterDelegate Implementation

Handle foreground and background notifications:

```swift
extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        let userInfo = notification.request.content.userInfo

        if Chatist.isChatistPushNotification(userInfo) {
            // Let Chatist SDK decide how to present the notification
            return Chatist.willPresentNotification(userInfo)
        }

        return [.alert, .sound, .badge]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        if Chatist.isChatistPushNotification(userInfo) {
            // Handle notification tap - opens chat to specific ticket
            Chatist.handlePushNotification(userInfo)
        }

        completionHandler()
    }
}
```

The SDK intelligently handles notification presentation:
- If chat UI is open: Shows sound only
- If in-app notification observer is active: Shows sound only (for custom UI)
- Otherwise: Shows banner and sound

## 🔔 In-App Notifications

Display in-app notification overlays when messages arrive while the app is active. The SDK provides both UIKit (`ChatistNotificationUIView`) and SwiftUI (`ChatistNotificationView`) components for a ready-to-use UI, or you can implement your own custom notification view using the `ChatistNotification` data.

### SwiftUI Implementation

```swift
import SwiftUI
import ChatistSdk

struct ContentView: View {
    @State private var notification: ChatistNotification?

    var body: some View {
        ZStack(alignment: .top) {
            // Your main content
            MainView()

            if let notification {
                ChatistNotificationView(
                    notification: notification,
                    onTap: {
                        self.notification = nil
                        Chatist.open(with: notification.ticketID)
                    },
                    onClose: {
                        self.notification = nil
                    }
                )
                .padding(.horizontal, 16)
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(), value: notification)
            }
        }
        .onReceive(Chatist.observeNotifications()) { notification in
            withAnimation {
                self.notification = notification
            }
        }
    }
}
```

### UIKit Implementation

```swift
import Combine
import ChatistSdk

class YourViewController: UIViewController {
    private var cancellables = Set<AnyCancellable>()
    private var notificationView: ChatistNotificationUIView?

    override func viewDidLoad() {
        super.viewDidLoad()

        Chatist.observeNotifications()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.showNotification(notification)
            }
            .store(in: &cancellables)
    }

    private func showNotification(_ notification: ChatistNotification) {
        // Remove any existing notification
        notificationView?.removeFromSuperview()

        let notificationView = ChatistNotificationUIView(
            notification: notification,
            onTap: { [weak self] in
                self?.notificationView?.removeFromSuperview()
                self?.notificationView = nil
                Chatist.open(with: notification.ticketID)
            },
            onClose: { [weak self] in
                self?.notificationView?.removeFromSuperview()
                self?.notificationView = nil
            }
        )

        view.addSubview(notificationView)
        self.notificationView = notificationView

        notificationView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            notificationView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            notificationView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            notificationView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
        ])
    }
}
```

### ChatistNotification Properties

The `ChatistNotification` struct contains:

```swift
public struct ChatistNotification {
    public let ticketID: String        // Ticket identifier for deep linking
    public let sender: String          // Sender's name
    public let message: String         // Message content
    public let avatarUrl: String?      // Optional sender avatar URL
    public let attachmentCount: Int?   // Count of image attachments, if any
}
```

Features:
- Available for both SwiftUI (`ChatistNotificationView`) and UIKit (`ChatistNotificationUIView`)
- Themed according to Chatist branding
- Shows sender avatar with speech bubble mask
- Displays sender name and message preview
- Tap to open the specific conversation
- Close button for manual dismissal
- Animated press feedback on interaction
- Glass effect on iOS 26.0+

## 📊 Customer Management

Update customer information after authentication:

```swift
// After user login in your app
Task {
    await Chatist.updateCustomer(
        email: user.email,
        originalID: user.id  // Your system's user ID
    )
}
```

This associates support conversations with specific users and enables personalized support.

## 🔄 Unread Message Tracking

### Observing Unread Count

Monitor unread message count in real-time using Combine:

```swift
import Combine
import ChatistSdk

class YourViewController: UIViewController {
    private var cancellables = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()

        Chatist.getUnreadMessagesCount()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] count in
                self?.updateUnreadBadge(count)
            }
            .store(in: &cancellables)
    }

    private func updateUnreadBadge(_ count: Int) {
        // Update your UI with the unread count
        if count > 0 {
            // Show badge
        } else {
            // Hide badge
        }
    }
}
```

### Refreshing Unread Count on Foreground

**Important**: You must refresh the unread count when the app enters foreground:

#### UIKit AppDelegate

```swift
func applicationWillEnterForeground(_ application: UIApplication) {
    Task { await Chatist.refreshUnreadMessagesCount() }
}
```

#### SwiftUI with ScenePhase

```swift
@Environment(\.scenePhase) var scenePhase

var body: some Scene {
    WindowGroup {
        ContentView()
    }
    .onChange(of: scenePhase) { oldPhase, newPhase in
        if newPhase == .active {
            Task { await Chatist.refreshUnreadMessagesCount() }
        }
    }
}
```

#### SceneDelegate

```swift
func sceneWillEnterForeground(_ scene: UIScene) {
    Task { await Chatist.refreshUnreadMessagesCount() }
}
```

### Manual Refresh

You can also manually refresh the unread count at any time:

```swift
Task {
    await Chatist.refreshUnreadMessagesCount()
}
```

## 🎯 Opening the Chat Interface

### Open Ticket List

Open the chat interface showing all customer tickets:

```swift
Chatist.open()
```

### Open Specific Ticket (Deep Linking)

Open the chat interface to a specific ticket:

```swift
Chatist.open(with: ticketID)
```

This is useful when:
- User taps on a notification
- Deep linking from another part of your app
- Continuing a specific conversation

## 🔄 Session Lifecycle Management

### Login Flow

```swift
// In your app's login flow
private func onUserLoginSuccess(user: User) {
    // Login to Chatist SDK
    Chatist.login()

    // Update customer information
    Task {
        await Chatist.updateCustomer(
            email: user.email,
            originalID: user.id
        )
    }

    // SDK is ready for use
    navigateToMainScreen()
}
```

### Logout Flow

```swift
// In your app's logout flow
private func onUserLogout() {
    // Logout from Chatist SDK (stops notifications, clears data)
    Chatist.logout()

    // Optionally, login again to continue using SDK anonymously
    // This allows the user to still access support without being identified
    Chatist.login()

    // Clear your app's user session
    clearUserSession()
    navigateToLoginScreen()
}
```

### User Switching

```swift
private func switchUser(newUser: User) {
    // Logout current user
    Chatist.logout()

    // Login new user
    Chatist.login()
    Task {
        await Chatist.updateCustomer(
            email: newUser.email,
            originalID: newUser.id
        )
    }
}
```

## 📊 Analytics Integration

Integrate your analytics provider to track SDK events:

### Implementing ChatistAnalyticsDelegate

```swift
import ChatistSdk

extension AppDelegate: ChatistAnalyticsDelegate {
    func didReceiveEvent(_ event: ChatistAnalyticsEvent) {
        print("📊 Analytics Event: \(event.name)")
        print("   Properties: \(event.properties)")
        print("   Timestamp: \(event.timestamp)")
        print("   SDK Version: \(event.sdkVersion)")
        print("   Customer ID: \(event.customerId ?? "nil")")
        print("   Original Customer ID: \(event.originalCustomerId ?? "nil")")

        // Forward to your analytics service
        Analytics.track(event.name, properties: event.properties)
    }

    func didUpdateUserProperties(_ properties: [String: Any]) {
        print("📊 Analytics User Properties Updated: \(properties)")

        // Update user properties in your analytics service
        Analytics.setUserProperties(properties)
    }

    func didUpdateUserID(_ userId: String?) {
        print("📊 Analytics User ID Updated: \(userId ?? "nil")")

        // Update user ID in your analytics service
        Analytics.setUserId(userId)
    }
}
```

### Setting the Analytics Delegate

```swift
// During SDK initialization
Chatist.setAnalyticsDelegate(self)
```

### Analytics Events

The SDK tracks various events including:
- SDK initialization
- Chat opened/closed
- Messages sent/received
- Push notifications received/tapped
- Customer data updated
- Errors

## 📂 Project Structure

```
YourApp/
├── AppDelegate.swift              # SDK initialization, push notifications
├── ViewController.swift           # Main UI, chat integration
└── YourApp.entitlements          # Push notification capabilities
```

## 🚀 Getting Started

1. **Add the SDK dependency** via Swift Package Manager
2. **Replace the API key** in your `AppDelegate` with your actual Chatist API key
3. **Configure push notifications** entitlements in Xcode
4. **Build and run** the app

## 💡 Advanced Features

### Checking if Notification is from Chatist

```swift
if Chatist.isChatistPushNotification(userInfo) {
    // Handle Chatist notification
}
```

### Custom Notification Presentation

The SDK's `willPresentNotification` method returns appropriate presentation options based on the current state:

```swift
let options = Chatist.willPresentNotification(userInfo)
// Returns [.sound] if chat is open or in-app observer is active
// Returns [.sound, .banner] otherwise
```

## 📚 Complete Public API Reference

### Initialization & Configuration

| Method | Description |
|--------|-------------|
| `Chatist.enableLogging(_ enabled: Bool)` | Enable or disable SDK logging |
| `Chatist.initialize(key: String)` | Initialize SDK with API key (required) |

### Session Management

| Method | Description |
|--------|-------------|
| `Chatist.login()` | Activate SDK session and enable push notifications |
| `Chatist.logout()` | Deactivate session and clear customer data |
| `Chatist.updateCustomer(email: String?, originalID: String?) async` | Update customer information |

### Push Notifications (APNs)

| Method | Description |
|--------|-------------|
| `Chatist.setDeviceToken(_ deviceToken: Data)` | Forward APNs device token to SDK |
| `Chatist.isChatistPushNotification(_ userInfo: [AnyHashable: Any]) -> Bool` | Check if notification is from Chatist |
| `Chatist.willPresentNotification(_ userInfo: [AnyHashable: Any]) -> UNNotificationPresentationOptions` | Handle foreground notification presentation |
| `Chatist.handlePushNotification(_ userInfo: [AnyHashable: Any])` | Handle notification tap action |

### Chat Interface

| Method | Description |
|--------|-------------|
| `Chatist.open()` | Open chat UI showing ticket list |
| `Chatist.open(with ticketID: String)` | Open chat UI to specific ticket |

### Unread Messages

| Method | Description |
|--------|-------------|
| `Chatist.getUnreadMessagesCount() -> AnyPublisher<Int, Never>` | Subscribe to unread count updates via Combine |
| `Chatist.refreshUnreadMessagesCount() async` | Manually refresh unread count from server |

### In-App Notifications

| Method | Description |
|--------|-------------|
| `Chatist.observeNotifications() -> AnyPublisher<ChatistNotification, Never>` | Subscribe to in-app notification events via Combine |

### Analytics

| Method | Description |
|--------|-------------|
| `Chatist.setAnalyticsDelegate(_ delegate: ChatistAnalyticsDelegate?)` | Set analytics delegate to receive SDK events |

### ChatistNotificationUIView (UIKit Component)

| Initializer | Description |
|-------------|-------------|
| `ChatistNotificationUIView(notification: ChatistNotification, onTap: (() -> Void)?, onClose: (() -> Void)?)` | Create in-app notification view with tap and close handlers |

### ChatistNotificationView (SwiftUI Component)

| Initializer | Description |
|-------------|-------------|
| `ChatistNotificationView(notification: ChatistNotification, onTap: @escaping () -> Void, onClose: @escaping () -> Void)` | Create SwiftUI in-app notification view with tap and close handlers |

## 📝 Important Notes

- **SDK Initialization**: Must be called before using any SDK features, preferably in `Application.didFinishLaunchingWithOptions`
- **Customer Login**: Required before opening the chat UI to enable notifications and session management
- **Thread Safety**: All SDK methods are thread-safe and can be called from any thread
- **APNs**: SDK uses Apple Push Notification service directly
- **Foreground Refresh**: Always call `refreshUnreadMessagesCount()` in `applicationWillEnterForeground` or `sceneWillEnterForeground`
- **Combine**: The SDK uses Combine framework for reactive updates

## 🔐 Security Considerations

- Store API keys securely
- The SDK can be used anonymously by calling `Chatist.login()` without `Chatist.updateCustomer()`, or with identified users by also calling `Chatist.updateCustomer()`
- Clear customer data on logout using `Chatist.logout()`

## 🆘 Support

For issues or questions about the Chatist SDK, please contact your Chatist support representative or refer to the SDK documentation included in the framework.

## 📄 License

This example app is provided as-is for demonstration purposes. The Chatist SDK is subject to its own license agreement.
