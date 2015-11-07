//
//  JSONFileDestination.swift
//  Slogger
//
//  Created by David Goodine on 11/7/15.
//  Copyright © 2015 David Goodine. All rights reserved.
//

import Foundation

public class JSONFileDestination : TextFileDestination {

  public class JSONConfiguration : Configuration {

    public init () {
      super.init()
      self.fileExtension = "json"
      self.entryDelimiter = ",\n"

      self.fileWrapperGenerator = {
        (isPreamble) in
        if isPreamble {
          return "[\n"
        }
        return "]"
      }

      self.generator = {
        (message, category, override, level, date, function, file, line, details, dateFormatter) -> String in

        let str : NSMutableString = NSMutableString(capacity: 512)
        str.appendString("{")

        func jsonString (key : String, _ value : String) {
          let val = value.stringByReplacingOccurrencesOfString("\"", withString: "\\\"")
          str.appendString("\"\(key)\":\"\(val)\"")
        }

        func jsonBool (key : String, _ value : Bool) {
          str.appendString("\"\(key)\":\(value)")
        }

        func jsonInt (key : String, _ value : Int) {
          str.appendString("\"\(key)\":\(value)")
        }

        jsonBool("override", override != nil)

        for detail in details {
          str.appendString(",")

          switch detail {

          case .Category:
            jsonString("category", category == nil ? "" : "\(category!)")

          case .File:
            let f = file as NSString
            let filename = f.lastPathComponent
            jsonString("file", filename)
            str.appendString(",")
            jsonInt("line", line)

          case .Function:
            jsonString("function", function)

          case .Level:
            jsonString("level", "\(level)")

          case .Date:
            jsonString("date", dateFormatter.stringFromDate(date))
          }
        }

        str.appendString(",")
        jsonString("message", message)
        str.appendString("}")

        return str as String
      }
    }
  }

  override init(directory: String, config: Configuration = JSONConfiguration()) {
    super.init(directory: directory, config: config)
  }
}

