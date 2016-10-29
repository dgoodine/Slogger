//
//  TSVFileDestination.swift
//  Slogger
//
//  Created by David Goodine on 11/7/15.
//  Copyright © 2015 David Goodine. All rights reserved.
//

import Foundation

/// Tab-delimited file output destination.
open class TSVFileDestination: TextFileDestination {

  /// Configuration object.
  open class TSVConfiguration: Configuration {

    /// Designated initializer.
    public init () {
      super.init(generator: TSVGenerator())
      self.fileExtension = "tsv"
      self.entryDelimiter = "\n"
      self.fileWrapperGenerator = { (isPreamble) in
        if isPreamble {
          let header = self.details.map({"\($0)"}).joined(separator: "\t")
          return "\(header)\n"
        }
        return ""
      }
    }
  }

  /// Designateed initializaer
  public init(directory: String, config: TSVConfiguration = TSVConfiguration()) {
    super.init(directory: directory, config: config)
  }
}

/// Log entry generator for tab-delimited format.
open class TSVGenerator: Generator {

  override func emitBegin(_ outputString: NSMutableString) {}

  override func emit (_ outputString: NSMutableString, type: ValueType) {
    switch type {

    case .boolValue (_, let value):
      outputString.append("\(value)")

    case .intValue (_, let value):
      outputString.append("\(value)")

    case .stringValue(_, let value, _):
      let str = value.replacingOccurrences(of: "\t", with: " ")
      outputString.append("\(str)")

    case .dateValue(_, let value):
      var ds = dateFormatter.string(from: value)
      ds = ds.replacingOccurrences(of: "\t", with: " ")
      outputString.append("\(ds)")
    }
  }

  override func emitDelimiter(_ outputString: NSMutableString) {
    outputString.append("\t")
  }

  override func emitEnd(_ outputString: NSMutableString) {}

}
