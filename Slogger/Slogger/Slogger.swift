//
//  Slogger.swift
//  Slogger
//
//  Created by David Goodine on 10/20/15.
//

import Foundation

public typealias LogClosure = () -> String

// Marker protocol for client-provided logging category enums
public protocol SloggerCategory : Hashable {}
public enum NoCategories : SloggerCategory {
  case None
}

public enum Level : Int, Comparable {
  case None, Severe, Error, Warning, Info, Debug, Verbose, Trace

  // Swift really should support this implicitly.
  static func allValues () -> [Level] {
    return [None, Severe, Error, Warning, Info, Debug, Verbose, Trace]
  }
}

// Swift really should support this implicitly.
public func <<T: RawRepresentable where T.RawValue: Comparable>(a: T, b: T) -> Bool {
  return a.rawValue < b.rawValue
}

public enum Detail : Int {
  case Date, File, Function, Level, Category
}

public typealias Generator = (message: String, category: Any?, level: Level,
  function: String, file: String, line: Int, details : [Detail], dateFormatter: NSDateFormatter) -> String

public protocol Destination {
  var colorMap : ColorMap? { get set }
  var decorator : Decorator? { get set }
  var generator : Generator? { get set }

  init (generator: Generator?, colorMap : ColorMap?)

  func logString(string : String, level: Level)
}

public class Slogger <T: SloggerCategory> : NSObject {

  public var currentLevel : Level

  public var dateFormatter : NSDateFormatter

  public var details : [Detail]

  public var categories : [T : Level] = Dictionary<T, Level>()

  public var destinations : [Destination] = Array<Destination>()

  public var defaultGenerator : Generator = { (message, category, level, function, file, line, details, dateFormatter) -> String in
    /* TODO: I would have just made this a closure call to an internal function, but for some reason was getting
    a compiler error.  Swift's type checking is still a little wonky. */
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
    str.appendString(message)
    return str as String
  }

  public var colorMap : ColorMap = [
    Level.Severe : (colorFromHexString("FF0000"), nil),
    Level.Error : (colorFromHexString("FF8503"), nil),
    Level.Warning : (colorFromHexString("FF03FB"), nil),
    Level.Info : (colorFromHexString("444444"), nil),
    Level.Debug : (colorFromHexString("035FFF"), nil),
    Level.Verbose : (colorFromHexString("666666"), nil),
    Level.Trace : (colorFromHexString("009C03"), nil)
  ]

  // Mark: Stats
  public var hits : Int64 = 0
  public var misses : Int64 = 0

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
    self.destinations = [ConsoleDestination(colorMap: colorMap)]
  }

  public func canLogWithCondition (condition: Bool, category: T?, level: Level) -> Bool {
    guard condition else {
      return false
    }

    var operatingLevel = currentLevel
    if category != nil, let categoryLevel = categories[category!] {
      operatingLevel = categoryLevel
    }

    return level <= operatingLevel
  }

  // MARK: Internal
  func logInternal (condition: Bool, @noescape _ closure: LogClosure, category: T?, level: Level,
    function: String, file: String, line: Int) {

      guard canLogWithCondition(condition, category: category, level: level) else {
        misses++
        return;
      }

      hits++

      let message = closure()
      var defaultString : String? = nil

      for dest in destinations {
        let generator = dest.generator
        let string : String?
        if generator != nil {
          string = generator!(message: message, category: category, level: level,
            function: function, file: file, line: line, details: details, dateFormatter: dateFormatter)
        } else {
          if defaultString == nil {
            defaultString = defaultGenerator(message: message, category: category, level: level,
              function: function, file: file, line: line, details: details, dateFormatter: dateFormatter)
          }
          string = defaultString
        }
        dest.logString(string!, level: level)
      }
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






