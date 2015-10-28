//
//  ConsoleDestination.swift
//  Slogger
//
//  Created by David Goodine on 10/24/15.
//

import Foundation

public class ConsoleDestination : BaseDestination {
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
