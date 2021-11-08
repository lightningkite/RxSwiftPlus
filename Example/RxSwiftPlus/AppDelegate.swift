//
//  AppDelegate.swift
//  RxSwiftPlus
//
//  Created by UnknownJoe796 on 08/30/2021.
//  Copyright (c) 2021 UnknownJoe796. All rights reserved.
//

import UIKit
import RxSwiftPlus

@UIApplicationMain
class AppDelegate: ViewGeneratorAppDelegate {
    override func makeMain() -> ViewGenerator {
        return RootVG()
    }
}

