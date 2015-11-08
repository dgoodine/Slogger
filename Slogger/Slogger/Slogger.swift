//
//  Slogger.swift
//  Slogger
//
//  Created by David Goodine on 10/20/15.
//  Copyright © 2015 David Goodine. All rights reserved.
//

import Foundation

public typealias LogClosure = () -> String

/// Protocol for client-provided logging category enums.
public protocol SloggerCategory : Hashable {}

/// Default enum for instantiating a generic Slogger class without categories.
public enum NoCategories : SloggerCategory {
  /// If you only need one category, you can use this. Not a likely use-case.
  case One
}

/// Logging levels – Cumulatave upward (ex. .Error logs both .Error and .Severe events).
public enum Level : Int, Comparable {
  /// Turn off all logging (except overrides).
  case None

  /// Use this for cataclysmic events.
  case Severe

  /// Use this for things that shouldn't really happen.
  case Error

  /// Use this if something seems awry.
  case Warning

  /// Use this for general operational information.
  case Info

  /// Use this for deeper debugging.
  case Debug

  /// Use this for even more verbose debugging.
  case Verbose

  /// All logging levels.
  static let allValues = [None, Severe, Error, Warning, Info, Debug, Verbose]
}

/// This is necessary because Swift doesn't provide it by default for Int-based enume
public func <<T: RawRepresentable where T.RawValue: Comparable>(a: T, b: T) -> Bool {
  return a.rawValue < b.rawValue
}

/// An enumeration of the types of information for a `Generator` to output.
public enum Detail : Int {
  /// Whether the event was an override
  case Override

  ///  Date and time of the event.
  case Date

  /// File of the logging site.
  case File

  /// File line number of the logging site
  case Line

  /// The function the logging site is in.
  case Function

  /// The logging level of the site.
  case Level

  /// The category specified in the logging site.
  case Category

  /// The message string produced at the logging site.
  case Message
}

/// Protocol for type used to decorate generator output.
public protocol Decorator {

  /**
   The decorator function.

   - Parameter string: The string to decorate.
   - Parameter colorSpec: The color spec to use for decoration.
   - Returns: The decorated string.
   */
  func decorateString(string : String, spec: ColorSpec) -> String
}


// MARK: - Slogger Class

/**
This is the main logger class.  Its operation should be fairly intuitive and the properties and functions are
fully documented herein.

The 'SloggerTests.swift' file is a very good place to look for examples of advanced usage, including
how to define a subclass to use your own categories.  Check out the Slogger extension below for logging site
functions documentation.  Only the *severe* level functions are documented.  All other functions related to logging
site levels are identical.

**Important Implementation Note**: *Slogger* uses a private, serial dispatch queue for most of its work, including
calls to the generator, decorator, and all logging destinations.  The only code executed synchronously by the logging
functions is the threshold evaluation (and only if `destinations.count > 0`) and, if that passes, evaulation of the
closure to produce the message from the logging site.  All other work is performed on a separate thread serially.

Thus, all *Slogger* types are inherently thread-safe. If you decide to implement your own, you can do so
without concern about concurrency issues. However, if you create a custom implementation of any type that requires
code be executed on the main thread, you **MUST** wrap that code inside a `dispatch_async` call to the main queue.

*/
public class Slogger <T: SloggerCategory> : NSObject {

  /// The active, global operating level of the logger.
  public var level : Level

  /// Local storage
  private var _details : [Detail] = [.Override, .Date, .File, .Line, .Function, .Category, .Level, .Message]

  /// An array representing what to output (and in what order) by a `Generator`.
  public var details : [Detail] {
    get { return _details }
    set { _details = newValue }
  }

  /// Local storage
  private var _categories : [T : Level] = Dictionary<T, Level>()

  /// A dictionary for providing a custom `Level` for each `Category` defined.
  public var categories : [T : Level] {
    get { return _categories }
    set {_categories = newValue }
  }

  /// The current generator closure.
  public var generator : Generator

  // Local Storage
  private var _destinations : [Destination] = []

