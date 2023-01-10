//
//  AppDelegate.swift
//  RxSwiftPlus
//
//  Created by UnknownJoe796 on 08/30/2021.
//  Copyright (c) 2021 UnknownJoe796. All rights reserved.
//

import UIKit
import Firebase
import FirebaseMessaging

open class ViewGeneratorFcmDelegate: ViewGeneratorAppDelegate, MessagingDelegate, UNUserNotificationCenterDelegate  {
    
    override func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]?) -> Bool {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
        
        UIApplication.shared.registerForRemoteNotifications()
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    override func makeMain() -> ViewGenerator {
        //        fatalError()
        UIView.backgroundLayersByName = R.drawable.allEntries
        UIView.useLayoutSubviewsLambda()
        return RootVG()
    }
    
    public func messaging(
        _ messaging: Messaging,
        didReceiveRegistrationToken fcmToken: String?
    ) {
        Notifications.INSTANCE.notificationToken.value = fcmToken
    }
    
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ){
        var result = ForegroundNotificationHandlerResult.UNHANDLED
        if let entryPoint = self.viewController?.main as? ForegroundNotificationHandler {
            let info = notification.request.content.userInfo
            result = entryPoint.handleNotificationInForeground(
                Dictionary(uniqueKeysWithValues:
                    info
                        .filter { it in it.key is String && it.value is String }
                        .map { ($0.key as! String, $0.value as! String) }
                )
            )
           
        }
        completionHandler(result == .SUPPRESS_NOTIFICATION ? [] : [.alert, .badge, .sound])
    }
    
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ){
        completionHandler()
    }
}
