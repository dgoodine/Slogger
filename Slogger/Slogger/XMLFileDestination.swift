//
//  XMLFileDestination.swift
//  Slogger
//
//  Created by David Goodine on 11/7/15.
//  Copyright © 2015 David Goodine. All rights reserved.
//

import Foundation

public class XMLFileDestination : TextFileDestination {

  public class XMLConfiguration :  Configuration {

    public init (generator: Generator = XMLGenerator()) {
      super.init(generator: generator)
      self.fileExtension = "xml"
      self.entryDelimiter = "\n"
      self.fileWrapperGenerator = { (isPreamble) in
        if isPreamble {
          return "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\" ?>\n"
            + "<!-- File generated by Slogger: \"http://dgoodine.github.io/Slogger/\" -->\n"
            + "<log>\n"
        } else {
          return "\n</log>\n"
        }
      }
    }
  }

  init(directory: String, config: XMLConfiguration = XMLConfiguration()) {
    super.init(directory: directory, config: config)
  }
}

public class XMLGenerator : Generator {

  override func emitBegin(outputString: NSMutableString) {
    outputString.appendString("<entry>")
  }

  override func emit (outputString : NSMutableString, _ detail: Detail, _ type: ValueType) {
    switch type {

    case .BoolValue (let key, let value):
      outputString.appendString("<\(key)>\(value)</\(key)>")

    case .IntValue (let key, let value):
      outputString.appendString("<\(key)>\(value)</\(key)>")

    case .StringValue(let key, let value):
      outputString.appendString("<\(key)><![CDATA[\(value)]]></\(key)>")

    case .DateValue(let key, let value):
      let ds = dateFormatter.stringFromDate(value)
      outputString.appendString("<\(key)>\(ds)</\(key)>")
    }
  }

  override func emitDelimiter(outputString: NSMutableString) {
    outputString.appendString("")
  }

  override func emitEnd(outputString: NSMutableString) {
    outputString.appendString("</entry>")
  }

}