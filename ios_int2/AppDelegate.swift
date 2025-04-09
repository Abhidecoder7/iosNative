import UIKit
import CleverTapSDK
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, CleverTapInAppNotificationDelegate {
    
    var window: UIWindow?

    // MARK: - MAIN Function
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Initialize CleverTap

        
        CleverTap.autoIntegrate()
        CleverTap.setDebugLevel(CleverTapLogLevel.debug.rawValue)
        CleverTap.sharedInstance()?.setInAppNotificationDelegate(self)
        
        // Initialize Inbox
        CleverTap.sharedInstance()?.initializeInbox { success in
            let messageCount = CleverTap.sharedInstance()?.getInboxMessageCount() ?? 0
            let unreadCount = CleverTap.sharedInstance()?.getInboxMessageUnreadCount() ?? 0
            print("Inbox Message: \(messageCount) total, \(unreadCount) unread")
        }

        registerForPush()

        // Setup Notification Categories
        let action1 = UNNotificationAction(identifier: "action_1", title: "Back", options: [])
        let action2 = UNNotificationAction(identifier: "action_2", title: "Next", options: [])
        let action3 = UNNotificationAction(identifier: "action_3", title: "View In App", options: [])
        let category = UNNotificationCategory(identifier: "CTNotification", actions: [action1, action2, action3], intentIdentifiers: [], options: [])
        UNUserNotificationCenter.current().setNotificationCategories([category])

        return true
    }

    // MARK: - Register for Push Notifications
    func registerForPush() {
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.sound, .badge, .alert]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }

    // MARK: - CleverTap In-App Button Handling
    func inAppNotificationButtonTapped(withCustomExtras customExtras: [AnyHashable: Any]!) {
        print("In-App Button Tapped with custom extras:", customExtras ?? "No extras")
    }

    // MARK: - Handle Push Notifications
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        CleverTap.sharedInstance()?.handleNotification(withData: notification.request.content.userInfo, openDeepLinksInForeground: true)
        completionHandler([.badge, .sound, .alert])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        CleverTap.sharedInstance()?.handleNotification(withData: response.notification.request.content.userInfo)
        completionHandler()
    }

    // MARK: - Show Push Primer
//    func showPushPrimer() {
//        let localInAppBuilder = CTLocalInApp(
//            inAppType: .HALF_INTERSTITIAL,
//            titleText: "Stay Updated!",
//            messageText: "Enable notifications to receive real-time updates.",
//            followDeviceOrientation: true,
//            positiveBtnText: "Allow",
//            negativeBtnText: "Cancel"
//        )
//
//        // UI Customizations (Optional)
//        localInAppBuilder.setFallbackToSettings(true) // Redirect to settings if denied
//        localInAppBuilder.setBackgroundColor("#FFFFFF")
//        localInAppBuilder.setTitleTextColor("#000000")
//        localInAppBuilder.setMessageTextColor("#333333")
//        localInAppBuilder.setBtnBorderRadius("6")
//        localInAppBuilder.setBtnTextColor("#FFFFFF")
//        localInAppBuilder.setBtnBorderColor("#007AFF")
//        localInAppBuilder.setBtnBackgroundColor("#007AFF")
//        localInAppBuilder.setImageUrl("https://icons.iconarchive.com/icons/treetog/junior/64/camera-icon.png")
//
//        // Show Push Primer
//        CleverTap.sharedInstance()?.promptPushPrimer(localInAppBuilder.getSettings())
//    }
}
