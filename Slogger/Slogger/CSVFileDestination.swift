//
//  CSVFileDestination.swift
//  Slogger
//
//  Created by David Goodine on 11/7/15.
//  Copyright © 2015 David Goodine. All rights reserved.
//

import Foundation

/// Comma separated values TextFileDestination
public class CSVFileDestination: TextFileDestination {

  /// Configuration object.
  public class CSVConfiguration: Configuration {

    /// Designated initializer.
    public init () {
      super.init(generator: CSVGenerator())
      self.fileExtension = "csv"
      self.entryDelimiter = "\n"
      self.fileWrapperGenerator = { (isPreamble) in
        if isPreamble {
          let header = self.details.map({"\($0)"}).joinWithSeparator(",")
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
public class CSVGenerator: Generator {

  override func emitBegin(outputString: NSMutableString) {}

  override func emit (outputString: NSMutableString, type: ValueType) {
    switch type {

    case .BoolValue (_, let value):
      outputString.appendString("\(value)")

    case .IntValue (_, let value):
      outputString.appendString("\(value)")

    case .StringValue(_, let value, _):
      let str = value.stringByReplacingOccurrencesOfString("\"", withString: "\"\"")
      outputString.appendString("\"\(str)\"")

    case .DateValue(_, let value):
      let ds = dateFormatter.stringFromDate(value)
      outputString.appendString("\"\(ds)\"")
    }
  }

  override func emitDelimiter(outputString: NSMutableString) {
    outputString.appendString(",")
  }

  override func emitEnd(outputString: NSMutableString) {}

}
