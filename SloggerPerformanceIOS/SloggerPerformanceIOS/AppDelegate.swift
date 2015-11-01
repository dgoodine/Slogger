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

  func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

    let storyboard = UIStoryboard(name: "Main", bundle: nil)
    let vc = storyboard.instantiateInitialViewController();
    window = UIWindow(frame: UIScreen.mainScreen().bounds)
    window!.rootViewController = vc
    window?.makeKeyAndVisible()

    let performanceTest = PerformanceTest()
    performanceTest.test()

    dispatch_async(dispatch_get_main_queue()) {
      exit(0)
    }

    return true
  }
}

