//
//  Generator.swift
//  Slogger
//
//  Created by David Goodine on 11/7/15.
//  Copyright © 2015 David Goodine. All rights reserved.
//

import Foundation

/// Base class for log entry generators.
public class Generator {

  /// An enum for passing detail values to emitter functions.
  public enum ValueType {
    /// A value to be emitted as a string
    case StringValue (key: Detail, value: String)

    /// A value to be emitted as a boolean (`true` or `false`)
    case BoolValue (key: Detail, value: Bool)

    /// A value to be emitted as an integer.
    case IntValue (key: Detail, value: Int)

    /// A value to be emitted as a date.
    case DateValue (key: Detail, value: NSDate)
  }

  /// Default date formatter
  public lazy var dateFormatter : NSDateFormatter = {
    let template = "yyyy-MM-dd HH:mm:ss.SSS ZZZ"
    let idf = NSDateFormatter()
    idf.dateFormat = template
    return idf
  }()

  /**
   The generator function.

   - Important: The `override` parameter can be used to signify in the output that this is an override event. However, the
   `level` parameter should be used if the details call for it, since it corresponds to the level implicitly passed by the
   logging function at the logging site.  This will preserve decorator style appropriate for the level.

   - Parameter message: The message string at the logging site.
   - Parameter category: The category specified in the logging site.
   - Parameter override: The override level.
   - Parameter level: The logging level of the site.
   - Parameter date: The date of the logging event.
   - Parameter function: The function the logging site is in.
   - Parameter file: The file the logging site is in.
   - Parameter line: The line number in the file of the logging site.
   - Parameter details: The ordered array of detail enum values for information that should be output.

   - Returns: A string representation of the generator output or `nil` to produce no output.
   
   */
  public final func generate (message message: String, category: Any?, override: Level?, level: Level, date: NSDate, function: String, file: String, line: Int, details : [Detail]) -> String? {

    let str : NSMutableString = NSMutableString(capacity: 512)
    var isFirst = true

    self.emitBegin(str)

    for detail in details {
      if isFirst {
        isFirst = false
      } else {
        self.emitDelimiter(str)
      }

      switch detail {

      case .Override:
        self.emit(str, detail, .BoolValue(key: detail, value: override != nil))

      case .Category:
        let cat = category == nil ? "" : "\(category!)"
        self.emit(str, detail, .StringValue(key: detail, value: cat))

      case .File:
        let f = file as NSString
        let filename = f.lastPathComponent
        self.emit(str, detail, .StringValue(key: detail, value: filename))

      case .Line:
        self.emit(str, detail, .IntValue(key: detail, value: line))

      case .Function:
        self.emit(str, detail, .StringValue(key: detail, value: function))

      case .Level:
        self.emit(str, detail, .StringValue(key: detail, value: "\(level)"))

      case .Date:
        self.emit(str, detail, .DateValue(key: detail, value: date))

      case .Message:
        self.emit(str, detail, .StringValue(key: .Message, value: message))
      }

    }

    self.emitEnd(str)

    return str as String
  }

  // Emit the preamble for the entry contents
  func emitBegin (outputString : NSMutableString) {
  }

  // Emit an entry based on its value type.
  func emit (outputString : NSMutableString, _ detail: Detail, _ type: ValueType) {
    switch type {

    case .BoolValue (_, let value):
      let string = value ? "*" : "-"
      outputString.appendString("\(string)")

    case .IntValue (_, let value):
      switch detail {
      case .Line:
        outputString.appendString("(\(value))")
      default:
        outputString.appendString("\(value)")
      }

    case .StringValue(_, let value):
      switch detail {
      case .Category:
        outputString.appendString("[\(value)]")
      case .Message:
        outputString.appendString(": \(value)")
      default:
        outputString.appendString("\(value)")
      }

    case .DateValue(_, let value):
      let ds = dateFormatter.stringFromDate(value)
      outputString.appendString("[\(ds)]")
    }

  }

  // Emit the delimiter between entries.
  func emitDelimiter (outputString : NSMutableString) {
    outputString.appendString(" ")
  }

  // Emit the postamble for the entry.
  func emitEnd (outputString : NSMutableString) {
  }
}

