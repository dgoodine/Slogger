//
//  Generator.swift
//  Slogger
//
//  Created by David Goodine on 11/7/15.
//  Copyright © 2015 David Goodine. All rights reserved.
//

import Foundation

/// Base class for log entry generators.  See custom file destinations for more generators.
open class Generator {

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
    case stringValue (detail: Detail, value: String, protect: Bool)

    /**
    A value to be emitted as a boolean (`true` or `false`)

    - Parameter detail: The `Detail` enum for this value.
    - Parameter value: The value to be output.
    */
    case boolValue (detail: Detail, value: Bool)

    /**
     A value to be emitted as an integer.

    - Parameter detail: The `Detail` enum for this value.
    - Parameter value: The value to be output.
    */
    case intValue (detail: Detail, value: Int)

    /**
     A value to be emitted as a date.

     - Parameter detail: The `Detail` enum for this value.
     - Parameter value: The value to be output.
     */
    case dateValue (detail: Detail, value: Date)
  }

  /// Formatter for emitting dates.  You can set this for your own custom format.
  open lazy var dateFormatter: DateFormatter = {
    let template = "yyyy-MM-dd HH:mm:ss.SSS ZZZ"
    let idf = DateFormatter()
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
  public final func generate (message: String, category: Any?, override: Level?, level: Level, date: Date, function: String, file: String, line: Int, details: [Detail]) -> String? {

    let str: NSMutableString = NSMutableString(capacity: 512)
    var isFirst = true

    self.emitBegin(str)

    for detail in details {
      if isFirst {
        isFirst = false
      } else {
        self.emitDelimiter(str)
      }

      switch detail {

      case .override:
        self.emit(str, type: .boolValue(detail: detail, value: override != nil))

      case .category:
        let cat = category == nil ? "" : "\(category!)"
        self.emit(str, type: .stringValue(detail: detail, value: cat, protect: false))

      case .file:
        let f = file as NSString
        let filename = f.lastPathComponent
        self.emit(str, type: .stringValue(detail: detail, value: filename, protect: true))

      case .line:
        self.emit(str, type: .intValue(detail: detail, value: line))

      case .function:
        self.emit(str, type: .stringValue(detail: detail, value: function, protect: true))

      case .level:
        self.emit(str, type: .stringValue(detail: detail, value: "\(level)", protect: false))

      case .date:
        self.emit(str, type: .dateValue(detail: detail, value: date))

      case .message:
        self.emit(str, type: .stringValue(detail: .message, value: message, protect: true))
      }

    }

    self.emitEnd(str)

    return str as String
  }

  /**
   Emit the beginning of the log entry.

   - Parameter outputString: The destination for output.
   */
  func emitBegin (_ outputString: NSMutableString) {
  }

  /**
   Emit a detail value based on its type.

   - Parameter outputString: The destination for output.
   - Parameter type: `ValueType` enum value carrying the detail enum and value.
   */
  func emit (_ outputString: NSMutableString, type: ValueType) {
    switch type {

    case .boolValue (let detail, let value):
      switch detail {
      case .override:
        let string = value ? "*" : "-"
        outputString.append("\(string)")
      default:
        outputString.append("\(value)")
      }

    case .intValue (let detail, let value):
      switch detail {
      case .line:
        outputString.append("(\(value))")
      default:
        outputString.append("\(value)")
      }

    case .stringValue(let detail, let value, _):
      switch detail {
      case .category:
        outputString.append("[\(value)]")
      case .message:
        outputString.append(": \(value)")
      default:
        outputString.append("\(value)")
      }

    case .dateValue(_, let value):
      let ds = dateFormatter.string(from: value)
      outputString.append("[\(ds)]")
    }

  }

  /**
   Emit the delimiter between entries.  This will be output before any entry except for the first.

   - Parameter outputString: The destination for output.
  */
  func emitDelimiter (_ outputString: NSMutableString) {
    outputString.append(" ")
  }

  /**
   Emit the end of the log entry.

   - Parameter outputString: The destination for output.
   */
  func emitEnd (_ outputString: NSMutableString) {
  }
}
