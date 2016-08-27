//
//  JSONFileDestination.swift
//  Slogger
//
//  Created by David Goodine on 11/7/15.
//  Copyright © 2015 David Goodine. All rights reserved.
//

import Foundation

/// Output destination for JSON files.
public class JSONFileDestination: TextFileDestination {

  /// Configuration instance.
  public class JSONConfiguration: Configuration {

    /// Designated initializer.
    public init () {
      super.init(generator: JSONGenerator())
      self.fileExtension = "json"
      self.entryDelimiter = ",\n"
      self.fileWrapperGenerator = { (isPreamble) in
        return isPreamble ? "[\n" : "]"
      }
    }
  }

  /// Designated initializer.
  public init(directory: String, config: JSONConfiguration = JSONConfiguration()) {
    super.init(directory: directory, config: config)
  }
}

/// JSON format log entry generator.
public class JSONGenerator: Generator {

  override func emitBegin(outputString: NSMutableString) {
    outputString.appendString("{\n")
  }

  override func emit (outputString: NSMutableString, type: ValueType) {
    switch type {

    case .BoolValue (let detail, let value):
      outputString.appendString("\"\(detail)\":\(value)")

    case .IntValue (let detail, let value):
      outputString.appendString("\"\(detail)\":\(value)")

    case .StringValue(let detail, let value, _):
      let str = value.stringByReplacingOccurrencesOfString("\"", withString: "\\\"")
      outputString.appendString("\"\(detail)\":\"\(str)\"")

    case .DateValue(let detail, let value):
      let ds = dateFormatter.stringFromDate(value)
      outputString.appendString("\"\(detail)\":\"\(ds)\"")
    }
  }

  override func emitDelimiter(outputString: NSMutableString) {
    outputString.appendString(",")
  }

  override func emitEnd(outputString: NSMutableString) {
    outputString.appendString("\n}")
  }

}
