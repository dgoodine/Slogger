//
//  Slogger.swift
//  Slogger
//
//  Created by David Goodine on 10/20/15.
//

import Foundation

public typealias LogClosure = () -> String

/** 
 Marker protocol for client-provided logging category enums
*/
public protocol SloggerCategory : Hashable {}

/**
 Default enum for instantiating a generic Slogger class
 
 - None: Don't use it.
*/
public enum NoCategories : SloggerCategory {
  case None
}

/**
 Logging levels – Cumulatave upward (ex. .Error logs both .Error and .Severe events).
 
 - None: Turn off all logging
 - Severe: Use this for cataclysmic events
 - Error: Use this for things that shouldn't really happen
 - [Warning]: Use this if something seems awry (ignore the brackets)
 - Debug: Use this to look at runtime details of things
 - Verbose: WTF is going on in my app?
 - Trace: (special) See 'log.trace' documentation

 */
public enum Level : Int, Comparable {
  case None, Severe, Error, Warning, Info, Debug, Verbose, Trace

  /**
   - Returns: all values in the enumeration
  */
  static func allValues () -> [Level] {
    return [None, Severe, Error, Warning, Info, Debug, Verbose, Trace]
  }
}

// Swift really should support this implicitly.
public func <<T: RawRepresentable where T.RawValue: Comparable>(a: T, b: T) -> Bool {
  return a.rawValue < b.rawValue
}

/**
 An enumeration of the types of information passed to a generator for a log event

 - [Date]: Date and time of the event (ignore the brackets)
 - File: File and line number of the logging site
 - Function: The function the logging site is in
 - Level: The logging level of the site
 - Category: The category specified in the logging site
*/
public enum Detail : Int {
  case Date, File, Function, Level, Category
}

/**
 A type alias for Generator closures.

 - Parameter message: The message string at the logging site
 - Parameter category: The category specified in the logging site
 - Parameter level: The logging level of the site
 - Parameter function: The function the logging site is in
 - Parameter file: File and line number of the logging site
 - Parameter line: The line number of the logging site
 - Parameter details: The ordered array of detail enum values for information that should be emitted
 - Parameter dateFormatter: The dateFormatter to use.
 
 - Returns: A string representation of the generator output
*/
public typealias Generator = (message: String, category: Any?, level: Level,
  function: String, file: String, line: Int, details : [Detail], dateFormatter: NSDateFormatter) -> String

/**
 The protocol that all logging destination types must conform to
*/
public protocol Destination {
  /** A custom generator for this destination.  If not provided, use the default provided by the logger. */
  var generator : Generator? { get set }

  /** A custom color map for this destination.  If not provided, use the default provided by the logger. */
  var colorMap : ColorMap? { get set }

  /** A custom decorator for this destination */
  var decorator : Decorator? { get set }

  /**
   Required initializer.

   - Parameter generator: A custom generator to use for this destination.
   - Parameter colorMap: A custom colormap to use for this destination.
   */
  init (generator: Generator?, colorMap : ColorMap?, decorator: Decorator?)

  /**
   The basic logging function.
   - Parameter string: The fully generated and decorated log string for the event
   - Parameter level: The level of the logging site.  Provided for some special cases such as testing.
   */
  func logString(string : String, level: Level)
}

// MARK: - Main Class
/**
 The main logger class.  It's operation should be fairly intuitive and the properties and functions should
 be adequately documented herein.
 
 The 'SloggerTests.swift' file is a very good place to look for examples of advanced usage, including
 how to subclass this class to use your own categories.
 
 All public properties are designed to allow any changes at runtime, so you can dynamically change
 while debugging. You could even change them programatically in your code if you need to track down a bug in the
 middle of heaps of calls by setting a higher, more verbose debug level in a function.
 
 A typical strategy in a function might be:
 1. Capture the current log level
 1. Evaluate a test to see if the conditions require deeper logging
 1. If so, set the logging level higher
 1. Execute the body of the function
 1. If the condition in step 2 was true, reset 'log.loglevel' back to the saved value

*/
public class Slogger <T: SloggerCategory> : NSObject {

  /**
   The current operating level of the logger. 
   */
  public var currentLevel : Level

  /**
   The current operating level of the logger. 
   */
  public var dateFormatter : NSDateFormatter

  /**
   The current detail array representing the fields for the generator to output. A generator implemenetation
   is free to choose to ignore details that are irrelevant for that generator.
   */
  public var details : [Detail]

  /** 
   A dictionary of category  to level associations.  If a value exists for a given category, that level will be used
   for all logging sites that specify that category, instead of the currentLevel.
   */
  public var categories : [T : Level] = Dictionary<T, Level>()

  /**
   The default consoleDestination.  Can be accessed if you want to operate on it directly.
   */
  public var consoleDestination : Destination

  /**
   The curent destinations this logger will write to.  If this array is empty, logging will be evaluated normally.
   (This can be useful for performance testing.)
   
   You can modify this array as you wish at any time while your app is running.
   */
  public var destinations : [Destination] = Array<Destination>()

  /**
   The default (log4j-style) generator function.
   
   Ouput looks like this:

       - [10/25/2015, 17:07:52.302 EDT] SloggerTests.swift:118 callIt [] Severe: String

   */
  public var defaultGenerator : Generator = { (message, category, level, function, file, line, details, dateFormatter) -> String in
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

  /**
   The current colorMap.  See 'Color.swift' for more information on creating your own.
   */
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
  /**
  The number of logging hits (actual logged events) so far.
  */
  public var hits : Int64 = 0

  /**
   The number of logging misses (events not logged due to level) so far.
   */
  public var misses : Int64 = 0

  // MARK: Initialization
  /**
  The default initializer.
  
  - Parameter defaultLevel: Sets the 'currentLevel' property to this value.
  - Parameter dateFormatter: The date formatter to use for dates.  It has a typical default.
  - Parameter details: The order detail for the generator to output.
  */
  public init (defaultLevel : Level, dateFormatter : NSDateFormatter? = nil, details : [Detail]? = nil) {
    var df = dateFormatter
    if df == nil {
      let template = "yyyy.MM.dd HH:mm:ss.SSS zzz"
      let locale = NSLocale.currentLocale()
      let dateFormat = NSDateFormatter.dateFormatFromTemplate(template, options: 0, locale: locale)
      let idf = NSDateFormatter()
      idf.dateFormat = dateFormat
      df = idf
    }

    self.currentLevel = defaultLevel
    self.dateFormatter = df!
    self.details = (details != nil) ? details! : [.Date, .File, .Function, .Category, .Level]
    self.consoleDestination = ConsoleDestination(colorMap: colorMap, decorator: XCodeColorsDecorator())
    self.destinations = [consoleDestination]
  }

  // MARK: Public
  /**
   The internal function used to determine if an event can be logged.  It's provided to allow for special use-cases,
   but shouldn't be needed in code.
   
   - Parameter condition: The condition (see the 'trace' documentation).  If it is false, the test MUST fail.
   - Parameter category: The category of the logging site or nil.  Used to evaluate category
   specific debugging level configuration.
   - Parameter level: The value of the 'currentLevel' property.
   
   - Returns: true of the logging of the event should proceed, false if it shouldn't
   */
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
/**
This extension holds the public convenience methods for logging.  They should be the only ones used at logging sites.
*/
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






