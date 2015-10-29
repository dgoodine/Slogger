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

  static func allValues () -> [TestCategory] {
    return [First, Second]
  }
}

class TestLogger : Slogger<TestCategory> {
  init (destination : Destination) {
    super.init(defaultLevel: Level.Info)
    destinations.append(destination)
  }
}

let testDestination = MemoryDestination()

#if DEBUG
let log = Slogger<NoCategories>(defaultLevel: .Info)
#else
let log = Slogger<NoCategories>(defaultLevel: .Warning)
#endif

class SloggerTests: XCTestCase {
  let log = TestLogger(destination: testDestination)

  override func setUp() {
    super.setUp()
    testDestination.generator = log.defaultGenerator
  }

  override func tearDown() {
    super.tearDown()
  }

  func otestBasic () {
    log.error("Message")

    log.error(.First, "Message")

    log.error() {
      return "Closure Message"
    }

    log.error(.First) {
      return "Closure Message"
    }

    log.verbose("Message")
    log.verbose("Message", override: true)

    log.verbose(.First, "Message")

    log.verbose() { "Closure Message" }
    log.verbose(nil, override: true) { "Closure Message" }

    log.verbose(.First) { "Closure Message" }
    log.verbose(.First, override: true) { "Closure Message" }
  }

  func exhaustiveTestWithDestinations (destinations : [Destination], checkResults: Bool = true, verbose: Bool = false) {
    let levels = Level.allValues()
    let categories = TestCategory.allValues()

    log.hits = 0
    log.misses = 0
    log.destinations = destinations

    func checkForMessage (message: String, _ override: Bool, _ category: TestCategory?, _ level: Level, _ function: String) {
      guard checkResults && log.canLogWithOverride(override, category: category, level: level) else {
        return
      }

      let last = testDestination.lastLine
      guard last != nil || override else {
        return
      }

      if let last = last {
        let prefix = (override) ? "* " : "- "
        XCTAssert(last.containsString(prefix), "Incorrect Radioactive Trace Prefix")
        XCTAssert(last.containsString(" \(level): "), "Incorrect level")
        XCTAssert(last.containsString(": \(message)"), "Incorrect message")
        XCTAssert(last.containsString(" SloggerTests.swift:"), "Incorrect file")
        XCTAssert(last.containsString(" \(function)"), "Incorrect function")
        if category == nil {
          XCTAssert(last.containsString(" [] "), "Incorrect function")
        } else {
          XCTAssert(last.containsString(" [\(category!)] "), "Incorrect function")
        }
      }
    }

    func callIt (category: TestCategory?, _ level: Level) {
      switch (level) {
      case .None:
        checkForMessage("String", false, category, level, __FUNCTION__)
        checkForMessage("Closure", false, category, level, __FUNCTION__)

      case .Severe:
        log.severe(category, "String")
        checkForMessage("String", false, category, level, __FUNCTION__)
        log.severe(category) { "Closure" }
        checkForMessage("Closure", false, category, level, __FUNCTION__)

      case .Error:
        log.error(category, "String")
        checkForMessage("String", false, category, level, __FUNCTION__)
        log.error(category) { "Closure" }
        checkForMessage("Closure", false, category, level, __FUNCTION__)

      case .Warning:
        log.warning(category, "String")
        checkForMessage("String", false, category, level, __FUNCTION__)
        log.warning(category) { "Closure" }
        checkForMessage("Closure", false, category, level, __FUNCTION__)

      case .Info:
        log.info(category, "String")
        checkForMessage("String", false, category, level, __FUNCTION__)
        log.info(category) { "Closure" }
        checkForMessage("Closure", false, category, level, __FUNCTION__)

      case .Debug:
        log.debug(category, "String")
        checkForMessage("String", false, category, level, __FUNCTION__)
        log.debug(category) { "Closure" }
        checkForMessage("Closure", false, category, level, __FUNCTION__)

      case .Verbose:
        log.verbose(category, "String")
        checkForMessage("String", false, category, level, __FUNCTION__)
        log.verbose(category) { "Closure" }
        checkForMessage("Closure", false, category, level, __FUNCTION__)
      }
    }

    func sloggit (category: TestCategory?) {
      for level in levels {
        testDestination.clear()
        callIt(category, level)
      }
    }

    // Execute the tests
    for setLevel in levels {
      if verbose {
        print("Setting log level: \(setLevel)")
      }
      log.currentLevel = setLevel

      if setLevel == .None {
        // Radioactive trace
        log.verbose("String", override: true)
        checkForMessage("String", true, nil, .Verbose, __FUNCTION__)
        log.verbose(nil, override: true) { "Closure" }
        checkForMessage("Closure", true, nil, .Verbose, __FUNCTION__)

      }

      sloggit(nil)
      for category in categories {
        sloggit(category)
      }
    }

    if verbose {
      print("Logged entries: \(log.hits), Log calls \(log.hits + log.misses)")
    }
  }

  func testConsole () {
    testDestination.clear()
    self.exhaustiveTestWithDestinations([self.log.consoleDestination], checkResults: false, verbose: true)
  }

  func testNoConsole () {
    testDestination.clear()
    self.exhaustiveTestWithDestinations([testDestination], checkResults: true)
  }

  func testNoLoggers () {
    testDestination.clear()
    self.exhaustiveTestWithDestinations([], checkResults: false)
  }
}



































