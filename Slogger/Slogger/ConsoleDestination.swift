//
//  ConsoleDestination.swift
//  Slogger
//
//  Created by David Goodine on 10/24/15.
//  Copyright © 2015 David Goodine. All rights reserved.
//

import Foundation

/// A default console destination.
open class ConsoleDestination: DestinationBase, Destination {

  /// Local Storage
  fileprivate static let defaultColorMap: ColorMap = [
    .off : (colorFromHexString("02A8A8"), nil),
    .severe : (colorFromHexString("FF0000"), nil),
    .error : (colorFromHexString("FF5500"), nil),
    .warning : (colorFromHexString("FF03FB"), nil),
    .info : (colorFromHexString("008C31"), nil),
    .debug : (colorFromHexString("035FFF"), nil),
    .verbose : (colorFromHexString("555555"), nil),
  ]

  /// Designated initializer.
  override public init (details: [Detail]? = nil, generator: Generator = Generator(), colorMap: ColorMap? = defaultColorMap, decorator: Decorator? = XCodeColorsDecorator()) {
    super.init(details: details, generator: generator, colorMap: colorMap, decorator: decorator)
  }

  /// Protocol implementation.
  open func logString (_ string: String, level: Level) {
    if let color = colorMap?[level] , decorator != nil {
      if let decorated = decorator?.decorateString(string, spec: color) {
        print(decorated)
        return
      }
    }

    print(string)
  }
}
