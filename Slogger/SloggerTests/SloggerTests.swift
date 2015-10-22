//
//  SloggerTests.swift
//  SloggerTests
//
//  Created by David Goodine on 10/20/15.
//  Copyright © 2015 David Goodine. All rights reserved.
//

import XCTest
@testable import Slogger

class SloggerTests: XCTestCase {

  enum TestCategory : String, SloggerCategory {
    case First, Second, Third
  }

  class TestLogger : Slogger<TestCategory> {
    init () {
      super.init(defaultLevel: Level.Info)
    }
  }

  let log = TestLogger()

  override func setUp() {
    super.setUp()
  }

  override func tearDown() {
    super.tearDown()
  }

  func testBasic () {
    log.error() { return "Error" }
    log.error(.First, "Error")

    log.error() {
      return "ClosureError"
    }
  }

//  func testPerformanceExample() {
//    // This is an example of a performance test case.
//    self.measureBlock {
//      // Put the code you want to measure the time of here.
//    }
//  }

}
