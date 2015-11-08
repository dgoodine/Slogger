//
//  JSONFileDestination.swift
//  Slogger
//
//  Created by David Goodine on 11/7/15.
//  Copyright © 2015 David Goodine. All rights reserved.
//

import Foundation

public class JSONFileDestination : TextFileDestination {

  public class JSONConfiguration :  Configuration {

    public init () {
      super.init(generator: JSONGenerator())
      self.fileExtension = "json"
      self.entryDelimiter = ",\n"
      self.fileWrapperGenerator = { (isPreamble) in
        return isPreamble ? "[\n" : "]"
      }
    }
  }

  init(directory: String, config: JSONConfiguration = JSONConfiguration()) {
    super.init(directory: directory, config: config)
  }
}

public class JSONGenerator : Generator {

  override func emitBegin(outputString: NSMutableString) {
    outputString.appendString("{\n")
  }

  override func emit (outputString : NSMutableString, _ detail: Detail, _ type: ValueType) {
    switch type {

    case .BoolValue (let key, let value):
      outputString.appendString("\"\(key)\":\(value)")

    case .IntValue (let key, let value):
      outputString.appendString("\"\(key)\":\(value)")

    case .StringValue(let key, let value):
      let str = value.stringByReplacingOccurrencesOfString("\"", withString: "\\\"")
      outputString.appendString("\"\(key)\":\"\(str)\"")

    case .DateValue(let key, let value):
      let ds = dateFormatter.stringFromDate(value)
      outputString.appendString("\"\(key)\":\"\(ds)\"")
    }
  }

  override func emitDelimiter(outputString: NSMutableString) {
    outputString.appendString(",")
  }

  override func emitEnd(outputString: NSMutableString) {
    outputString.appendString("\n}")
  }

}