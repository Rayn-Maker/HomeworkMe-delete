//
//  AppDelegate.swift
//  HomeworkMe
//
//  Created by Radiance Okuzor on 8/1/18.
//  Copyright © 2018 RayCo. All rights reserved.
//

import UIKit
import CoreData
import Firebase
import FirebaseDatabase
import FirebaseMessaging
import FirebaseInstanceID
import Stripe
import SquarePointOfSaleSDK
import GooglePlaces
import GoogleMaps
import GoogleSignIn
import FacebookLogin
import FBSDKLoginKit
import FacebookCore
import UserNotifications
import AudioToolbox



@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, GIDSignInDelegate, UNUserNotificationCenterDelegate  {

    var window: UIWindow?
    var seconds = 1200
    var timer = Timer()
    var isTimerRunning = false
    var isGrantedAccess = false
    
    //Notificaiton Var
    static let NOTIFICATION_URL = "https://gcm-http.googleapis.com/gcm/send"
    static var DEVICEID = String()
    
    static let SERVERKEY = "AAAAEwJPepM:APA91bGjsWw0SMNXJZGDeGzDJmqgS8FXK5cYy863_5hNkQLpneX5fW-zOVjoUxgA14Ioc6bm7Fvbkryb6ps-GG-KIIUuVEALqedTOlGXc8CjoXiPoDNZ4lGDaXwaPXMCMlB_cfWgv9mHdagbqLOJAXTqgmfUCav1-Q"
    

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        STPPaymentConfiguration.shared().publishableKey = Constants.publishableKey
        FirebaseApp.configure()
        GMSPlacesClient.provideAPIKey("AIzaSyDV7NWQ25BT5pISVM5b9vkRFJrK8TjXypY")
        GMSServices.provideAPIKey("AIzaSyDV7NWQ25BT5pISVM5b9vkRFJrK8TjXypY")
        logUser()
        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
        GIDSignIn.sharedInstance().delegate = self
        // Notification implementation
        if #available(iOS 10.0, *)
        {
            UNUserNotificationCenter.current().delegate = self
            
            let option : UNAuthorizationOptions = [.alert,.badge,.sound]
            UNUserNotificationCenter.current().requestAuthorization(options: option, completionHandler: { (bool, err) in
                
            })
            
        }else{
            let settings : UIUserNotificationSettings = UIUserNotificationSettings(types: [.alert,.badge,.sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        
        application.registerForRemoteNotifications()
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        return FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    //notifications configuration
    func messaging(_ messaging: Messaging, didRefreshRegistrationToken fcmToken: String) {
        guard  let newToken = InstanceID.instanceID().token() else {return}
        AppDelegate.DEVICEID = newToken
        connectToFCM()
    }
    
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let notification =  response.notification.request.content.body
        
        print(notification)
        
        completionHandler()
    }
    
    @available(iOS 10.0, *)
    func userNotificationCenter(center: UNUserNotificationCenter, willPresentNotification notification: UNNotification, withCompletionHandler completionHandler: (UNNotificationPresentationOptions) -> Void)
    {
        //Handle the notification
        completionHandler(
            [UNNotificationPresentationOptions.alert,
             UNNotificationPresentationOptions.sound,
             UNNotificationPresentationOptions.badge])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void)
    {
        completionHandler([.alert, .badge, .sound])
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        guard let token = InstanceID.instanceID().token() else {return}
        
        AppDelegate.DEVICEID = token
        print(token)
        connectToFCM()
    }
    
    
    func connectToFCM()
    {
        Messaging.messaging().shouldEstablishDirectChannel = true
    }
    
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        if let error = error {
            print(error.localizedDescription)
            return
        }
        let credential = FacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
        
        Auth.auth().signInAndRetrieveData(with: credential) { (authResult, error) in
            if let error = error {
                // ...
                return
            }
            // User is signed in
            // ...
        }
    }
    
    func logUser(){
        if Auth.auth().currentUser != nil {
            let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "userProfile") as! ProfileVC
            self.window?.rootViewController = vc
            
            
        }
        
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error?) {
        // ...
        if let error = error {
            // ...
            return
        }
        
        guard let authentication = user.authentication else { return }
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken,
                                                       accessToken: authentication.accessToken)
        // ...
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        // Perform any operations when the user disconnects from app here.
        // ...
    }
    
    @available(iOS 9.0, *)
    func application(_ application: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any])-> Bool {
        
        return SDKApplicationDelegate.shared.application(application, open: url, options: options)
        
        let stripeHandled = Stripe.handleURLCallback(with: url)
        
        if (stripeHandled) {
            return true
        }
        else {
            // This was not a stripe url, do whatever url handling your app
            // normally does, if any.
        }
        
        guard let sourceApplication = options[.sourceApplication] as? String,
            sourceApplication.hasPrefix("com.squareup.square") else {
                return false
        }
        
        do {
            let response = try SCCAPIResponse(responseURL: url)
            
            if let error = response.error {
                // Handle a failed request.
                print(error.localizedDescription)
            } else {
                // Handle a successful request.
            }
            
        } catch let error as NSError {
            // Handle unexpected errors.
            print(error.localizedDescription)
        }
        
        return GIDSignIn.sharedInstance().handle(url as URL?,
                                                 sourceApplication: options[UIApplicationOpenURLOptionsKey.sourceApplication] as? String,
                                                 annotation: options[UIApplicationOpenURLOptionsKey.annotation])
        
    }
    
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return GIDSignIn.sharedInstance().handle(url,
                                                 sourceApplication: sourceApplication,
                                                 annotation: annotation)
        return FBSDKApplicationDelegate.sharedInstance().application(application, open: url, sourceApplication: sourceApplication, annotation: annotation)
        
    }

    
    // This method is where you handle URL opens if you are using univeral link URLs (eg "https://example.com/stripe_ios_callback")
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb {
            if let url = userActivity.webpageURL {
                let stripeHandled = Stripe.handleURLCallback(with: url)
                
                if (stripeHandled) {
                    return true
                }
                else {
                    // This was not a stripe url, do whatever url handling your app
                    // normally does, if any.
                }
            }
            
        }
        return false 
    }
        

    func applicationWillResignActive(_ application: UIApplication) {
        FBSDKAppEvents.activateApp()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "HomeworkMe")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

}

