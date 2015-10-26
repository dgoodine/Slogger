//
//  Color.swift
//  Slogger
//
//  Created by David Goodine on 10/24/15.
//

import Foundation

/// A tuple that represents a color, each value in the range [0,1]
public typealias Color = (r: Double, g: Double, b: Double)

/** 
 A tuple that represents the foreground and background colors for a level.  Both are optional.
 If a value is nil, it will not be used for decoration.
*/
public typealias ColorSpec = (fg: Color?, bg: Color?)

/**
 A dictionary mapping logging levels to color specs.  If a level is not included in the dictionary,
 it will not be used for decoration.
*/
public typealias ColorMap = [Level : ColorSpec]

/**
 Parse a hexadecimal representation of a color value into a Color type.
 
 - Parameter string: A six-digit hex value. Can optionally be prefixed with '#'.
*/
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


