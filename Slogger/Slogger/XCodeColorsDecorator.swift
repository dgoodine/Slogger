//
//  XCodeColorsDecorator.swift
//  Slogger
//
//  Created by David Goodine on 10/24/15.
//  Copyright © 2015 David Goodine. All rights reserved.
//

import Foundation

public struct XCodeColorsDecorator : Decorator {
  private let escape = "\u{001b}["
  private let resetFg = "\u{001b}[fg;"
  private let resetBg = "\u{001b}[bg;"
  private let reset = "\u{001b}[;"
  private let maxColor = 255.0

  public func decorateString(string : String, spec: ColorSpec) -> String {
    let fg = spec.fg
    let bg = spec.bg

    func prefix (color: Color, _ typeCode : String) -> String
    {
      let r = Int(color.r * maxColor)
      let g = Int(color.g * maxColor)
      let b = Int(color.b * maxColor)
      return "\(escape)\(typeCode)\(r),\(g),\(b);"
    }

    var fgStart = ""
    let fgEnd = (fg == nil) ? "" : resetFg
    if fg != nil {
      fgStart = prefix(fg!, "fg")
    }

    var bgStart = ""
    let bgEnd = (bg == nil) ? "" : resetBg
    if bg != nil {
      bgStart = prefix(bg!, "bg")
    }
    let value = "\(fgStart)\(bgStart)\(string)\(fgEnd)\(bgEnd)"

    return value
  }
}
