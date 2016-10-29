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
public protocol SloggerCategory: Hashable {}

/// Default enum for instantiating a generic Slogger class without categories.
@objc public enum NoCategories: Int, SloggerCategory {
  /// If you only need one category, you can use this. Not a likely use-case.
  case one
}

/// Logging levels – Cumulatave upward (ex. .Error logs both .Error and .Severe events).
@objc public enum Level: Int, Comparable {
  /// Turn off all logging (except overrides).
  case off

  /// Use this for cataclysmic events.
  case severe

  /// Use this for things that shouldn't really happen.
  case error

  /// Use this if something seems awry.
  case warning

  /// Use this for general operational information.
  case info

  /// Use this for deeper debugging.
  case debug

  /// Use this for even more verbose debugging.
  case verbose

  /// All logging levels.
  static let allValues = [off, severe, error, warning, info, debug, verbose]
}

/// This is necessary because Swift doesn't provide it by default for Int-based enums
public func <<T: RawRepresentable>(a: T, b: T) -> Bool where T.RawValue: Comparable {
  return a.rawValue < b.rawValue
}

/// An enumeration of the types of information for a `Generator` to output.
public enum Detail: Int {
  /// Whether the event was an override
  case override

  ///  Date and time of the event.
  case date

  /// File of the logging site.
  case file

  /// File line number of the logging site
  case line

  /// The function the logging site is in.
  case function

  /// The category specified in the logging site.
  case category

  /// The logging level of the site.
  case level

  /// The message string produced at the logging site.
  case message

  /// An array of all avaliable cases in a typical order.
  static let allValues = [override, date, file, line, function, category, level, message]
}

/// Protocol for type used to decorate generator output.
public protocol Decorator {

  /**
   The decorator function.

   - Parameter string: The string to decorate.
   - Parameter colorSpec: The color spec to use for decoration.
   - Returns: The decorated string.
   */
  func decorateString(_ string: String, spec: ColorSpec) -> String
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
open class Slogger <T: SloggerCategory> : NSObject {

  /// The active, global operating level of the logger.
  open var level: Level

  /// Local storage
  fileprivate var _categories: [T : Level] = Dictionary<T, Level>()

  /// A dictionary for providing a custom `Level` for each `Category` defined.
  open var categories: [T : Level] {
    get { return _categories }
    set {_categories = newValue }
  }

  // Local Storage
  fileprivate var _destinations: [Destination] = [ConsoleDestination()]

  /// Destinations this logger will write to.
  open var destinations: [Destination] {
    get { return _destinations}
    set { _destinations = newValue }
  }

  /// Number of events logged.
  open var hits: UInt64 = 0

  /// Number of events that weren't logged due to logging threshold.
  open var misses: UInt64 = 0

  /// Used to turn off asynchronous operation for unit testing.
  var asynchronous = true

  /// Worker queue for processing logging work that has passed the level threshold test
  let workerQueue = DispatchQueue(label: "Slogger queue", attributes: [])

  // MARK: Initialization
  /**
  The default initializer.

  - Parameter defaultLevel: Sets the 'level' property to this value.
  */
  public init (defaultLevel: Level) {
    self.level = defaultLevel
  }

  // MARK: Functions
  /**
  The internal function used to determine if an event can be logged.  It's public to allow for special use-cases,
  but shouldn't be needed at logging sites since the message closure is only evaluated if this returns `true`.
  The order of the parameters designates their precedence in evaluating the logging conidition.

  - Parameter override: If it is not nil, it will be used exclusively to determine if logging should proceeed.
  If the value is .None, the generator will not be called for this logging site and there will be no output.
  - Parameter category: The category of the logging site or nil.  Used to evaluate category specific debugging
  level configuration.
  - Parameter level: The level of the logging site implicitly specified by the logging function.

  - Returns: true of the logging of the event should proceed, false if it shouldn't
  */
  open func canLog (override: Level?, category: T?, siteLevel: Level) -> Bool {
    let effectiveLevel: Level
    if override != nil {
      effectiveLevel = override!
    } else if category != nil, let categoryLevel = categories[category!] {
      effectiveLevel = categoryLevel
    } else {
      effectiveLevel = level
    }

    return effectiveLevel == .none ? false : siteLevel <= effectiveLevel
  }

