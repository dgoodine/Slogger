//
//  XCodeColorsDecorator.swift
//  Slogger
//
//  Created by David Goodine on 10/24/15.
//

import Foundation
import UIKit

public struct XCodeColorsDecorator : Decorator {
  private let escape = "\u{001b}["
  private let resetFg = "\u{001b}[fg;"
  private let resetBg = "\u{001b}[bg;"
  private let reset = "\u{001b}[;"
  private let maxColor = CGFloat(255)

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

    var fgString : String = resetFg
    if fg != nil {
      fgString = prefix(fg!, "fg")
    }

    var bgString : String = resetBg
    if bg != nil {
      bgString = prefix(bg!, "bg")
    }
    let value = "\(fgString)\(bgString)\(string)"

    return value
  }
}
