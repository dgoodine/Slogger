//
//  Slogger.swift
//  Slogger
//
//  Created by David Goodine on 10/20/15.
//  Copyright © 2015 David Goodine. All rights reserved.
//

import Foundation

public typealias LogClosure = () -> String

/**
 Marker protocol for client-provided logging category enums
 */
public protocol SloggerCategory : Hashable {}

/**
 Default enum for instantiating a generic Slogger class
 */
public enum NoCategories : SloggerCategory {
  /// Don't use this
  case None
}

/**
 Logging levels – Cumulatave upward (ex. .Error logs both .Error and .Severe events).
 */
public enum Level : Int, Comparable {
  /// Turn off all logging (except traces)
  case None

  /// Use this for cataclysmic events
  case Severe

  /// Use this for things that shouldn't really happen
  case Error

  /// Use this if something seems awry (ignore the brackets)
  case Warning

  /// Use this for general operational information
  case Info

  /// Use this for deeper debugging
  case Debug

  /// "WTF is going on in my app?"
  case Verbose

  /**
   - Returns: all values in the enumeration
   */
  static func allValues () -> [Level] {
    return [None, Severe, Error, Warning, Info, Debug, Verbose]
  }
}

// Swift really should support this implicitly.
public func <<T: RawRepresentable where T.RawValue: Comparable>(a: T, b: T) -> Bool {
  return a.rawValue < b.rawValue
}

/**
 An enumeration of the types of information passed to a generator for a log event
 */
public enum Detail : Int {
  ///  Date and time of the event (ignore the brackets)
  case Date

  /// File and line number of the logging site
  case File

  /// The function the logging site is in
  case Function

  /// The logging level of the site
  case Level

  /// The category specified in the logging site
  case Category
}

/**
 A type alias for Generator closures.

 - Parameter message: The message string at the logging site
 - Parameter override: The override value
 - Parameter category: The category specified in the logging site
 - Parameter level: The logging level of the site
 - Parameter function: The function the logging site is in
 - Parameter file: File and line number of the logging site
 - Parameter line: The line number of the logging site
 - Parameter details: The ordered array of detail enum values for information that should be emitted
 - Parameter dateFormatter: The dateFormatter to use.

 - Returns: A string representation of the generator output
 */
public typealias Generator = (message: String, override: Bool, category: Any?, level: Level, function: String, file: String, line: Int, details : [Detail], dateFormatter: NSDateFormatter) -> String

/**
 The protocol that all logging destination types must conform to
 */
public protocol Destination {
  /** A custom generator for this destination.  If not provided, the logger value will be used. */
  var generator : Generator? { get set }

  /** A custom color map for this destination.  If not provided, the logger value will be used. */
  var colorMap : ColorMap? { get set }

  /** A custom decorator for this destination.  If not provided, the logger value will be used. */
  var decorator : Decorator? { get set }

  /**
   The basic logging function.

   - Parameter string: The fully generated and decorated log string for the event
   - Parameter level: The level of the logging site.  Provided for some special cases such as testing.
   */
  func logString(string : String, level: Level)
}

/**
 Protocol for type used to decorate generator output.
 */
public protocol Decorator {

  /**
   The decorator function.

   - Parameter string: The string to decorate
   - Parameter colorSpec: The color spec to use for decoration
   - Returns: The decorated string
   */
  func decorateString(string : String, spec: ColorSpec) -> String
}


// MARK: - Main Class

