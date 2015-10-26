//
//  SloggerTests.swift
//  SloggerTests
//
//  Created by David Goodine on 10/20/15.
//  Copyright © 2015 David Goodine. All rights reserved.
//

import XCTest
@testable import Slogger

enum TestCategory : String, SloggerCategory {
  case First, Second, Third

  static func allValues () -> [TestCategory] {
    return [First, Second, Third]
  }
}

class TestLogger : Slogger<TestCategory> {
  init (destination : Destination) {
    super.init(defaultLevel: Level.Info)
    destinations.append(destination)
  }
}

let testDestination = TestDestination()

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

  func exhaustiveTestWithDestinations (destinations : [Destination], checkResults: Bool = true) {
    let levels = Level.allValues()
    let categories = TestCategory.allValues()
    var lastIndex : Int = 0

    log.hits = 0
    log.misses = 0
    log.destinations = destinations

    func checkForType (type: String, _ condition: Bool, _ category: TestCategory?, _ level: Level, function: String) {
      guard checkResults && log.canLogWithOverride(condition, category: category, level: level) else {
        return
      }

      let last = testDestination[lastIndex]
      XCTAssertEqual(last.containsString(" \(level): "), condition, "Incorrect level")
      XCTAssertEqual(last.containsString(type), condition, "Incorrect message")
      XCTAssertEqual(last.containsString(" SloggerTests.swift:"), condition, "Incorrect file")
      XCTAssertEqual(last.containsString(" \(function)"), condition, "Incorrect function")
      if category == nil {
        XCTAssertEqual(last.containsString(" [] "), condition, "Incorrect function")
      } else {
        XCTAssertEqual(last.containsString(" [\(category!)] "), condition, "Incorrect function")
      }

      lastIndex++
    }

    func checkString (condition: Bool, _ category: TestCategory?, _ level: Level, function: String = __FUNCTION__) {
      checkForType(": String", condition, category, level, function: function)
    }

    func checkClosure (condition: Bool, _ category: TestCategory?, _ level: Level, function: String = __FUNCTION__) {
      checkForType(": Closure", condition, category, level, function: function)
    }

    func callIt (category: TestCategory?, _ level: Level) {
      switch (level) {
      case .None:
        checkString(false, category, level)
        checkClosure(false, category, level)

      case .Severe:
        log.severe(category, "String")
        checkString(false, category, level)
        log.severe(category) { "Closure" }
        checkClosure(false, category, level)

      case .Error:
        log.error(category, "String")
        checkString(false, category, level)
        log.error(category) { "Closure" }
        checkClosure(false, category, level)

      case .Warning:
        log.warning(category, "String")
        checkString(false, category, level)
        log.warning(category) { "Closure" }
        checkClosure(false, category, level)

      case .Info:
        log.info(category, "String")
        checkString(false, category, level)
        log.info(category) { "Closure" }
        checkClosure(false, category, level)

      case .Debug:
        log.debug(category, "String")
        checkString(false, category, level)
        log.debug(category) { "Closure" }
        checkClosure(false, category, level)

      case .Verbose:
        log.verbose(category, "String")
        checkString(false, category, level)
        log.verbose(category) { "Closure" }
        checkClosure(false, category, level)
      }
    }

    func sloggit (category: TestCategory?) {
      for level in levels {
        callIt(category, level)
      }
    }

    // Test tracing
    log.verbose("String", override: true)
    checkString(true, nil, .Verbose)
    log.verbose(nil, override: true) { "Closure" }
    checkClosure(true, nil, .Verbose)

    for setLevel in levels {
      print("Setting log level: \(setLevel)")
      log.currentLevel = setLevel

      sloggit(nil)
      for category in categories {
        sloggit(category)
      }
    }

    print("Log Calls: \(log.hits), Log Calls \(log.hits + log.misses)")
  }

  func testConsole () {
    self.measureBlock() {
      self.exhaustiveTestWithDestinations([self.log.consoleDestination], checkResults: false)
    }
  }

  func testNoConsole () {
    self.measureBlock() {
      testDestination.clear()
      self.exhaustiveTestWithDestinations([testDestination], checkResults: true)
    }
  }

  func testNoLoggers () {
    self.measureBlock() {
      testDestination.clear()
      self.exhaustiveTestWithDestinations([], checkResults: false)
    }
  }

  //  func testPerformanceExample() {
  //    // This is an example of a performance test case.
  //    self.measureBlock {
  //      // Put the code you want to measure the time of here.
  //    }
  //  }
  
}