  /// Destinations this logger will write to.
  public var destinations : [Destination] {
    get { return _destinations}
    set { _destinations = newValue }
  }

  /// Number of events logged.
  public var hits : UInt64 = 0

  /// Number of events that weren't logged due to logging threshold.
  public var misses : UInt64 = 0

  /// Used to turn off asynchronous operation for unit testing.
  var asynchronous = true

  /// Worker queue for processing logging work that has passed the level threshold test
  let workerQueue = dispatch_queue_create("Slogger queue", DISPATCH_QUEUE_SERIAL)

  // MARK: Initialization
  /**
  The default initializer.

  - Parameter defaultLevel: Sets the 'level' property to this value.
  - Parameter details: The detail for the generator to output at logging sites.
  */
  public init (defaultLevel : Level, details : [Detail]? = nil) {
    self.level = defaultLevel
    self.generator = defaultGenerator
    self.consoleDestination = ConsoleDestination()
  	self._destinations = [consoleDestination]

    if let details = details {
      self._details = details
    }
  }

  // MARK: Functions
  /**
  The internal function used to determine if an event can be logged.  It's public to allow for special use-cases,
  but shouldn't be needed at logging sites since the message closure is only evaluated if this returns `true`.
  The order of the parameters designates their precedence in evaluating the logging conidition.

  - Parameter override: If it is not nil, it will be used exclusively to determine if logging should proceeed.
  If the value is .None, the generator will not be called for this logging site and there will be no output.
  - Parameter category: The category of the logging site or nil.  Used to evaluate category specific debugging level configuration.
  - Parameter level: The default level of the logging site.

  - Returns: true of the logging of the event should proceed, false if it shouldn't
  */
  public func canLog (override override: Level?, category: T?, siteLevel: Level) -> Bool {
    let effectiveLevel : Level
    if override != nil {
      effectiveLevel = override!
    } else if category != nil, let categoryLevel = categories[category!] {
      effectiveLevel = categoryLevel
    } else {
      effectiveLevel = level
    }

    return effectiveLevel == .None ? false : siteLevel <= effectiveLevel
  }

  /// Resets `hits` and `misses` counters.
  public func resetStats () {
    hits = 0
    misses = 0
  }

  // MARK: Generators
  /**
   The default generator function. The ouput looks like this:

  	- [10/25/2015, 17:07:52.302 EDT] SloggerTests.swift:118 myFunction(_:) [] Severe: String
   */
  public let defaultGenerator : Generator = Generator()

  // MARK: Destinations
  /// The default consoleDestination.
  public let consoleDestination : Destination

