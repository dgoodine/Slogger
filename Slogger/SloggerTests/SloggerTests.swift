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

class SloggerTests: XCTestCase {
  let log = TestLogger(destination: testDestination)
  override func setUp() {
    super.setUp()
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

    log.verbose(.First, "Message")

    log.verbose() {
      return "Closure Message"
    }

    log.verbose(.First) {
      return "Closure Message"
    }
  }

  func testExhaustive () {

    let levels = Level.allValues()
    let categories = TestCategory.allValues()
    var lastIndex : Int = 0

    func checkForType (type: String, _ condition: Bool, _ category: TestCategory?, _ level: Level) {
      guard log.canLogWithCondition(condition, category: category, level: level) else {
        return
      }

      let last = testDestination[lastIndex]
      XCTAssert(last.containsString(type) == condition, "Incorrect message")

      lastIndex++
    }

    func checkString (condition: Bool, _ category: TestCategory?, _ level: Level) {
      checkForType(": String", condition, category, level)
    }

    func checkClosure (condition: Bool, _ category: TestCategory?, _ level: Level) {
      checkForType(": Closure", condition, category, level)
    }

    func callIt (category: TestCategory?, _ level: Level) {
      switch (level) {
      case .None:
        checkString(false, category, level)
        checkClosure(false, category, level)

      case .Severe:
        log.severe(category, "String")
        checkString(true, category, level)
        log.severe(category) { return "Closure" }
        checkClosure(true, category, level)

      case .Error:
        log.error(category, "String")
        checkString(true, category, level)
        log.error(category) { return "Closure" }
        checkClosure(true, category, level)

      case .Warning:
        log.warning(category, "String")
        checkString(true, category, level)
        log.warning(category) { return "Closure" }
        checkClosure(true, category, level)

      case .Info:
        log.info(category, "String")
        checkString(true, category, level)
        log.info(category) { return "Closure" }
        checkClosure(true, category, level)

      case .Debug:
        log.debug(category, "String")
        checkString(true, category, level)
        log.debug(category) { return "Closure" }
        checkClosure(true, category, level)

      case .Verbose:
        log.verbose(category, "String")
        checkString(true, category, level)
        log.verbose(category) { return "Closure" }
        checkClosure(true, category, level)

      case .Trace:
        for condition in [true, false] {
          log.trace(category, condition, "String")
          checkString(condition, category, level)
          log.trace(category, condition) { return "Closure" }
          checkClosure(condition, category, level)
        }
      }
    }

    func sloggit (category: TestCategory?) {
      for level in levels {
        callIt(category, level)
      }
    }

    for setLevel in levels {
      print("Setting log level: \(setLevel)")
      log.currentLevel = setLevel

      sloggit(nil)
      for category in categories {
        sloggit(category)
      }
    }

    print("Call counts: \(log.hits) / \(log.hits + log.misses)")
  }

  //  func testPerformanceExample() {
  //    // This is an example of a performance test case.
  //    self.measureBlock {
  //      // Put the code you want to measure the time of here.
  //    }
  //  }
  
}
