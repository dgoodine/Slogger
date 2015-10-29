//
//  ConsoleDestination.swift
//  Slogger
//
//  Created by David Goodine on 10/24/15.
//  Copyright © 2015 David Goodine. All rights reserved.
//

import Foundation

public class ConsoleDestination : BaseDestination {

  /**
   Protocol implementation.  Outputs the string to the console.

   - Parameter string: The line to be logged.
   - Parameter level: The level provided at the logging site.
   */
  public override func logString(string : String, level: Level) {
    if let color = colorMap?[level] where decorator != nil {
      if let decorated = decorator?.decorateString(string, spec: color) {
        print(decorated)
        return
      }
    }

    print(string)
  }
  
}
