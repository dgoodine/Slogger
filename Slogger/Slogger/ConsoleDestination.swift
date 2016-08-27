//
//  ConsoleDestination.swift
//  Slogger
//
//  Created by David Goodine on 10/24/15.
//  Copyright © 2015 David Goodine. All rights reserved.
//

import Foundation

/// A default console destination.
public class ConsoleDestination: DestinationBase, Destination {

  /// Local Storage
  private static let defaultColorMap: ColorMap = [
    .None : (colorFromHexString("02A8A8"), nil),
    .Severe : (colorFromHexString("FF0000"), nil),
    .Error : (colorFromHexString("FF5500"), nil),
    .Warning : (colorFromHexString("FF03FB"), nil),
    .Info : (colorFromHexString("008C31"), nil),
    .Debug : (colorFromHexString("035FFF"), nil),
    .Verbose : (colorFromHexString("555555"), nil),
  ]

  /// Designated initializer.
  override public init (details: [Detail]? = nil, generator: Generator = Generator(), colorMap: ColorMap? = defaultColorMap, decorator: Decorator? = XCodeColorsDecorator()) {
    super.init(details: details, generator: generator, colorMap: colorMap, decorator: decorator)
  }

  /// Protocol implementation.
  public func logString (string: String, level: Level) {
    if let color = colorMap?[level] where decorator != nil {
      if let decorated = decorator?.decorateString(string, spec: color) {
        print(decorated)
        return
      }
    }

    print(string)
  }
}
