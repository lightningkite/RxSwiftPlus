//
//  AppDelegate.swift
//
//  Created by Joseph Ivie on 2/18/19.
//  Copyright © 2019 Lightning Kite. All rights reserved.
//

import UIKit

open class ViewGeneratorAppDelegate: UIResponder, UIApplicationDelegate {

    public var window: UIWindow?
    public var viewController: ViewGeneratorViewController?
    open var main: ViewGenerator?
    
    open func makeViewController() -> ViewGeneratorViewController {
        let vc = makeMain()
        main = vc
        return ViewGeneratorViewController(vc)
    }
    open func makeMain() -> ViewGenerator {
        fatalError("Not implemented")
    }
    
    open func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { fatalError() }
        var items: Dictionary<String, String> = [:]
        for item in components.queryItems ?? [] {
            items[item.name] = item.value
        }
        if let main = main as? EntryPoint {
            main.handleDeepLink(
                schema: components.scheme ?? "",
                host: components.host ?? "",
                path: components.path,
                params: items
            )
        }
        return true
    }

    open func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        window = UIWindow(frame: UIScreen.main.bounds)
        let nav = SpecialNavController()
        let vc = makeViewController()
        nav.viewControllers = [vc]
        viewController = vc
        window?.rootViewController = nav
        window?.makeKeyAndVisible()
        
        return true
    }

    // Respond to Universal Links
    public func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
                    let url = userActivity.webpageURL,
                    let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
                        return false
                }
        var items: Dictionary<String, String> = [:]
        for item in components.queryItems ?? [] {
            items[item.name] = item.value
        }
        if let main = main as? EntryPoint {
            main.handleDeepLink(
                schema: components.scheme ?? "",
                host: components.host ?? "",
                path: components.path,
                params: items
            )
        }
        return true
    }
}

