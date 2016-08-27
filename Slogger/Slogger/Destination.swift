//
//  BaseDestination.swift
//  Slogger
//
//  Created by David Goodine on 10/28/15.
//  Copyright © 2015 David Goodine. All rights reserved.
//

import Foundation

/// Protocol all destinations must implement.
public protocol Destination {
  /// A custom generator for this destination.  If nil, the output will not be decorated.
  var decorator: Decorator? { get set }

  /// The generator for this destination.
  var generator: Generator { get set }

  /// A custom decorator for this destination.  If nil, no color will be used.
  var colorMap: ColorMap? { get set }

  /// The details to be logged for this destination.
  var details: [Detail] { get  set }

  /*
  The function called by the internal system to emit the event.

  - Parameter string: The string representation of the logging event.
  - Parameter level: The logging level, provided for level-based destination routing.
  */
  func logString (string: String, level: Level)
}

/**
 Abstract providing some of the Destination protocol.
 Subclasses must conform to Destination and provide the `logString` function.
 */
public class DestinationBase {

  /// Protocol Implementation
  public var decorator: Decorator?

  /// Protocol Implementation
  public var generator: Generator

  /// Protocol Implementation
  public var colorMap: ColorMap?

  /// Protocol Implementation
  public var details: [Detail]

  /**
   Designated initializer.

   - Parameter generator: Generator to use for this destination.
   - Parameter colorMap: Colormap to use for this destination. If nil, uses the logger's colorMap.
   - Parameter decorator: Decorator to use for this destination.  If nil, uses the logger's decorator.
   */
  public init (details: [Detail]? = nil, generator: Generator = Generator(), colorMap: ColorMap? = nil, decorator: Decorator? = nil) {
    self.generator = generator
    self.details = details != nil ? details! : Detail.allValues
    self.colorMap = colorMap
    self.decorator = decorator
  }
}
