//
//  Slogger.swift
//  Slogger
//
//  Created by David Goodine on 10/20/15.
//  Copyright © 2015 David Goodine. All rights reserved.
//

import Foundation

public typealias LogClosure = () -> String

public protocol SloggerCategory : Hashable {}

public enum Level : Int, Comparable {
  case None, Severe, Error, Warning, Info, Debug, Verbose
}

// Marker protocol for client-provided logging category enums

public func <<T: RawRepresentable where T.RawValue: Comparable>(a: T, b: T) -> Bool {
  return a.rawValue < b.rawValue
}

public enum Detail : Int {
  case Time = 0, File, Function, Level, Category
}

public class Slogger <T: SloggerCategory> : NSObject {

  public var currentLevel : Level
  public var dateFormatter : NSDateFormatter
  public var details : [Detail]
  public var categories : [T : Level] = Dictionary<T, Level>()

  // MARK: Initialization
  public init (defaultLevel : Level, dateFormatter : NSDateFormatter? = nil, details : [Detail]? = nil) {
    var df = dateFormatter
    if df == nil {
      let template = "yyyy.MM.dd HH:mm:ss zzz"
      let locale = NSLocale.currentLocale()
      let dateFormat = NSDateFormatter.dateFormatFromTemplate(template, options: 0, locale: locale)
      let idf = NSDateFormatter()
      idf.dateFormat = dateFormat
      df = idf
    }

    self.currentLevel = defaultLevel
    self.dateFormatter = df!
    self.details = (details != nil) ? details! : [.Time, .File, .Function, .Level, .Category]
  }

  // MARK: Public
  public func error (function: String = __FUNCTION__, _ file: String = __FILE__, _ line: Int = __LINE__, @autoclosure closure: LogClosure) {
      logInternal(closure, category: nil, level: .Error, function: function, file: file, line: line)
  }

  public func error (category: T? = nil, @autoclosure _ closure: LogClosure,
     _ function: String = __FUNCTION__, _ file: String = __FILE__, _ line: Int = __LINE__) {
    logInternal(closure, category: category, level: .Error, function: function, file: file, line: line)
  }

  public func warning (@autoclosure closure: LogClosure,
    category: T? = nil, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__)  {
    logInternal(closure, category: category, level: .Warning, function: function, file: file, line: line)
  }

  public func info (@autoclosure closure: LogClosure,
    category: T? = nil, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__)  {
    logInternal(closure, category: category, level: .Info, function: function, file: file, line: line)
  }

  public func debug (@autoclosure closure: LogClosure,
    category: T? = nil, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__)  {
    logInternal(closure, category: category, level: .Debug, function: function, file: file, line: line)
  }

  public func verbose (@autoclosure closure: LogClosure,
    category: T? = nil, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__)  {
    logInternal(closure, category: category, level: .Verbose, function: function, file: file, line: line)
  }

  // MARK: Private
  private func canLog (category: T?, level: Level) -> Bool {
    var operatingLevel = currentLevel
    if category != nil, let categoryLevel = categories[category!] {
      operatingLevel = categoryLevel
    }

    return level <= operatingLevel
  }

  private func logInternal (@autoclosure closure: LogClosure, category: T?, level: Level, function: String, file: String, line: Int) {

      guard canLog(category, level: level) else {
        return;
      }

      let string = closure()
      let str : NSMutableString = NSMutableString()
      for detail in details {
        switch detail {
        case .Category:
          if category != nil {
            str.appendString("\(category!)")
          }

        case .File:
          let f = __FILE__
          str.appendString(f)
          break

        case .Function:
          str.appendString(function)
          break

        case .Level:
          break

        case .Time:
          break
        }
      }
      
      str.appendString(": ")
      str.appendString(string)
      print(str)
  }
}




