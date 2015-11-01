//
//  PerformanceTest.swift
//  Slogger
//
//  Created by David Goodine on 10/29/15.
//  Copyright © 2015 David Goodine. All rights reserved.
//

import Foundation

/// Simple performance test for logging.
public class PerformanceTest {

  /// Category enum
  private enum PerformanceCategory : String, SloggerCategory {
    case Only
  }

  /// Initializer
  public init () {}

  /// Test Function
  public func test () {
    testWithDestinations(MemoryDestination(), 100000, .None)
    testWithDestinations(nil, 1000000, .Severe)
    testWithDestinations(MemoryDestination(), 100000, .Severe)
    testWithDestinations(ConsoleDestination(), 1000, .Severe)
  }

  /// Private test implementation.
  private func testWithDestinations (destination : Destination?, _ count : Int, _ level : Level) {
    let log = Slogger<PerformanceCategory>(defaultLevel: level)
    log.destinations = (destination == nil) ? [] : [destination!]

    print("Testing \(log.destinations) with \(count) iterations at level: \(level)")

    let startDate = NSDate()

    for _ in 1...count {
      log.debug(.Only, "LogMessage")
    }

    let endDate = NSDate()
    let interval = endDate.timeIntervalSinceDate(startDate)

    print("Elapsed: \(intervalToString(interval)), Per Call time: \(intervalToString(interval / Double(count)))")
  }

  /// Helper function for human-readable output.
  private func intervalToString (interval : Double) -> String {
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
  private func formatInterval (interval : Double) -> String {
    return NSString(format: "%.0f", interval) as String
  }
}