//
//  CSVFileDestination.swift
//  Slogger
//
//  Created by David Goodine on 11/7/15.
//  Copyright © 2015 David Goodine. All rights reserved.
//

import Foundation

/// Comma separated values TextFileDestination
open class CSVFileDestination: TextFileDestination {

  /// Configuration object.
  open class CSVConfiguration: Configuration {

    /// Designated initializer.
    public init () {
      super.init(generator: CSVGenerator())
      self.fileExtension = "csv"
      self.entryDelimiter = "\n"
      self.fileWrapperGenerator = { (isPreamble) in
        if isPreamble {
          let header = self.details.map({"\($0)"}).joined(separator: ",")
          return "\(header)\n"
        }
        return ""
      }
    }
  }

  /// Designated initializer.
  public init(directory: String, config: CSVConfiguration = CSVConfiguration()) {
    super.init(directory: directory, config: config)
  }
}

/// CSV entry generator.
open class CSVGenerator: Generator {

  override func emitBegin(_ outputString: NSMutableString) {}

  override func emit (_ outputString: NSMutableString, type: ValueType) {
    switch type {

    case .boolValue (_, let value):
      outputString.append("\(value)")

    case .intValue (_, let value):
      outputString.append("\(value)")

    case .stringValue(_, let value, _):
      let str = value.replacingOccurrences(of: "\"", with: "\"\"")
      outputString.append("\"\(str)\"")

    case .dateValue(_, let value):
      let ds = dateFormatter.string(from: value)
      outputString.append("\"\(ds)\"")
    }
  }

  override func emitDelimiter(_ outputString: NSMutableString) {
    outputString.append(",")
  }

  override func emitEnd(_ outputString: NSMutableString) {}

}
