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

enum TestCategory: String, SloggerCategory {
  case First, Second

  static let allValues = [First, Second]
}

class TestLogger: Slogger<TestCategory> {
  init() {
    super.init(defaultLevel: .info)
    self.asynchronous = false
  }
}

private let testDestination = MemoryDestination()
private let log = TestLogger()

class SloggerTests: XCTestCase {

  override func setUp() {
    super.setUp()
  }

  override func tearDown() {
    super.tearDown()
  }

  func checkForMessage (message: String, category: TestCategory?, override: Level?, level: Level, function: String, checkResults: Bool) {
    guard checkResults && log.canLog(override: override, category: category, siteLevel: level) else {
      return
    }

    guard let last = testDestination.lastLine else {
      return
    }

    let prefix = (override != nil) ? "* " : "- "
    XCTAssert(last.contains(prefix), "Incorrect Radioactive Trace Prefix")
    XCTAssert(last.contains(" \(level) "), "Incorrect level")
    XCTAssert(last.contains(": \(message)"), "Incorrect message")
    XCTAssert(last.contains(" SloggerTests.swift "), "Incorrect file")
    XCTAssert(last.contains(" \(function) "), "Incorrect function")
    if category == nil {
      XCTAssert(last.contains(" [] "), "Incorrect function")
    } else {
      XCTAssert(last.contains(" [\(category!)] "), "Incorrect function")
    }
  }

  func callIt (category: TestCategory?, override: Level?, level: Level, checkResults: Bool) {
    switch (level) {
    case .off:
      log.none(category, "String", override: override)
			checkForMessage(message: "String", category: category, override: override, level: level, function: #function, checkResults: checkResults)
      log.none(category, override: override) { "Closure" }
      checkForMessage(message: "Closure", category: category, override: override, level: level, function: #function, checkResults: checkResults)

    case .severe:
      log.severe(category, "String", override: override)
      checkForMessage(message: "String", category: category, override: override, level: level, function: #function, checkResults: checkResults)
      log.severe(category, override: override) { "Closure" }
      checkForMessage(message: "Closure", category: category, override: override, level: level, function: #function, checkResults: checkResults)

    case .error:
      log.error(category, "String", override: override)
      checkForMessage(message: "String", category: category, override: override, level: level, function: #function, checkResults: checkResults)
      log.error(category, override: override) { "Closure" }
      checkForMessage(message: "Closure", category: category, override: override, level: level, function: #function, checkResults: checkResults)

    case .warning:
      log.warning(category, "String", override: override)
      checkForMessage(message: "String", category: category, override: override, level: level, function: #function, checkResults: checkResults)
      log.warning(category, override: override) { "Closure" }
      checkForMessage(message: "Closure", category: category, override: override, level: level, function: #function, checkResults: checkResults)

    case .info:
      log.info(category, "String", override: override)
      checkForMessage(message: "String", category: category, override: override, level: level, function: #function, checkResults: checkResults)
      log.info(category, override: override) { "Closure" }
      checkForMessage(message: "Closure", category: category, override: override, level: level, function: #function, checkResults: checkResults)

    case .debug:
      log.debug(category, "String", override: override)
      checkForMessage(message: "String", category: category, override: override, level: level, function: #function, checkResults: checkResults)
      log.debug(category, override: override) { "Closure" }
      checkForMessage(message: "Closure", category: category, override: override, level: level, function: #function, checkResults: checkResults)

    case .verbose:
      log.verbose(category, "String", override: override)
      checkForMessage(message: "String", category: category, override: override, level: level, function: #function, checkResults: checkResults)
      log.verbose(category, override: override) { "Closure" }
      checkForMessage(message: "Closure", category: category, override: override, level: level, function: #function, checkResults: checkResults)
    }
  }

  func exhaustiveTest (destinations: [Destination], checkResults: Bool = true, verbose: Bool = false) {
    let levels = Level.allValues
    let categories = TestCategory.allValues

    log.hits = 0
    log.misses = 0
    log.destinations = destinations


    func sloggit (category: TestCategory?, override: Level? = nil, checkResults: Bool) {
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
    log.destinations = [ConsoleDestination(), testDestination]

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
    testDestination.clear()
    self.exhaustiveTest(destinations: [ConsoleDestination()], checkResults: false, verbose: true)
  }

  func testNoConsole () {
    log.destinations = [testDestination]
    testDestination.clear()
    self.exhaustiveTest(destinations: [testDestination], checkResults: true)
  }

  func testPlainFileLogging () {
    let dir = "~/Desktop/SloggerTestLogs" as NSString
    let path = dir.expandingTildeInPath
    let dest = TextFileDestination(directory: path)

    print("Testing plain file logging to path: \(path)")
    self.exhaustiveTest(destinations: [dest], checkResults: false, verbose: false)
  }

  func testJSONFileLogging () {
    let dir = "~/Desktop/SloggerTestLogs" as NSString
    let path = dir.expandingTildeInPath
    let dest = JSONFileDestination(directory: path)

    print("Testing JSON file logging to path: \(path)")
    self.exhaustiveTest(destinations: [dest], checkResults: false, verbose: false)
  }

  func testXMLFileLogging () {
    let dir = "~/Desktop/SloggerTestLogs" as NSString
    let path = dir.expandingTildeInPath
    let dest = XMLFileDestination(directory: path)

    print("Testing JSON file logging to path: \(path)")
    self.exhaustiveTest(destinations: [dest], checkResults: false, verbose: false)
  }

  func testCSVFileLogging () {
    let dir = "~/Desktop/SloggerTestLogs" as NSString
    let path = dir.expandingTildeInPath
    let dest = CSVFileDestination(directory: path)

    print("Testing CSV file logging to path: \(path)")
    self.exhaustiveTest(destinations: [dest], checkResults: false, verbose: false)
  }

  func testTSVFileLogging () {
    let dir = "~/Desktop/SloggerTestLogs" as NSString
    let path = dir.expandingTildeInPath
    let dest = TSVFileDestination(directory: path)

    print("Testing TSV file logging to path: \(path)")
    self.exhaustiveTest(destinations: [dest], checkResults: false, verbose: false)
  }

}
