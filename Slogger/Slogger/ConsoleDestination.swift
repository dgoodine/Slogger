//
//  ConsoleDestination.swift
//  Slogger
//
//  Created by David Goodine on 10/24/15.
//  Copyright © 2015 David Goodine. All rights reserved.
//

import Foundation

/// A default console destination.
public class ConsoleDestination : BaseDestination {

  /// Protocol implementation
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
