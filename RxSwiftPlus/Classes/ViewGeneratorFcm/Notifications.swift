//
//  Notifications.swift
//
//  Created by Joseph Ivie on 1/21/20.
//  Copyright © 2020 Lightning Kite. All rights reserved.
//

import Foundation
import FirebaseCore
import FirebaseMessaging
import KhrysalisRuntime
import RxSwift

public class Notifications {
    static public var useCritical = true
    static public let INSTANCE = Notifications()
    
    public let notificationToken = ValueSubject<String?>(nil)
    public func hasPermission(onResult: @escaping (Bool)->Void) {
        UNUserNotificationCenter.current().getNotificationSettings { it in
            onResult(it.authorizationStatus.rawValue >= UNAuthorizationStatus.authorized.rawValue)
        }
    }
    public func request(insistMessage: String? = nil, onResult: @escaping (Bool)->Void = { _ in }) {
        UNUserNotificationCenter.current().getNotificationSettings { it in
            if it.authorizationStatus.rawValue >= UNAuthorizationStatus.authorized.rawValue {
                onResult(true)
                return
            } else if it.authorizationStatus == .notDetermined {
                var options: UNAuthorizationOptions = [.alert, .sound, .badge]
                if #available(iOS 12.0, *) {
                    if Notifications.useCritical {
                        options = [.alert, .sound, .badge, .criticalAlert]
                    }
                }
                UNUserNotificationCenter.current().requestAuthorization(options: options, completionHandler: { (success, error) in
                    if success, let token = Messaging.messaging().fcmToken {
                        Notifications.INSTANCE.notificationToken.value = token
                    }
                    onResult(success)
                })
            } else if let insistMessage = insistMessage {
                DispatchQueue.main.async {
                    showDialog(request: DialogRequest(
                        string: insistMessage,
                        confirmation: { () in
                            DispatchQueue.main.async {
                                guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                                    return
                                }
                                if UIApplication.shared.canOpenURL(settingsUrl) {
                                    if #available(iOS 10.0, *) {
                                        UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                                            
                                        })
                                    } else {
                                        UIApplication.shared.openURL(settingsUrl as URL)
                                    }
                                }
                            }
                        }
                    ))
                }
            }
        }
    }
    public func configure(_ dependency: ViewControllerAccess){
        request(insistMessage:"Notification are required for this app to work correctly. Open Settings?")
    }
}
