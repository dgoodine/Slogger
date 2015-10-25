//
//  ConsoleSlogger.swift
//  Slogger
//
//  Created by David Goodine on 10/24/15.
//

import Foundation

public class ConsoleDestination : Destination {

  public var colorMap : ColorMap?
  public var decorator : Decorator? = XCodeColorsDecorator()
  public var generator : Generator?

  public required init (generator: Generator? = nil, colorMap : ColorMap? = nil) {
    self.generator = generator
    self.colorMap = colorMap
  }

  public func logString(string : String, level: Level) {
    if let color = colorMap?[level] where decorator != nil {
      if let decorated = decorator?.decorateString(string, spec: color) {
        print(decorated)
        return
      }
    }

    print(string)
  }
}

