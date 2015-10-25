//
//  Color.swift
//  Slogger
//
//  Created by David Goodine on 10/24/15.
//

import Foundation

public typealias Color = (r: Double, g: Double, b: Double)
public typealias ColorSpec = (fg: Color?, bg: Color?)
public typealias ColorMap = [Level : ColorSpec]

public func colorFromHexString (string : String) -> Color {
  let hexString = string.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
  let scanner = NSScanner(string: hexString)

  if (hexString.hasPrefix("#")) {
    scanner.scanLocation = 1
  }

  var color:UInt32 = 0
  scanner.scanHexInt(&color)
  let mask = 0x000000FF
  let r = Int(color >> 16) & mask
  let g = Int(color >> 8) & mask
  let b = Int(color) & mask

  return (r: Double(r) / 255.0, g: Double(g) / 255.0, b: Double(b) / 255.0)
}

public protocol Decorator {
  func decorateString(string : String, spec: ColorSpec) -> String
}

