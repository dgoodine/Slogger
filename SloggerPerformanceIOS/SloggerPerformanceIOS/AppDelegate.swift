//
//  AppDelegate.swift
//  SloggerPerformanceIOS
//
//  Created by David Goodine on 10/29/15.
//  Copyright © 2015 David Goodine. All rights reserved.
//

import UIKit
import Slogger

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

    let storyboard = UIStoryboard(name: "Main", bundle: nil)
    let vc = storyboard.instantiateInitialViewController();
    window = UIWindow(frame: UIScreen.main.bounds)
    window!.rootViewController = vc
    window?.makeKeyAndVisible()

    let performanceTest = PerformanceTest()
    performanceTest.test()

    return true
  }
}

