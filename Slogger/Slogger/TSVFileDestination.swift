//
//  TSVFileDestination.swift
//  Slogger
//
//  Created by David Goodine on 11/7/15.
//  Copyright © 2015 David Goodine. All rights reserved.
//

import Foundation

public class TSVFileDestination : TextFileDestination {

  public class TSVConfiguration :  Configuration {

    public init () {
      super.init(generator: TSVGenerator())
      self.fileExtension = "tsv"
      self.entryDelimiter = "\n"
      self.fileWrapperGenerator = { (isPreamble) in
        if isPreamble {
          let header = self.details.map({"\($0)"}).joinWithSeparator("\t")
          return "\(header)\n"
        }
        return ""
      }
    }
  }

  init(directory: String, config: TSVConfiguration = TSVConfiguration()) {
    super.init(directory: directory, config: config)
  }
}

public class TSVGenerator : Generator {

  override func emitBegin(outputString: NSMutableString) {}

  override func emit (outputString : NSMutableString, _ detail: Detail, _ type: ValueType) {
    switch type {

    case .BoolValue (_, let value):
      outputString.appendString("\(value)")

    case .IntValue (_, let value):
      outputString.appendString("\(value)")

    case .StringValue(_, let value):
      let str = value.stringByReplacingOccurrencesOfString("\t", withString: " ")
      outputString.appendString("\(str)")

    case .DateValue(_, let value):
      var ds = dateFormatter.stringFromDate(value)
      ds = ds.stringByReplacingOccurrencesOfString("\t", withString: " ")
      outputString.appendString("\(ds)")
    }
  }

  override func emitDelimiter(outputString: NSMutableString) {
    outputString.appendString("\t")
  }

  override func emitEnd(outputString: NSMutableString) {}

}