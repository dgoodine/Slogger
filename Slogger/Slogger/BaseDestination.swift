//
//  BaseDestination.swift
//  Slogger
//
//  Created by David Goodine on 10/28/15.
//  Copyright © 2015 David Goodine. All rights reserved.
//

import Foundation

/**
 Base class implementing the destination protocol.  Can be subclassed to provide custom *logString* functionality.
*/
public class BaseDestination : Destination {
  public var decorator : Decorator?
  public var generator : Generator?
  public var colorMap : ColorMap?

  public required init (generator: Generator? = nil, colorMap : ColorMap? = nil, decorator: Decorator? = nil) {
    self.generator = generator
    self.colorMap = colorMap
    self.decorator = decorator
  }

  public func logString(string : String, level: Level) {
    assert(true, "This function must be overridden by subclasses")
  }
}