  // MARK: Private
  func logInternal (@noescape closure closure: LogClosure, category: T?, override: Level?, level: Level, function: String, file: String, line: Int) {

    guard destinations.count > 0 else {
      return
    }

    guard canLog(override: override, category: category, siteLevel: level) else {
      misses = misses &+ 1
      return
    }

    let message = closure()
    let date = NSDate()
    let codeBlock = {
      self.hits = self.hits &+ 1

      var defaultString : String? = nil

      for dest in self.destinations {
        let string : String?
        if let generator = dest.generator {
          string = generator.generate(message: message, category: category, override: override, level: level, date: date,             function: function, file: file, line: line, details: self.details)
        }
        else if defaultString != nil {
          string = defaultString!
        }
        else {
          string = self.generator.generate(message: message, category: category, override: override, level: level, date: NSDate(), function: function, file: file, line: line, details: self.details)
          defaultString = string
        }

        if let string = string {
          dest.logString(string, level: level)
        }
      }
    }

    if (asynchronous) {
      dispatch_async(workerQueue, codeBlock)
    } else {
      codeBlock()
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
  Log a *severe* event.

  - Parameter closure: A closure that returns the message string.
  - Parameter override: If not nil, will be used to determine whether logging should output to the destinations.  Defaults to `nil`.
  - Parameter function: The function within which the logging site is contained.  It should remain as the default.
  - Parameter file: The file within which the logging site is contained.  It should remain as the default.
  - Parameter line: The line in the file of the logging site.  It should remain as the default.
  */
  public func severe (@autoclosure  closure: LogClosure, override: Level? = nil, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__) {
    logInternal(closure: closure, category: nil, override: override, level: .Severe, function: function, file: file, line: line)
  }

  /**
   Log a *severe* event.

   - Parameter category: The `Category` of the logging site.
   - Parameter closure: A closure that returns the message string.
   - Parameter override: If not nil, will be used to determine whether logging should output to the destinations.  Defaults to `nil`.
   - Parameter function: The function within which the logging site is contained.  It should remain as the default.
   - Parameter file: The file within which the logging site is contained.  It should remain as the default.
   - Parameter line: The line in the file of the logging site.  It should remain as the default.
   */
  public func severe (category: T?, @autoclosure _ closure: LogClosure, override: Level? = nil, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__) {
    logInternal(closure: closure, category: category, override: override, level: .Severe, function: function, file: file, line: line)
  }

  /**
   Log a *severe* event.

   - Parameter override: If not nil, will be used to determine whether logging should output to the destinations.  Defaults to `nil`.
   - Parameter function: The function within which the logging site is contained.  It should remain as the default.
   - Parameter file: The file within which the logging site is contained.  It should remain as the default.
   - Parameter line: The line in the file of the logging site.  It should remain as the default.
   - Parameter closure: A closure that returns the message string.
   */
  public func severe (override: Level? = nil, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__, @noescape closure: LogClosure) {
    logInternal(closure: closure, category: nil, override: override, level: .Severe, function: function, file: file, line: line)
  }

  /**
   Log a *severe* event.

   - Parameter category: The `Category` of the logging site.
   - Parameter override: If not nil, will be used to determine whether logging should output to the destinations.  Defaults to `nil`.
   - Parameter function: The function within which the logging site is contained.  It should remain as the default.
   - Parameter file: The file within which the logging site is contained.  It should remain as the default.
   - Parameter line: The line in the file of the logging site.  It should remain as the default.
   - Parameter closure: A closure that returns the message string.
   */
  public func severe (category: T?, override: Level? = nil, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__, @noescape closure: LogClosure) {
    logInternal(closure: closure, category: category, override: override, level: .Severe, function: function, file: file, line: line)
  }

  // MARK: Error
  /// See the `severe` functions for documentation.
  public func error (@autoclosure  closure: LogClosure, override: Level? = nil, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__) {
    logInternal(closure: closure, category: nil, override: override, level: .Error, function: function, file: file, line: line)
  }

  /// See the `severe` functions for documentation.
  public func error (category: T?, @autoclosure _ closure: LogClosure, override: Level? = nil, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__) {
    logInternal(closure: closure, category: category, override: override, level: .Error, function: function, file: file, line: line)
  }

  /// See the `severe` functions for documentation.
  public func error (override override: Level? = nil, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__, @noescape closure: LogClosure) {
    logInternal(closure: closure, category: nil, override: override, level: .Error, function: function, file: file, line: line)
  }

  /// See the `severe` functions for documentation.
  public func error (category: T?, override: Level? = nil, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__, @noescape closure: LogClosure) {
    logInternal(closure: closure, category: category, override: override, level: .Error, function: function, file: file, line: line)
  }

  // MARK: Warning
  /// See the `severe` functions for documentation.
  public func warning (@autoclosure  closure: LogClosure, override: Level? = nil, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__) {
    logInternal(closure: closure, category: nil, override: override, level: .Warning, function: function, file: file, line: line)
  }

  /// See the `severe` functions for documentation.
  public func warning (category: T?, @autoclosure _ closure: LogClosure, override: Level? = nil, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__) {
    logInternal(closure: closure, category: category, override: override, level: .Warning, function: function, file: file, line: line)
  }

  /// See the `severe` functions for documentation.
  public func warning (override override: Level? = nil, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__, @noescape closure: LogClosure) {
    logInternal(closure: closure, category: nil, override: override, level: .Warning, function: function, file: file, line: line)
  }

  /// See the `severe` functions for documentation.
  public func warning (category: T?, override: Level? = nil, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__, @noescape closure: LogClosure) {
    logInternal(closure: closure, category: category, override: override, level: .Warning, function: function, file: file, line: line)
  }

  // MARK: Info
  /// See the `severe` functions for documentation.
  public func info (@autoclosure  closure: LogClosure, override: Level? = nil, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__) {
    logInternal(closure: closure, category: nil, override: override, level: .Info, function: function, file: file, line: line)
  }

  /// See the `severe` functions for documentation.
  public func info (category: T?, @autoclosure _ closure: LogClosure, override: Level? = nil, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__) {
    logInternal(closure: closure, category: category, override: override, level: .Info, function: function, file: file, line: line)
  }

  /// See the `severe` functions for documentation.
  public func info (override override: Level? = nil, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__, @noescape closure: LogClosure) {
    logInternal(closure: closure, category: nil, override: override, level: .Info, function: function, file: file, line: line)
  }

  /// See the `severe` functions for documentation.
  public func info (category: T?, override: Level? = nil, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__, @noescape closure: LogClosure) {
    logInternal(closure: closure, category: category, override: override, level: .Info, function: function, file: file, line: line)
  }

  // MARK: Debug
  /// See the `severe` functions for documentation.
  public func debug (@autoclosure  closure: LogClosure, override: Level? = nil, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__) {
    logInternal(closure: closure, category: nil, override: override, level: .Debug, function: function, file: file, line: line)
  }

  /// See the `severe` functions for documentation.
  public func debug (category: T?, @autoclosure _ closure: LogClosure, override: Level? = nil, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__) {
    logInternal(closure: closure, category: category, override: override, level: .Debug, function: function, file: file, line: line)
  }

  /// See the `severe` functions for documentation.
  public func debug (override override: Level? = nil, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__, @noescape closure: LogClosure) {
    logInternal(closure: closure, category: nil, override: override, level: .Debug, function: function, file: file, line: line)
  }

  /// See the `severe` functions for documentation.
  public func debug (category: T?, override: Level? = nil, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__, @noescape closure: LogClosure) {
    logInternal(closure: closure, category: category, override: override, level: .Debug, function: function, file: file, line: line)
  }

  // MARK: Verbose
  /// See the `severe` functions for documentation.
  public func verbose (@autoclosure  closure: LogClosure, override: Level? = nil, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__) {
    logInternal(closure: closure, category: nil, override: override, level: .Verbose, function: function, file: file, line: line)
  }

  /// See the `severe` functions for documentation.
  public func verbose (category: T?, @autoclosure _ closure: LogClosure, override: Level? = nil, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__) {
    logInternal(closure: closure, category: category, override: override, level: .Verbose, function: function, file: file, line: line)
  }

  /// See the `severe` functions for documentation.
  public func verbose (override override: Level? = nil, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__, @noescape _ closure: LogClosure) {
    logInternal(closure: closure, category: nil, override: override, level: .Verbose, function: function, file: file, line: line)
  }

  /// See the `severe` functions for documentation.
  public func verbose (category: T?, override: Level? = nil, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__, @noescape _ closure: LogClosure) {
    logInternal(closure: closure, category: category, override: override, level: .Verbose, function: function, file: file, line: line)
  }

  // MARK: None
  /// See the corresponding `severe` function for documentation. This function does not perform threshold checking or output to logs. (Its implementation is empty.)
  public func none (@autoclosure  closure: LogClosure, override: Level? = nil, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__)
  {}

  /// See the corresponding `severe` function for documentation. This function does not perform threshold checking or output to logs. (Its implementation is empty.)
  public func none (category: T?, @autoclosure _ closure: LogClosure, override: Level? = nil, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__)
  {}

  /// See the corresponding `severe` function for documentation. This function does not perform threshold checking or output to logs. (Its implementation is empty.)
  public func none (override override: Level? = nil, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__, @noescape _ closure: LogClosure)
  {}

  /// See the corresponding `severe` function for documentation. This function does not perform threshold checking or output to logs. (Its implementation is empty.)
  public func none (category: T?, override: Level? = nil, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__, @noescape _ closure: LogClosure)
  {}
}






