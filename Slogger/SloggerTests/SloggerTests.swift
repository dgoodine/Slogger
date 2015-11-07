//
//  SloggerTests.swift
//  SloggerTests
//
//  Created by David Goodine on 10/20/15.
//  Copyright © 2015 David Goodine. All rights reserved.
//

import XCTest

#if os(iOS)
@testable import Slogger
#elseif os(OSX)
@testable import SloggerOSX
#endif

enum TestCategory : String, SloggerCategory {
  case First, Second

  static let allValues = [First, Second]
}

class TestLogger : Slogger<TestCategory>
{
  init() {
    super.init(defaultLevel: .Info)
    self.asynchronous = false
  }
}

let testDestination = MemoryDestination()
let log = TestLogger()

class SloggerTests: XCTestCase {

  override func setUp() {
    super.setUp()
    testDestination.generator = log.defaultGenerator
  }

  override func tearDown() {
    super.tearDown()
  }

  func checkForMessage (message: String, _ category: TestCategory?, _ override: Level?, _ level: Level, _ function: String,  _ checkResults: Bool) {
    guard checkResults && log.canLog(override: override, category: category, siteLevel: level) else {
      return
    }

    guard let last = testDestination.lastLine else {
      return
    }

    let prefix = (override != nil) ? "* " : "- "
    XCTAssert(last.containsString(prefix), "Incorrect Radioactive Trace Prefix")
    XCTAssert(last.containsString(" \(level) "), "Incorrect level")
    XCTAssert(last.containsString(": \(message)"), "Incorrect message")
    XCTAssert(last.containsString(" SloggerTests.swift "), "Incorrect file")
    XCTAssert(last.containsString(" \(function) "), "Incorrect function")
    if category == nil {
      XCTAssert(last.containsString(" [] "), "Incorrect function")
    } else {
      XCTAssert(last.containsString(" [\(category!)] "), "Incorrect function")
    }
  }

  func callIt (category category: TestCategory?, override: Level?, level: Level, checkResults : Bool) {
    switch (level) {
    case .None:
      log.none(category, "String", override: override)
      checkForMessage("String", category, override, level, __FUNCTION__, checkResults)
      log.none(category, override: override) { "Closure" }
      checkForMessage("Closure", category, override, level, __FUNCTION__, checkResults)

    case .Severe:
      log.severe(category, "String", override: override)
      checkForMessage("String", category, override, level, __FUNCTION__, checkResults)
      log.severe(category, override: override) { "Closure" }
      checkForMessage("Closure", category, override, level, __FUNCTION__, checkResults)

    case .Error:
      log.error(category, "String", override: override)
      checkForMessage("String", category, override, level, __FUNCTION__, checkResults)
      log.error(category, override: override) { "Closure" }
      checkForMessage("Closure", category, override, level, __FUNCTION__, checkResults)

    case .Warning:
      log.warning(category, "String", override: override)
      checkForMessage("String", category, override, level, __FUNCTION__, checkResults)
      log.warning(category, override: override) { "Closure" }
      checkForMessage("Closure", category, override, level, __FUNCTION__, checkResults)

    case .Info:
      log.info(category, "String", override: override)
      checkForMessage("String", category, override, level, __FUNCTION__, checkResults)
      log.info(category, override: override) { "Closure" }
      checkForMessage("Closure", category, override, level, __FUNCTION__, checkResults)

    case .Debug:
      log.debug(category, "String", override: override)
      checkForMessage("String", category, override, level, __FUNCTION__, checkResults)
      log.debug(category, override: override) { "Closure" }
      checkForMessage("Closure", category, override, level, __FUNCTION__, checkResults)

    case .Verbose:
      log.verbose(category, "String", override: override)
      checkForMessage("String", category, override, level, __FUNCTION__, checkResults)
      log.verbose(category, override: override) { "Closure" }
      checkForMessage("Closure", category, override, level, __FUNCTION__, checkResults)
    }
  }

  func exhaustiveTest (destinations destinations : [Destination], checkResults: Bool = true, verbose: Bool = false) {
    let levels = Level.allValues
    let categories = TestCategory.allValues

    log.hits = 0
    log.misses = 0
    log.destinations = destinations


    func sloggit (category category: TestCategory?, override: Level? = nil, checkResults : Bool) {
      testDestination.clear()
      for level in levels {
        callIt(category: category, override: override, level: level, checkResults: checkResults)
      }
    }

    // Execute the tests
    for setLevel in levels {
      if verbose {
        print("Setting log level: \(setLevel)")
      }

      log.level = setLevel

      sloggit(category: nil, checkResults: checkResults)
      for category in categories {
        sloggit(category: category, checkResults: checkResults)
      }
    }

    if verbose {
      print("Logged entries: \(log.hits), Total log calls: \(log.hits + log.misses)")
    }
  }

  func testRadioactive () {
    log.destinations = [log.consoleDestination, testDestination]

    print("Testing Radioactive Logging")
    for logLevel in Level.allValues {
      print("Log level: \(logLevel)")
      log.level = logLevel

      for override in Level.allValues {
        print("   Override: \(override)")

        for level in Level.allValues {
          testDestination.clear()
          callIt(category: nil, override: override, level: level, checkResults: true)
          for category in TestCategory.allValues {
            callIt(category: category, override: override, level: level, checkResults: true)
          }
        }
      }
    }

    print("Logged entries: \(log.hits), Total log calls: \(log.hits + log.misses)")
  }

  func testConsole () {
    log.destinations = [log.consoleDestination]
    testDestination.clear()
    self.exhaustiveTest(destinations: [log.consoleDestination], checkResults: false, verbose: true)
  }

  func testNoConsole () {
    log.destinations = [testDestination]
    testDestination.clear()
    self.exhaustiveTest(destinations: [testDestination], checkResults: true)
  }

  func testPlainFileLogging () {
    let dir = "~/Desktop/SloggerTestLogs" as NSString
    let path = dir.stringByExpandingTildeInPath
    let dest = TextFileDestination(directory: path)

    print("Testing plain file logging to path: \(path)")
    self.exhaustiveTest(destinations: [dest], checkResults: false, verbose: false)
  }

  func testJSONFileLogging () {
    let dir = "~/Desktop/SloggerTestLogs" as NSString
    let path = dir.stringByExpandingTildeInPath
    let dest = JSONFileDestination(directory: path)

    print("Testing JSON file logging to path: \(path)")
    self.exhaustiveTest(destinations: [dest], checkResults: false, verbose: false)
  }

}



































