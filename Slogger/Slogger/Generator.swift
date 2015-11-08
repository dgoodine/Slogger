//
//  Generator.swift
//  Slogger
//
//  Created by David Goodine on 11/7/15.
//  Copyright © 2015 David Goodine. All rights reserved.
//

import Foundation

/// Base class for log entry generators.  See custom file destinations for more generators.
public class Generator {

  /// An enum for passing detail values to emitter functions.
  public enum ValueType {
    /** 
     A value to be emitted as a string

     - Parameter detail: The `Detail` enum for this value.
     - Parameter value: The value to be output.
     - Parameter protect: If true, the value may contain characters that are not alphanumeric, and anomalous
     to the output format – a comma character the message field in CSV format, for example. Implementations are free
     to ignore this and protect all string fields if desired.  This was motivated to cut down on CDATA section spam
     where it isn't needed in the XMLGenerator implementation.

     */
    case StringValue (detail: Detail, value: String, protect: Bool)

    /**
    A value to be emitted as a boolean (`true` or `false`)

    - Parameter detail: The `Detail` enum for this value.
    - Parameter value: The value to be output.
    */
    case BoolValue (detail: Detail, value: Bool)

    /**
     A value to be emitted as an integer.

    - Parameter detail: The `Detail` enum for this value.
    - Parameter value: The value to be output.
    */
    case IntValue (detail: Detail, value: Int)

    /**
     A value to be emitted as a date.

     - Parameter detail: The `Detail` enum for this value.
     - Parameter value: The value to be output.
     */
    case DateValue (detail: Detail, value: NSDate)
  }

  /// Formatter for emitting dates.  You can set this for your own custom format.
  public lazy var dateFormatter : NSDateFormatter = {
    let template = "yyyy-MM-dd HH:mm:ss.SSS ZZZ"
    let idf = NSDateFormatter()
    idf.dateFormat = template
    return idf
  }()

  /**
   The generator function.

   - Important: The `override` parameter can be used to signify in the output that this is an override event. However,
   the `level` parameter should be used if the details call for it, since it corresponds to the level implicitly passed
   by the logging site.

   - Parameter message: The message string from the logging site.
   - Parameter category: The category specified at the logging site.
   - Parameter override: The override level.
   - Parameter level: The level of the logging site.
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
        self.emit(str, type: .BoolValue(detail: detail, value: override != nil))

      case .Category:
        let cat = category == nil ? "" : "\(category!)"
        self.emit(str, type: .StringValue(detail: detail, value: cat, protect: false))

      case .File:
        let f = file as NSString
        let filename = f.lastPathComponent
        self.emit(str, type: .StringValue(detail: detail, value: filename, protect: true))

      case .Line:
        self.emit(str, type: .IntValue(detail: detail, value: line))

      case .Function:
        self.emit(str, type: .StringValue(detail: detail, value: function, protect: true))

      case .Level:
        self.emit(str, type: .StringValue(detail: detail, value: "\(level)", protect: false))

      case .Date:
        self.emit(str, type: .DateValue(detail: detail, value: date))

      case .Message:
        self.emit(str, type: .StringValue(detail: .Message, value: message, protect: true))
      }

    }

    self.emitEnd(str)

    return str as String
  }

  /**
   Emit the beginning of the log entry.
   
   - Parameter outputString: The destination for output.
   */
  func emitBegin (outputString : NSMutableString) {
  }

  /** 
   Emit a detail value based on its type.
   
   - Parameter outputString: The destination for output.
   - Parameter type: `ValueType` enum value carrying the detail enum and value.
   */
  func emit (outputString : NSMutableString, type: ValueType) {
    switch type {

    case .BoolValue (let detail, let value):
      switch detail {
      case .Override:
        let string = value ? "*" : "-"
        outputString.appendString("\(string)")
      default:
        outputString.appendString("\(value)")
      }

    case .IntValue (let detail, let value):
      switch detail {
      case .Line:
        outputString.appendString("(\(value))")
      default:
        outputString.appendString("\(value)")
      }

    case .StringValue(let detail, let value, _):
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

  /** 
   Emit the delimiter between entries.  This will be output before any entry except for the first.
   
   - Parameter outputString: The destination for output.
  */
  func emitDelimiter (outputString : NSMutableString) {
    outputString.appendString(" ")
  }

  /** 
   Emit the end of the log entry.
   
   - Parameter outputString: The destination for output.
   */
  func emitEnd (outputString : NSMutableString) {
  }
}

