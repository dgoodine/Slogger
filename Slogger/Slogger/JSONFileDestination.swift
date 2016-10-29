//
//  JSONFileDestination.swift
//  Slogger
//
//  Created by David Goodine on 11/7/15.
//  Copyright © 2015 David Goodine. All rights reserved.
//

import Foundation

/// Output destination for JSON files.
open class JSONFileDestination: TextFileDestination {

  /// Configuration instance.
  open class JSONConfiguration: Configuration {

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
open class JSONGenerator: Generator {

  override func emitBegin(_ outputString: NSMutableString) {
    outputString.append("{\n")
  }

  override func emit (_ outputString: NSMutableString, type: ValueType) {
    switch type {

    case .boolValue (let detail, let value):
      outputString.append("\"\(detail)\":\(value)")

    case .intValue (let detail, let value):
      outputString.append("\"\(detail)\":\(value)")

    case .stringValue(let detail, let value, _):
      let str = value.replacingOccurrences(of: "\"", with: "\\\"")
      outputString.append("\"\(detail)\":\"\(str)\"")

    case .dateValue(let detail, let value):
      let ds = dateFormatter.string(from: value)
      outputString.append("\"\(detail)\":\"\(ds)\"")
    }
  }

  override func emitDelimiter(_ outputString: NSMutableString) {
    outputString.append(",")
  }

  override func emitEnd(_ outputString: NSMutableString) {
    outputString.append("\n}")
  }

}
