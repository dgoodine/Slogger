//
//  MemoryDestination.swift
//  Slogger
//
//  Created by David Goodine on 10/25/15.
//  Copyright © 2015 David Goodine. All rights reserved.
//

import Foundation

/**
 An in-memory logging destination used by the test suite. 
 Provided as it might be a useful superclass for some use-cases (e.g. buffering lines for periodic
 transfer to some other output sink.
 */
public class MemoryDestination : Destination {

  // MARK - Properties

  /// The index of the last logged line.  Returns *-1* if the destination is empty.
  public var lastIndex : Int {
    get {
      return lines.count - 1
    }
  }

  /// The last logged line.  Returns *nil* if the destination is empty.
  public var lastLine : String? {
    get {
      return self[lastIndex]
    }
  }

  /// Storage
  private var lines : [String] = []

  // MARK - Functions
  /**
  Protocol implementation.  Simply appends the string to an internal array.
  
  - Parameter string: The line to be logged.
  - Parameter level: The level provided at the logging site.
  */
  public override func logString(string : String, level: Level) {
    lines.append(string)
  }

  /// Clear the logging history.
  public func clear () {
    lines = []
  }

  /**
   Subscript-based access to logging lines.

   - Parameter index: The index of the line to return
   - Returns: The logging output for the index or nil if the destination is empty or the index is out of bounds
   */
  public subscript (index : Int) -> String? {
    get {
      guard index >= 0 && index < lines.count else {
        return nil
      }

      return lines[index]
    }
  }
}