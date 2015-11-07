//
//  JSONFileDestination.swift
//  Slogger
//
//  Created by David Goodine on 11/7/15.
//  Copyright © 2015 David Goodine. All rights reserved.
//

import Foundation

public class JSONFileDestination : WrappedFileDestination {

  public class JSONConfiguration : WrappedFileConfiguration {

    public init () {
      super.init()
      self.fileExtension = "json"
      self.entryDelimiter = ",\n"
      self.fileWrapperGenerator = { (isPreamble) in
        return isPreamble ? "[\n" : "]"
      }
    }
  }

  let dateFormatter : NSDateFormatter = {
    let template = "yyyy-MM-dd HH:mm:ss.SSS zzz"
    let idf = NSDateFormatter()
    idf.dateFormat = template
    return idf
  }()

  override init(directory: String, config: WrappedFileConfiguration = JSONConfiguration()) {
    super.init(directory: directory, config: config)
  }

  override func emitBegin(outputString: NSMutableString) {
    outputString.appendString("{")
  }

  override func emit (outputString: NSMutableString, _ type: ValueType) {

    switch type {

    case .BoolValue (let key, let value):
      outputString.appendString("\"\(key)\":\(value)")

    case .IntValue (let key, let value):
      outputString.appendString("\"\(key)\":\(value)")

    case .StringValue(let key, let value):
      let val = value.stringByReplacingOccurrencesOfString("\"", withString: "\\\"")
      outputString.appendString("\"\(key)\":\"\(val)\"")

    case .DateValue(let key, let value):
      let ds = dateFormatter.stringFromDate(value)
      outputString.appendString("\"\(key)\":\"\(ds)\"")
    }
  }

  override func emitEnd(outputString: NSMutableString) {
    outputString.appendString("}")
  }
}