/**
The main logger class.  It's operation should be fairly intuitive and the properties and functions should
be adequately documented herein.

The 'SloggerTests.swift' file is a very good place to look for examples of advanced usage, including
how to subclass this class to use your own categories.  Check out the Slogger extension below for logging site
functions documentation.  Only the *severe* level functions are documented.  All other functions related to logging
site levels are identical.

All public properties are designed to allow any changes at runtime, so you can dynamically change
while debugging. You could even change them programatically in your code if you need to track down a bug in the
middle of heaps of calls by setting a higher, more verbose debug level in a function.

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
   The default generator function.

   Ouput looks like this:

   - [10/25/2015, 17:07:52.302 EDT] SloggerTests.swift:118 callIt [] Severe: String

   */
  public var defaultGenerator : Generator = { (message, override, category, level, function, file, line, details, dateFormatter) -> String in
    let prefix = (override) ? "*" : "-"
    let str : NSMutableString = NSMutableString(capacity: 100)
    str.appendString(prefix)

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
  public var colorMap : ColorMap
  = [
    Level.Severe : (colorFromHexString("FF0000"), nil),
    Level.Error : (colorFromHexString("FF5500"), nil),
    Level.Warning : (colorFromHexString("FF03FB"), nil),
    Level.Info : (colorFromHexString("008C31"), nil),
    Level.Debug : (colorFromHexString("035FFF"), nil),
    Level.Verbose : (colorFromHexString("666666"), nil),
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
  but shouldn't be needed at logging sites since the message closure is only evaluated if this returns to true.

  - Parameter override: If it is true, this function will return true, regardless of log level.
  - Parameter category: The category of the logging site or nil.  Used to evaluate category specific debugging level configuration.
  - Parameter level: The value of the 'currentLevel' property.

  - Returns: true of the logging of the event should proceed, false if it shouldn't
  */
  public func canLogWithOverride (override: Bool, category: T?, level: Level) -> Bool {
    guard override == false else {
      return true
    }

    var operatingLevel = currentLevel
    if category != nil, let categoryLevel = categories[category!] {
      operatingLevel = categoryLevel
    }

    return level <= operatingLevel
  }

  // MARK: Internal
  func logInternal (override: Bool, @noescape _ closure: LogClosure, category: T?, level: Level, function: String, file: String, line: Int) {

    guard canLogWithOverride(override, category: category, level: level) else {
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
        string = generator!(message: message, override: override, category: category, level: level,
          function: function, file: file, line: line, details: details, dateFormatter: dateFormatter)
      } else {
        if defaultString == nil {
          defaultString = defaultGenerator(message: message, override: override, category: category, level: level,
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
  /**
  Log a *severe* level event.  The first arugment is an @autoclosure returning the message string.
  This logging site has no category.
  - Parameter override: If *true* it will cause the event to be logged regardless of level evaluation.  Detaults to *false*.
  - Parameter function: The function within which the logging site is contained.  It should remain as the default.
  - Parameter file: The file within which the logging site is contained.  It should remain as the default.
  - Parameter line: The line in the file of the logging site.  It should remain as the default.
  */
  public func severe (@autoclosure  closure: LogClosure, override: Bool = false, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__) {
    logInternal(override, closure, category: nil, level: .Severe, function: function, file: file, line: line)
  }

  /**
   Log a *severe* level event.
   The first argument is the category of the logging site.
   The second arugment is an @autoclosure returning the message string.
   - Parameter override: If *true* it will cause the event to be logged regardless of level evaluation.  Detaults to *false*
   - Parameter function: The function within which the logging site is contained.  It should remain as the default.
   - Parameter file: The file within which the logging site is contained.  It should remain as the default.
   - Parameter line: The line in the file of the logging site.  It should remain as the default.
   */
  public func severe (category: T?, @autoclosure _ closure: LogClosure, override: Bool = false, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__) {
    logInternal(override, closure, category: category, level: .Severe, function: function, file: file, line: line)
  }

  /**
   Log a *severe* level event.
   The last argument is a trailing @noescape closure that produces the message string.
   This logging site has no category.
   - Parameter override: If *true* it will cause the event to be logged regardless of level evaluation.  Detaults to *false*
   - Parameter function: The function within which the logging site is contained.  It should remain as the default.
   - Parameter file: The file within which the logging site is contained.  It should remain as the default.
   - Parameter line: The line in the file of the logging site.  It should remain as the default.
   */
  public func severe (override: Bool = false, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__, @noescape closure: LogClosure) {
    logInternal(override, closure, category: nil, level: .Severe, function: function, file: file, line: line)
  }

  /**
   Log a *severe* level event.
   The first argument is the category of the logging site.
   The last argument is a trailing @noescape closure that produces the message string.
   - Parameter override: If *true* it will cause the event to be logged regardless of level evaluation.  Detaults to *false*
   - Parameter function: The function within which the logging site is contained.  It should remain as the default.
   - Parameter file: The file within which the logging site is contained.  It should remain as the default.
   - Parameter line: The line in the file of the logging site.  It should remain as the default.
   */
  public func severe (category: T?, override: Bool = false, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__, @noescape closure: LogClosure) {
    logInternal(override, closure, category: category, level: .Severe, function: function, file: file, line: line)
  }

  // MARK: Error
  public func error (@autoclosure  closure: LogClosure, override: Bool = false, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__) {
    logInternal(override, closure, category: nil, level: .Error, function: function, file: file, line: line)
  }

  public func error (category: T?, @autoclosure _ closure: LogClosure, override: Bool = false, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__) {
    logInternal(override, closure, category: category, level: .Error, function: function, file: file, line: line)
  }

  public func error (override: Bool = false, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__, @noescape closure: LogClosure) {
    logInternal(override, closure, category: nil, level: .Error, function: function, file: file, line: line)
  }

  public func error (category: T?, override: Bool = false, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__, @noescape closure: LogClosure) {
    logInternal(override, closure, category: category, level: .Error, function: function, file: file, line: line)
  }

  // MARK: Warning
  public func warning (@autoclosure  closure: LogClosure, override: Bool = false, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__) {
    logInternal(override, closure, category: nil, level: .Warning, function: function, file: file, line: line)
  }

  public func warning (category: T?, @autoclosure _ closure: LogClosure, override: Bool = false, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__) {
    logInternal(override, closure, category: category, level: .Warning, function: function, file: file, line: line)
  }

  public func warning (override: Bool = false, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__, @noescape closure: LogClosure) {
    logInternal(override, closure, category: nil, level: .Warning, function: function, file: file, line: line)
  }

  public func warning (category: T?, override: Bool = false, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__, @noescape closure: LogClosure) {
    logInternal(override, closure, category: category, level: .Warning, function: function, file: file, line: line)
  }

  // MARK: Info
  public func info (@autoclosure  closure: LogClosure, override: Bool = false, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__) {
    logInternal(override, closure, category: nil, level: .Info, function: function, file: file, line: line)
  }

  public func info (category: T?, @autoclosure _ closure: LogClosure, override: Bool = false, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__) {
    logInternal(override, closure, category: category, level: .Info, function: function, file: file, line: line)
  }

  public func info (override: Bool = false, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__, @noescape closure: LogClosure) {
    logInternal(override, closure, category: nil, level: .Info, function: function, file: file, line: line)
  }

  public func info (category: T?, override: Bool = false, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__, @noescape closure: LogClosure) {
    logInternal(override, closure, category: category, level: .Info, function: function, file: file, line: line)
  }

  // MARK: Debug
  public func debug (@autoclosure  closure: LogClosure, override: Bool = false, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__) {
    logInternal(override, closure, category: nil, level: .Debug, function: function, file: file, line: line)
  }

  public func debug (category: T?, @autoclosure _ closure: LogClosure, override: Bool = false, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__) {
    logInternal(override, closure, category: category, level: .Debug, function: function, file: file, line: line)
  }

  public func debug (override: Bool = false, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__, @noescape closure: LogClosure) {
    logInternal(override, closure, category: nil, level: .Debug, function: function, file: file, line: line)
  }

  public func debug (category: T?, override: Bool = false, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__, @noescape closure: LogClosure) {
    logInternal(override, closure, category: category, level: .Debug, function: function, file: file, line: line)
  }

  // MARK: Verbose
  public func verbose (@autoclosure  closure: LogClosure, override: Bool = false, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__) {
    logInternal(override, closure, category: nil, level: .Verbose, function: function, file: file, line: line)
  }

  public func verbose (category: T?, @autoclosure _ closure: LogClosure, override: Bool = false, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__) {
    logInternal(override, closure, category: category, level: .Verbose, function: function, file: file, line: line)
  }

  public func verbose (override: Bool = false, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__, @noescape _ closure: LogClosure) {
    logInternal(override, closure, category: nil, level: .Verbose, function: function, file: file, line: line)
  }

  public func verbose (category: T?, override: Bool = false, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__, @noescape _ closure: LogClosure) {
    logInternal(override, closure, category: category, level: .Verbose, function: function, file: file, line: line)
  }
  
}






