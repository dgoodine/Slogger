//
//  TestingDestination.swift
//  Slogger
//
//  Created by David Goodine on 10/25/15.
//  Copyright © 2015 David Goodine. All rights reserved.
//

import Foundation

/**
 A logging destination used by the test suite.  It records each line logged in order so that testing code
 can retrieve them after a logging call.
*/
public class TestDestination : Destination {
  public var colorMap : ColorMap?
  public var decorator : Decorator?
  public var generator : Generator?

  private var lines : [String] = []
  public var lastIndex : Int {
    get {
      return lines.count - 1
    }
  }

  public required init (generator: Generator? = nil, colorMap : ColorMap? = nil, decorator: Decorator? = nil) {
    self.colorMap = colorMap
  }

  public func logString(string : String, level: Level) {
    lines.append(string)
  }

  /// Clear the logging history.
  public func clear () {
    lines = []
  }

  /**
   Subscript-based access to logging lines.
   
   - Parameter index: The index of the line to return
   - Returns: The logging output for the index or the empty string if the index was out of bounds.
   */
  public subscript (index : Int) -> String {
    get {
      guard index >= 0 && index < lines.count else {
        return ""
      }

      return lines[index]
    }
  }
}