//
//  BaseDestination.swift
//  Slogger
//
//  Created by David Goodine on 10/28/15.
//  Copyright © 2015 David Goodine. All rights reserved.
//

import Foundation

/**
 Base class implementing the destination protocol.  Subclasses must override *logString* function.
*/
public class BaseDestination : Destination {

  /// Protocol property
  public var decorator : Decorator?

  /// Protocol property
  public var generator : Generator?

  /// Protocol property
  public var colorMap : ColorMap?

  /**
   Base initializer.
   
   - Parameter generator: Generator to use for this destination.  If nil, uses the logger's generator.
   - Parameter colorMap: Colormap to use for this destination. If nil, uses the logger's colorMap.
   - Parameter decorator: Decorator to use for this destination.  If nil, uses the logger's decorator.
   */
  public init (generator: Generator? = nil, colorMap : ColorMap? = nil, decorator: Decorator? = nil) {
    self.generator = generator
    self.colorMap = colorMap
    self.decorator = decorator
  }

  /**
   Protocol implementation.  Will terminate with a false assertion.
   Important: Subclasses *MUST* override this function.
   */
  public func logString(string : String, level: Level) {
    assert(true, "This function must be overridden by subclasses")
  }
}