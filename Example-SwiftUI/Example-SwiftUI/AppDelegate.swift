import ChatistSdk
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Enable SDK logging for debugging
        Chatist.enableLogging(true)

        // Initialize the SDK with your API key
        Chatist.initialize(key: "Your API Key") // Replace with your actual API key

        // Setup analytics delegate
        Chatist.setAnalyticsDelegate(self)

        // Simulate user login (for demonstration purposes)
        Chatist.login()

        // Setup push notifications
        setupPushNotifications(application)

        return true
    }

    /// Configures push notification permissions and registers for remote notifications
    private func setupPushNotifications(_ application: UIApplication) {
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.delegate = self

        Task {
            do {
                let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
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

    /// Called when APNs successfully registers the device and provides a device token
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        print("✅ Device token received: \(deviceToken.map { String(format: "%02.2hhx", $0) }.joined())")
        // Pass the device token to Chatist SDK for push notification delivery
        Chatist.setDeviceToken(deviceToken)
    }

    /// Called when APNs registration fails
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("❌ Failed to register for remote notifications: \(error)")
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension AppDelegate: UNUserNotificationCenterDelegate {

    /// Called when a notification is delivered while the app is in the foreground
    /// Returns the presentation options for displaying the notification
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        let userInfo = notification.request.content.userInfo

        print("📱 Will present notification: \(userInfo)")

        // Check if this is a Chatist notification and let the SDK handle presentation
        if Chatist.isChatistPushNotification(userInfo) {
            print("🔔 Chatist notification - will present with options")
            return Chatist.willPresentNotification(userInfo)
        }

        // Default presentation for non-Chatist notifications
        return [.banner, .sound, .badge]
    }

    /// Called when the user taps on a notification
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        print("📱 User tapped notification: \(userInfo)")

        // Check if this is a Chatist notification and let the SDK handle it
        if Chatist.isChatistPushNotification(userInfo) {
            print("🔔 Chatist notification - handling")
            Chatist.handlePushNotification(userInfo)
        }

        completionHandler()
    }
}

// MARK: - ChatistAnalyticsDelegate

extension AppDelegate: ChatistAnalyticsDelegate {

    /// Called when the SDK tracks an analytics event
    func didReceiveEvent(_ event: ChatistAnalyticsEvent) {
        print("📊 Analytics Event: \(event.name)")
        print("   Properties: \(event.properties)")
        print("   Timestamp: \(event.timestamp)")
        print("   SDK Version: \(event.sdkVersion)")
        print("   Customer ID: \(event.customerId ?? "nil")")
        print("   Original Customer ID: \(event.originalCustomerId ?? "nil")")
        print("   ---")
    }

    /// Called when user properties are updated
    func didUpdateUserProperties(_ properties: [String: Any]) {
        print("📊 Analytics User Properties Updated: \(properties)")
    }

    /// Called when the user ID is updated
    func didUpdateUserID(_ userId: String?) {
        print("📊 Analytics User ID Updated: \(userId ?? "nil")")
    }
}
