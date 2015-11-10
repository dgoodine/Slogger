//
//  SloggerObjc.swift
//  Slogger
//
//  Created by David Goodine on 11/10/15.
//  Copyright © 2015 David Goodine. All rights reserved.
//

import Foundation

@objc public class SloggerObjC : NSObject {
  let log : Slogger<NoCategories>

  @objc public init (defaultLevel: Level) {
    log = Slogger<NoCategories>(defaultLevel: .Info)
  }

  // MARK: Severe
  @objc public func severe (@autoclosure  closure: LogClosure, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__) {
    log.logInternal(closure: closure, category: nil, override: nil, level: .Severe, function: function, file: file, line: line)
  }

  public func severe (category: NoCategories?, @autoclosure _ closure: LogClosure, override: Level? = nil, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__) {
    log.logInternal(closure: closure, category: category, override: override, level: .Severe, function: function, file: file, line: line)
  }

  public func severe (override: Level? = nil, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__, @noescape closure: LogClosure) {
    log.logInternal(closure: closure, category: nil, override: override, level: .Severe, function: function, file: file, line: line)
  }

  public func severe (category: NoCategories?, override: Level? = nil, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__, @noescape closure: LogClosure) {
    log.logInternal(closure: closure, category: category, override: override, level: .Severe, function: function, file: file, line: line)
  }

  // MARK: Error
  /// See the `severe` functions for documentation.
  public func error (@autoclosure  closure: LogClosure, override: Level? = nil, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__) {
    log.logInternal(closure: closure, category: nil, override: override, level: .Error, function: function, file: file, line: line)
  }

  /// See the `severe` functions for documentation.
  public func error (category: NoCategories?, @autoclosure _ closure: LogClosure, override: Level? = nil, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__) {
    log.logInternal(closure: closure, category: category, override: override, level: .Error, function: function, file: file, line: line)
  }

  /// See the `severe` functions for documentation.
  public func error (override override: Level? = nil, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__, @noescape closure: LogClosure) {
    log.logInternal(closure: closure, category: nil, override: override, level: .Error, function: function, file: file, line: line)
  }

  /// See the `severe` functions for documentation.
  public func error (category: NoCategories?, override: Level? = nil, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__, @noescape closure: LogClosure) {
    log.logInternal(closure: closure, category: category, override: override, level: .Error, function: function, file: file, line: line)
  }

  // MARK: Warning
  /// See the `severe` functions for documentation.
  public func warning (@autoclosure  closure: LogClosure, override: Level? = nil, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__) {
    log.logInternal(closure: closure, category: nil, override: override, level: .Warning, function: function, file: file, line: line)
  }

  /// See the `severe` functions for documentation.
  public func warning (category: NoCategories?, @autoclosure _ closure: LogClosure, override: Level? = nil, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__) {
    log.logInternal(closure: closure, category: category, override: override, level: .Warning, function: function, file: file, line: line)
  }

  /// See the `severe` functions for documentation.
  public func warning (override override: Level? = nil, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__, @noescape closure: LogClosure) {
    log.logInternal(closure: closure, category: nil, override: override, level: .Warning, function: function, file: file, line: line)
  }

  /// See the `severe` functions for documentation.
  public func warning (category: NoCategories?, override: Level? = nil, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__, @noescape closure: LogClosure) {
    log.logInternal(closure: closure, category: category, override: override, level: .Warning, function: function, file: file, line: line)
  }

  // MARK: Info
  /// See the `severe` functions for documentation.
  public func info (@autoclosure  closure: LogClosure, override: Level? = nil, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__) {
    log.logInternal(closure: closure, category: nil, override: override, level: .Info, function: function, file: file, line: line)
  }

  /// See the `severe` functions for documentation.
  public func info (category: NoCategories?, @autoclosure _ closure: LogClosure, override: Level? = nil, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__) {
    log.logInternal(closure: closure, category: category, override: override, level: .Info, function: function, file: file, line: line)
  }

  /// See the `severe` functions for documentation.
  public func info (override override: Level? = nil, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__, @noescape closure: LogClosure) {
    log.logInternal(closure: closure, category: nil, override: override, level: .Info, function: function, file: file, line: line)
  }

  /// See the `severe` functions for documentation.
  public func info (category: NoCategories?, override: Level? = nil, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__, @noescape closure: LogClosure) {
    log.logInternal(closure: closure, category: category, override: override, level: .Info, function: function, file: file, line: line)
  }

  // MARK: Debug
  /// See the `severe` functions for documentation.
  public func debug (@autoclosure  closure: LogClosure, override: Level? = nil, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__) {
    log.logInternal(closure: closure, category: nil, override: override, level: .Debug, function: function, file: file, line: line)
  }

  /// See the `severe` functions for documentation.
  public func debug (category: NoCategories?, @autoclosure _ closure: LogClosure, override: Level? = nil, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__) {
    log.logInternal(closure: closure, category: category, override: override, level: .Debug, function: function, file: file, line: line)
  }

  /// See the `severe` functions for documentation.
  public func debug (override override: Level? = nil, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__, @noescape closure: LogClosure) {
    log.logInternal(closure: closure, category: nil, override: override, level: .Debug, function: function, file: file, line: line)
  }

  /// See the `severe` functions for documentation.
  public func debug (category: NoCategories?, override: Level? = nil, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__, @noescape closure: LogClosure) {
    log.logInternal(closure: closure, category: category, override: override, level: .Debug, function: function, file: file, line: line)
  }

  // MARK: Verbose
  /// See the `severe` functions for documentation.
  public func verbose (@autoclosure  closure: LogClosure, override: Level? = nil, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__) {
    log.logInternal(closure: closure, category: nil, override: override, level: .Verbose, function: function, file: file, line: line)
  }

  /// See the `severe` functions for documentation.
  public func verbose (category: NoCategories?, @autoclosure _ closure: LogClosure, override: Level? = nil, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__) {
    log.logInternal(closure: closure, category: category, override: override, level: .Verbose, function: function, file: file, line: line)
  }

  /// See the `severe` functions for documentation.
  public func verbose (override override: Level? = nil, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__, @noescape _ closure: LogClosure) {
    log.logInternal(closure: closure, category: nil, override: override, level: .Verbose, function: function, file: file, line: line)
  }

  /// See the `severe` functions for documentation.
  public func verbose (category: NoCategories?, override: Level? = nil, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__, @noescape _ closure: LogClosure) {
    log.logInternal(closure: closure, category: category, override: override, level: .Verbose, function: function, file: file, line: line)
  }

  // MARK: None
  /// See the corresponding `severe` function for documentation. This function does not perform threshold checking or output to logs. (Its implementation is empty.)
  public func none (@autoclosure  closure: LogClosure, override: Level? = nil, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__)
  {}

  /// See the corresponding `severe` function for documentation. This function does not perform threshold checking or output to logs. (Its implementation is empty.)
  public func none (category: NoCategories?, @autoclosure _ closure: LogClosure, override: Level? = nil, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__)
  {}

  /// See the corresponding `severe` function for documentation. This function does not perform threshold checking or output to logs. (Its implementation is empty.)
  public func none (override override: Level? = nil, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__, @noescape _ closure: LogClosure)
  {}

  /// See the corresponding `severe` function for documentation. This function does not perform threshold checking or output to logs. (Its implementation is empty.)
  public func none (category: NoCategories?, override: Level? = nil, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__, @noescape _ closure: LogClosure)
  {}

}