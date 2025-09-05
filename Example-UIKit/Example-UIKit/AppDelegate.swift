import ChatistSdk
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
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

        // Setup UI
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = ExampleViewController()
        window.makeKeyAndVisible()

        self.window = window

        return true
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        Task {
            await Chatist.refreshUnreadMessagesCount()
        }
    }

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

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        print("✅ Device token received: \(deviceToken.map { String(format: "%02.2hhx", $0) }.joined())")
        Chatist.setDeviceToken(deviceToken)
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("❌ Failed to register for remote notifications: \(error)")
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        let userInfo = notification.request.content.userInfo

        print("📱 Will present notification: \(userInfo)")

        if Chatist.isChatistPushNotification(userInfo) {
            print("🔔 Chatist notification - will present with options")
            return Chatist.willPresentNotification(userInfo)
        }

        return [.banner, .sound, .badge]
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo

        print("📱 User tapped notification: \(userInfo)")

        if Chatist.isChatistPushNotification(userInfo) {
            print("🔔 Chatist notification - handling")
            Chatist.handlePushNotification(userInfo)
        }
    }
}

// MARK: - ChatistAnalyticsDelegate

extension AppDelegate: ChatistAnalyticsDelegate {
    func didReceiveEvent(_ event: ChatistAnalyticsEvent) {
        print("📊 Analytics Event: \(event.name)")
        print("   Properties: \(event.properties)")
        print("   Timestamp: \(event.timestamp)")
        print("   SDK Version: \(event.sdkVersion)")
        print("   Customer ID: \(event.customerId ?? "nil")")
        print("   Original Customer ID: \(event.originalCustomerId ?? "nil")")
        print("   ---")
    }

    func didUpdateUserProperties(_ properties: [String: Any]) {
        print("📊 Analytics User Properties Updated: \(properties)")
    }

    func didUpdateUserID(_ userId: String?) {
        print("📊 Analytics User ID Updated: \(userId ?? "nil")")
    }
}

