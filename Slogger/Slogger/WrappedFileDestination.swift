//
//  WrappedFileDestination.swift
//  Slogger
//
//  Created by David Goodine on 11/7/15.
//  Copyright © 2015 David Goodine. All rights reserved.
//

import Foundation

public class WrappedFileDestination : TextFileDestination {

  public class WrappedFileConfiguration : Configuration {}

  public enum ValueType {
    case StringValue (key: Detail, value: String)
    case BoolValue (key: Detail, value: Bool)
    case IntValue (key: Detail, value: Int)
    case DateValue (key: Detail, value: NSDate)
  }

  init(directory: String, config: WrappedFileConfiguration) {
    super.init(directory: directory, config: config)

    weak var ws = self
    self.generator = {
      (message, category, override, level, date, function, file, line, details, dateFormatter) -> String in

      guard let ss = ws else {
        return ""
      }

      let str : NSMutableString = NSMutableString(capacity: 512)

      ss.emitBegin(str)


      for detail in details {
        ss.emitDelimiter(str)

        switch detail {

        case .Override:
          ss.emit(str, .BoolValue(key: detail, value: override != nil))

        case .Category:
          let cat = category == nil ? "" : "\(category!)"
          ss.emit(str, .StringValue(key: detail, value: cat))

        case .File:
          let f = file as NSString
          let filename = f.lastPathComponent
          ss.emit(str, .StringValue(key: detail, value: filename))

        case .Line:
          ss.emit(str, .IntValue(key: detail, value: line))

        case .Function:
          ss.emit(str, .StringValue(key: detail, value: function))

        case .Level:
          ss.emit(str, .StringValue(key: detail, value: "\(level)"))

        case .Date:
          ss.emit(str, .DateValue(key: detail, value: date))

        case .Message:
          ss.emit(str, .StringValue(key: .Message, value: message))
        }

        ss.emitEnd(str)

      }

      return str as String
    }
  }

  // Emit the preamble for the entry contents
  func emitBegin (outputString : NSMutableString) {
    assert(false, "This function must be overridden by subclasses")
  }

  // Emit an entry
  func emit (outputString : NSMutableString, _ type: ValueType) {
    assert(false, "This function must be overridden by subclasses")
  }

  // Emit the delimiter between entries.
  func emitDelimiter (outputString : NSMutableString) {
    assert(false, "This function must be overridden by subclasses")
  }

  // Emit the postamble for the entry.
  func emitEnd (outputString : NSMutableString) {
    assert(false, "This function must be overridden by subclasses")
  }
  
}