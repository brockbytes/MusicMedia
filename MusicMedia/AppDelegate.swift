import UIKit
import Firebase
import FirebaseAuth
import BackgroundTasks

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Configure Firebase before doing anything else
        FirebaseApp.configure()
        
        // Get Firebase Auth instance
        let auth = Auth.auth()
        
        // Add auth state listener to monitor sign-in status
        auth.addStateDidChangeListener { [weak self] (auth, user) in
            if let user = user {
                print("User is signed in with ID: \(user.uid)")
                // Ensure user data is properly cached
                UserDefaults.standard.set(user.uid, forKey: "lastSignedInUser")
                
                // Attempt to restore the user's session
                if let currentUser = auth.currentUser {
                    print("Current user session is valid")
                    NotificationCenter.default.post(name: NSNotification.Name("UserSessionRestored"), object: nil, userInfo: ["userId": currentUser.uid])
                }
            } else {
                print("User is signed out")
                UserDefaults.standard.removeObject(forKey: "lastSignedInUser")
            }
        }
        
        // Register for background fetch
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.brockton.MusicMedia.fetch", using: nil) { task in
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
        
        return true
    }
    
    func application(_ application: UIApplication,
                    performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // Handle background fetch for iOS 12 and earlier
        handleLegacyBackgroundFetch(completionHandler: completionHandler)
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        scheduleAppRefresh()
    }
    
    private func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.brockton.MusicMedia.fetch")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // Refresh no earlier than 15 minutes
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule app refresh: \(error)")
        }
    }
    
    private func handleAppRefresh(task: BGAppRefreshTask) {
        // Create a task that will be called before the background task is terminated
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        // Perform the background fetch
        Task {
            do {
                // Add your background refresh logic here
                // For example, update currently playing music info, check for nearby listeners, etc.
                
                task.setTaskCompleted(success: true)
                scheduleAppRefresh() // Schedule the next refresh
            } catch {
                task.setTaskCompleted(success: false)
            }
        }
    }
    
    private func handleLegacyBackgroundFetch(completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        Task {
            do {
                // Add your background fetch logic here
                // For example, update currently playing music info, check for nearby listeners, etc.
                
                completionHandler(.newData)
            } catch {
                completionHandler(.failed)
            }
        }
    }
} 