  /// Resets `hits` and `misses` counters.
  open func resetStats () {
    hits = 0
    misses = 0
  }

/**
   The internal logging function, provided for extensibility.  Normally, you'll want to use the logging site functions
   provided below for clarity.

   - Parameter closure: A closure that returns the message string.
   - Parameter category: Category of the logging site.
   - Parameter override: If not nil, will be used to determine whether logging should output to the destinations.  Defaults to `nil`.
   - Parameter level: The level of the logging site.
   - Parameter function: The function within which the logging site is contained.  It should remain as the default.
   - Parameter file: The file within which the logging site is contained.  It should remain as the default.
   - Parameter line: The line in the file of the logging site.  It should remain as the default.
*/
  open func logInternal (closure: LogClosure, category: T?, override: Level?, level: Level, function: String, file: String, line: Int) {

    guard destinations.count > 0 else {
      return
    }

    guard canLog(override: override, category: category, siteLevel: level) else {
      misses = misses &+ 1
      return
    }

    let message = closure()
    let date = Date()
    let codeBlock = {
      self.hits = self.hits &+ 1

      for dest in self.destinations {
        if let string = dest.generator.generate(message: message, category: category, override: override, level: level, date: date, function: function, file: file, line: line, details: dest.details) {
          dest.logString(string, level: level)
        }
      }
    }

    if (asynchronous) {
      workerQueue.async(execute: codeBlock)
    } else {
      codeBlock()
    }
  }
}

// MARK: - Log site functions
/**
This extension holds the public convenience methods for logging per level.
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
  public func severe (_  closure: @autoclosure () -> String, override: Level? = nil, function: String = #function, file: String = #file, line: Int = #line) {
    logInternal(closure: closure, category: nil, override: override, level: .severe, function: function, file: file, line: line)
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
  public func severe (_ category: T?, _ closure: @autoclosure () -> String, override: Level? = nil, function: String = #function, file: String = #file, line: Int = #line) {
    logInternal(closure: closure, category: category, override: override, level: .severe, function: function, file: file, line: line)
  }

  /**
   Log a *severe* event.

   - Parameter override: If not nil, will be used to determine whether logging should output to the destinations.  Defaults to `nil`.
   - Parameter function: The function within which the logging site is contained.  It should remain as the default.
   - Parameter file: The file within which the logging site is contained.  It should remain as the default.
   - Parameter line: The line in the file of the logging site.  It should remain as the default.
   - Parameter closure: A closure that returns the message string.
   */
  public func severe (_ override: Level? = nil, function: String = #function, file: String = #file, line: Int = #line, closure: LogClosure) {
    logInternal(closure: closure, category: nil, override: override, level: .severe, function: function, file: file, line: line)
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
  public func severe (_ category: T?, override: Level? = nil, function: String = #function, file: String = #file, line: Int = #line, closure: LogClosure) {
    logInternal(closure: closure, category: category, override: override, level: .severe, function: function, file: file, line: line)
  }

  // MARK: Error
  /// See the `severe` functions for documentation.
  public func error (_  closure: @autoclosure () -> String, override: Level? = nil, function: String = #function, file: String = #file, line: Int = #line) {
    logInternal(closure: closure, category: nil, override: override, level: .error, function: function, file: file, line: line)
  }

  /// See the `severe` functions for documentation.
  public func error (_ category: T?, _ closure: @autoclosure () -> String, override: Level? = nil, function: String = #function, file: String = #file, line: Int = #line) {
    logInternal(closure: closure, category: category, override: override, level: .error, function: function, file: file, line: line)
  }

  /// See the `severe` functions for documentation.
  public func error (override: Level? = nil, function: String = #function, file: String = #file, line: Int = #line, closure: LogClosure) {
    logInternal(closure: closure, category: nil, override: override, level: .error, function: function, file: file, line: line)
  }

  /// See the `severe` functions for documentation.
  public func error (_ category: T?, override: Level? = nil, function: String = #function, file: String = #file, line: Int = #line, closure: LogClosure) {
    logInternal(closure: closure, category: category, override: override, level: .error, function: function, file: file, line: line)
  }

  // MARK: Warning
  /// See the `severe` functions for documentation.
  public func warning (_  closure: @autoclosure () -> String, override: Level? = nil, function: String = #function, file: String = #file, line: Int = #line) {
    logInternal(closure: closure, category: nil, override: override, level: .warning, function: function, file: file, line: line)
  }

  /// See the `severe` functions for documentation.
  public func warning (_ category: T?, _ closure: @autoclosure () -> String, override: Level? = nil, function: String = #function, file: String = #file, line: Int = #line) {
    logInternal(closure: closure, category: category, override: override, level: .warning, function: function, file: file, line: line)
  }

  /// See the `severe` functions for documentation.
  public func warning (override: Level? = nil, function: String = #function, file: String = #file, line: Int = #line, closure: LogClosure) {
    logInternal(closure: closure, category: nil, override: override, level: .warning, function: function, file: file, line: line)
  }

  /// See the `severe` functions for documentation.
  public func warning (_ category: T?, override: Level? = nil, function: String = #function, file: String = #file, line: Int = #line, closure: LogClosure) {
    logInternal(closure: closure, category: category, override: override, level: .warning, function: function, file: file, line: line)
  }

  // MARK: Info
  /// See the `severe` functions for documentation.
  public func info (_  closure: @autoclosure () -> String, override: Level? = nil, function: String = #function, file: String = #file, line: Int = #line) {
    logInternal(closure: closure, category: nil, override: override, level: .info, function: function, file: file, line: line)
  }

  /// See the `severe` functions for documentation.
  public func info (_ category: T?, _ closure: @autoclosure () -> String, override: Level? = nil, function: String = #function, file: String = #file, line: Int = #line) {
    logInternal(closure: closure, category: category, override: override, level: .info, function: function, file: file, line: line)
  }

  /// See the `severe` functions for documentation.
  public func info (override: Level? = nil, function: String = #function, file: String = #file, line: Int = #line, closure: LogClosure) {
    logInternal(closure: closure, category: nil, override: override, level: .info, function: function, file: file, line: line)
  }

  /// See the `severe` functions for documentation.
  public func info (_ category: T?, override: Level? = nil, function: String = #function, file: String = #file, line: Int = #line, closure: LogClosure) {
    logInternal(closure: closure, category: category, override: override, level: .info, function: function, file: file, line: line)
  }

  // MARK: Debug
  /// See the `severe` functions for documentation.
  public func debug (_  closure: @autoclosure () -> String, override: Level? = nil, function: String = #function, file: String = #file, line: Int = #line) {
    logInternal(closure: closure, category: nil, override: override, level: .debug, function: function, file: file, line: line)
  }

  /// See the `severe` functions for documentation.
  public func debug (_ category: T?, _ closure: @autoclosure () -> String, override: Level? = nil, function: String = #function, file: String = #file, line: Int = #line) {
    logInternal(closure: closure, category: category, override: override, level: .debug, function: function, file: file, line: line)
  }

  /// See the `severe` functions for documentation.
  public func debug (override: Level? = nil, function: String = #function, file: String = #file, line: Int = #line, closure: LogClosure) {
    logInternal(closure: closure, category: nil, override: override, level: .debug, function: function, file: file, line: line)
  }

  /// See the `severe` functions for documentation.
  public func debug (_ category: T?, override: Level? = nil, function: String = #function, file: String = #file, line: Int = #line, closure: LogClosure) {
    logInternal(closure: closure, category: category, override: override, level: .debug, function: function, file: file, line: line)
  }

  // MARK: Verbose
  /// See the `severe` functions for documentation.
  public func verbose (_  closure: @autoclosure () -> String, override: Level? = nil, function: String = #function, file: String = #file, line: Int = #line) {
    logInternal(closure: closure, category: nil, override: override, level: .verbose, function: function, file: file, line: line)
  }

  /// See the `severe` functions for documentation.
  public func verbose (_ category: T?, _ closure: @autoclosure () -> String, override: Level? = nil, function: String = #function, file: String = #file, line: Int = #line) {
    logInternal(closure: closure, category: category, override: override, level: .verbose, function: function, file: file, line: line)
  }

  /// See the `severe` functions for documentation.
  public func verbose (override: Level? = nil, function: String = #function, file: String = #file, line: Int = #line, _ closure: LogClosure) {
    logInternal(closure: closure, category: nil, override: override, level: .verbose, function: function, file: file, line: line)
  }

  /// See the `severe` functions for documentation.
  public func verbose (_ category: T?, override: Level? = nil, function: String = #function, file: String = #file, line: Int = #line, _ closure: LogClosure) {
    logInternal(closure: closure, category: category, override: override, level: .verbose, function: function, file: file, line: line)
  }

  // MARK: None
  /// See the corresponding `severe` function for documentation. This function does not perform threshold checking or output to logs. (Its implementation is empty.)
  public func none (_  closure: @autoclosure () -> String, override: Level? = nil, function: String = #function, file: String = #file, line: Int = #line) {}

  /// See the corresponding `severe` function for documentation. This function does not perform threshold checking or output to logs. (Its implementation is empty.)
  public func none (_ category: T?, _ closure: @autoclosure () -> String, override: Level? = nil, function: String = #function, file: String = #file, line: Int = #line) {}

  /// See the corresponding `severe` function for documentation. This function does not perform threshold checking or output to logs. (Its implementation is empty.)
  public func none (override: Level? = nil, function: String = #function, file: String = #file, line: Int = #line, _ closure: LogClosure) {}

  /// See the corresponding `severe` function for documentation. This function does not perform threshold checking or output to logs. (Its implementation is empty.)
  public func none (_ category: T?, override: Level? = nil, function: String = #function, file: String = #file, line: Int = #line, _ closure: LogClosure) {}
}
