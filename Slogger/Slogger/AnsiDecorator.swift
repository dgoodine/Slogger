//
//  AnsiDecorator.swift
//  Slogger
//
//  Created by David Goodine on 11/6/15.
//  Copyright © 2015 David Goodine. All rights reserved.
//

import Foundation

public struct AnsiDecorator : Decorator {
  private let escape = "\u{001b}["
  private let reset = "\u{001b}[m"
  private let fgCode = "38;2;"
  private let bgCode = "48;2;"
  private let maxColor = 255.0

  public init() {}

  /// Protocol implementation
  public func decorateString(string : String, spec: ColorSpec) -> String {
    // This is disabled for now.
    return string

//    let fg = spec.fg
//    let bg = spec.bg
//
//    func prefix (color: Color, _ typeCode : String) -> String
//    {
//      let r = Int(color.r * maxColor)
//      let g = Int(color.g * maxColor)
//      let b = Int(color.b * maxColor)
//      return "\(escape)\(typeCode)\(r);\(g);\(b);m"
//    }
//
//    var fgStart = ""
//    if fg != nil {
//      fgStart = prefix(fg!, fgCode)
//    }
//
//    var bgStart = ""
//    if bg != nil {
//      bgStart = prefix(bg!, bgCode)
//    }
//
//    let value = "\(fgStart)\(bgStart)\(string)\(reset)"
//    return value
  }
}
