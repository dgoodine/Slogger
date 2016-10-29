//
//  PerformanceTest.swift
//  Slogger
//
//  Created by David Goodine on 10/29/15.
//  Copyright © 2015 David Goodine. All rights reserved.
//

import Foundation

/// Simple performance test for logging.
open class PerformanceTest {

  // This code was found at Stack Overflow:
  // http://stackoverflow.com/questions/26028918/ios-how-to-determine-iphone-model-in-swift
  let device: String = {
    var systemInfo = utsname()
    uname(&systemInfo)
    let machineMirror = Mirror(reflecting: systemInfo.machine)
    let identifier = machineMirror.children.reduce("") { identifier, element in
      guard let value = element.value as? Int8 , value != 0 else { return identifier }
      return identifier + String(UnicodeScalar(UInt8(value)))
    }

    switch identifier {
    case "iPod5,1":                                 return "iPod Touch 5"
    case "iPod7,1":                                 return "iPod Touch 6"
    case "iPhone3,1", "iPhone3,2", "iPhone3,3":     return "iPhone 4"
    case "iPhone4,1":                               return "iPhone 4s"
    case "iPhone5,1", "iPhone5,2":                  return "iPhone 5"
    case "iPhone5,3", "iPhone5,4":                  return "iPhone 5c"
    case "iPhone6,1", "iPhone6,2":                  return "iPhone 5s"
    case "iPhone7,2":                               return "iPhone 6"
    case "iPhone7,1":                               return "iPhone 6 Plus"
    case "iPhone8,1":                               return "iPhone 6s"
    case "iPhone8,2":                               return "iPhone 6s Plus"
    case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":return "iPad 2"
    case "iPad3,1", "iPad3,2", "iPad3,3":           return "iPad 3"
    case "iPad3,4", "iPad3,5", "iPad3,6":           return "iPad 4"
    case "iPad4,1", "iPad4,2", "iPad4,3":           return "iPad Air"
    case "iPad5,1", "iPad5,3", "iPad5,4":           return "iPad Air 2"
    case "iPad2,5", "iPad2,6", "iPad2,7":           return "iPad Mini"
    case "iPad4,4", "iPad4,5", "iPad4,6":           return "iPad Mini 2"
    case "iPad4,7", "iPad4,8", "iPad4,9":           return "iPad Mini 3"
    case "iPad5,1", "iPad5,2":                      return "iPad Mini 4"
    case "i386", "x86_64":                          return "Simulator"
    default:                                        return "Unknown"
    }
  }()

  /// Markdown table rows
  var mdStrings: [String] = []

  /// Category enum
  fileprivate enum PerformanceCategory: String, SloggerCategory {
    case Only
  }

  /// Initializer
  public init () {}

  /// Test Function
  open func test () {
    let dir = NSTemporaryDirectory() + "/SloggerTestLogs" as NSString
    let path = dir.expandingTildeInPath
    print("Testing JSON: \(path)")
    testWithDestinations(JSONFileDestination(directory: path), 1000, .severe)
    testWithDestinations(JSONFileDestination(directory: path), 1000, .verbose)
    print("Testing XML: \(path)")
    testWithDestinations(XMLFileDestination(directory: path), 1000, .severe)
    testWithDestinations(XMLFileDestination(directory: path), 1000, .verbose)
    self.testWithDestinations(nil, 100000, .verbose)
    self.testWithDestinations(MemoryDestination(), 1000, .severe)
    self.testWithDestinations(MemoryDestination(), 1000, .verbose)
    self.testWithDestinations(ConsoleDestination(), 1000, .severe)
    self.testWithDestinations(ConsoleDestination(), 1000, .verbose)

    let delay = DispatchTime.now() + Double(Int64(5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
    DispatchQueue.main.asyncAfter(deadline: delay) {
      print("\nMarkdown table output:\n")
      print("Device | Destinations | Level | Can Log | log.Debug(.Only, \"Message\")")
      print("--- | --- | --- | --- | ---")
      for mdString in self.mdStrings {
        print(mdString)
      }
      print("")
    }
  }

  /// Private test implementation.
  fileprivate func testWithDestinations (_ destination: Destination?, _ count: Int, _ level: Level) {
    let log = Slogger<PerformanceCategory>(defaultLevel: level)
    log.destinations = (destination == nil) ? [] : [destination!]

    print("Testing \(log.destinations) with \(count) iterations at level: \(level)")

    let startDate = Date()

    for _ in 1...count {
      log.debug(.Only, "LogMessage")
    }

    let endDate = Date()
    let interval = endDate.timeIntervalSince(startDate)

    let elapsed = intervalToString(interval)
    let perCall = intervalToString(interval / Double(count))

    let dString = (log.destinations.count > 0) ? "[\(type(of: log.destinations[0]))]" : "[]"
    let canLog = log.canLog(override: nil, category: .Only, siteLevel: .debug)
    let mdString = "\(device) | \(dString) | \(level) | \(canLog) | \(perCall)"
    mdStrings.append(mdString)

    print("Elapsed: \(elapsed), Per Call time: \(perCall)")
  }

  /// Helper function for human-readable output.
  fileprivate func intervalToString (_ interval: Double) -> String {
    if interval > 1.0 {
      return "\(formatInterval(interval))s"
    } else if interval > 0.001 {
      return "\(formatInterval(interval * 1000))ms"
    } else if interval > 0.000001 {
      return "\(formatInterval(interval * 1000000))µs"
    } else if interval > 0.000000001 {
      return "\(formatInterval(interval * 1000000000))ns"
    }
    return "\(interval)"
  }

  /// Cuz meh.
  fileprivate func formatInterval (_ interval: Double) -> String {
    return NSString(format: "%.0f", interval) as String
  }
}
