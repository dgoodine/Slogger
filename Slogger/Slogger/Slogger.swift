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
  case None, Severe, Error, Warning, Info, Debug, Verbose, Trace

  // Wow.  This is pretty dumb.
  static func allValues () -> [Level] {
    return [None, Severe, Error, Warning, Info, Debug, Verbose, Trace]
  }
}

// Marker protocol for client-provided logging category enums

public func <<T: RawRepresentable where T.RawValue: Comparable>(a: T, b: T) -> Bool {
  return a.rawValue < b.rawValue
}

public enum Detail : Int {
  case Date, File, Function, Level, Category
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
    self.details = (details != nil) ? details! : [.Date, .File, .Function, .Category, .Level]
  }

  // MARK: Private
  private func canLog (category: T?, level: Level) -> Bool {
    var operatingLevel = currentLevel
    if category != nil, let categoryLevel = categories[category!] {
      operatingLevel = categoryLevel
    }

    return level <= operatingLevel
  }

  func logInternal (condition: Bool, @noescape _ closure: LogClosure, category: T?, level: Level, function: String, file: String, line: Int) {

    guard canLog(category, level: level) else {
      return;
    }

    let string = closure()
    let str : NSMutableString = NSMutableString()
    str.appendString("-")

    func maybeSpace () {
      if str.length > 0 {
        str.appendString(" ")
      }
    }

    for detail in details {
      maybeSpace()

      switch detail {

      case .Category:
        if category != nil {
          str.appendString("[\(category!)]")
        } else {
          str.appendString("[]")
        }

      case .File:
        var f = file as NSString
        f = f.lastPathComponent
        str.appendString(f as String)
        str.appendString(":")
        str.appendString("\(line)")

      case .Function:
        str.appendString(function)

      case .Level:
        str.appendString("\(level)")

      case .Date:
        let dateString = dateFormatter.stringFromDate(NSDate())
        str.appendString("[\(dateString)]")
      }
    }

    str.appendString(": ")
    str.appendString(string)
    print(str)
  }
}

// MARK: - Log site functions
extension Slogger {
  // MARK: Severe
  public func severe (@autoclosure  closure: LogClosure, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__) {
    logInternal(true, closure, category: nil, level: .Severe, function: function, file: file, line: line)
  }

  public func severe (category: T?, @autoclosure _ closure: LogClosure, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__) {
    logInternal(true, closure, category: category, level: .Severe, function: function, file: file, line: line)
  }

  public func severe (function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__, @noescape closure: LogClosure) {
    logInternal(true, closure, category: nil, level: .Severe, function: function, file: file, line: line)
  }

  public func severe (category: T?, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__, @noescape closure: LogClosure) {
    logInternal(true, closure, category: category, level: .Severe, function: function, file: file, line: line)
  }

  // MARK: Error
  public func error (@autoclosure  closure: LogClosure, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__) {
    logInternal(true, closure, category: nil, level: .Error, function: function, file: file, line: line)
  }

  public func error (category: T?, @autoclosure _ closure: LogClosure, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__) {
    logInternal(true, closure, category: category, level: .Error, function: function, file: file, line: line)
  }

  public func error (function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__, @noescape closure: LogClosure) {
    logInternal(true, closure, category: nil, level: .Error, function: function, file: file, line: line)
  }

  public func error (category: T?, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__, @noescape closure: LogClosure) {
    logInternal(true, closure, category: category, level: .Error, function: function, file: file, line: line)
  }

  // MARK: Warning
  public func warning (@autoclosure  closure: LogClosure, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__) {
    logInternal(true, closure, category: nil, level: .Warning, function: function, file: file, line: line)
  }

  public func warning (category: T?, @autoclosure _ closure: LogClosure, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__) {
    logInternal(true, closure, category: category, level: .Warning, function: function, file: file, line: line)
  }

  public func warning (function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__, @noescape closure: LogClosure) {
    logInternal(true, closure, category: nil, level: .Warning, function: function, file: file, line: line)
  }

  public func warning (category: T?, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__, @noescape closure: LogClosure) {
    logInternal(true, closure, category: category, level: .Warning, function: function, file: file, line: line)
  }

  // MARK: Info
  public func info (@autoclosure  closure: LogClosure, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__) {
    logInternal(true, closure, category: nil, level: .Info, function: function, file: file, line: line)
  }

  public func info (category: T?, @autoclosure _ closure: LogClosure, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__) {
    logInternal(true, closure, category: category, level: .Info, function: function, file: file, line: line)
  }

  public func info (function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__, @noescape closure: LogClosure) {
    logInternal(true, closure, category: nil, level: .Info, function: function, file: file, line: line)
  }

  public func info (category: T?, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__, @noescape closure: LogClosure) {
    logInternal(true, closure, category: category, level: .Info, function: function, file: file, line: line)
  }

  // MARK: Debug
  public func debug (@autoclosure  closure: LogClosure, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__) {
    logInternal(true, closure, category: nil, level: .Debug, function: function, file: file, line: line)
  }

  public func debug (category: T?, @autoclosure _ closure: LogClosure, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__) {
    logInternal(true, closure, category: category, level: .Debug, function: function, file: file, line: line)
  }

  public func debug (function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__, @noescape closure: LogClosure) {
    logInternal(true, closure, category: nil, level: .Debug, function: function, file: file, line: line)
  }

  public func debug (category: T?, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__, @noescape closure: LogClosure) {
    logInternal(true, closure, category: category, level: .Debug, function: function, file: file, line: line)
  }

  // MARK: Verbose
  public func verbose (@autoclosure  closure: LogClosure, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__) {
    logInternal(true, closure, category: nil, level: .Verbose, function: function, file: file, line: line)
  }

  public func verbose (category: T?, @autoclosure _ closure: LogClosure, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__) {
    logInternal(true, closure, category: category, level: .Verbose, function: function, file: file, line: line)
  }

  public func verbose (function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__, @noescape _ closure: LogClosure) {
    logInternal(true, closure, category: nil, level: .Verbose, function: function, file: file, line: line)
  }

  public func verbose (category: T?, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__, @noescape _ closure: LogClosure) {
    logInternal(true, closure, category: category, level: .Verbose, function: function, file: file, line: line)
  }

  // MARK: Trace
  public func trace (condition: Bool, @autoclosure  _ closure: LogClosure, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__) {
    logInternal(condition, closure, category: nil, level: .Trace, function: function, file: file, line: line)
  }

  public func trace (category: T?, _ condition: Bool, @autoclosure _ closure: LogClosure, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__) {
    logInternal(condition, closure, category: category, level: .Trace, function: function, file: file, line: line)
  }

  public func trace (condition: Bool, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__, @noescape closure: LogClosure) {
    logInternal(condition, closure, category: nil, level: .Trace, function: function, file: file, line: line)
  }

  public func trace (category: T?, _ condition: Bool, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__, @noescape closure: LogClosure) {
    logInternal(condition, closure, category: category, level: .Trace, function: function, file: file, line: line)
  }


}




