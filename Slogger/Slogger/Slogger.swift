//
//  Slogger.swift
//  Slogger
//
//  Created by David Goodine on 10/20/15.
//  Copyright © 2015 David Goodine. All rights reserved.
//

import Foundation

typealias LogClosure = () -> String

// Marker protocol for client-provided logging category enums
public protocol Category : Hashable {}

public enum Level : Int, Comparable {
  case None = 0, Error, Warning, Info, Verbose
}

public func <<T: RawRepresentable where T.RawValue: Comparable>(a: T, b: T) -> Bool {
  return a.rawValue < b.rawValue
}

public enum Detail : Int {
  case Date = 0, Time, File, Function
}

public class Slogger <T: Category> : NSObject {

  public var currentLevel : Level
  public var dateFormatter : NSDateFormatter
  public var details : [Detail]?
  public var categories : [T : Level] = Dictionary<T, Level>()

  // MARK: Initialization
  public init (defaultLevel : Level, dateFormatter : NSDateFormatter?, details : [Detail]?) {
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
    self.dateFormatter = dateFormatter!
    self.details = details
  }

  // MARK: Public
  public func error (category: T?, string : String) {
    logInternal(category, level: .Error, string: string)
  }

  public func error (category: T?, @autoclosure closure: () -> String?) {
    logInternal(category, level: .Error, closure: closure)
  }

  public func warning (category: T?, string : String) {
    logInternal(category, level: .Warning, string: string)
  }

  public func warning (category: T?, @autoclosure closure: () -> String?) {
    logInternal(category, level: .Warning, closure: closure)
  }

  public func info (category: T?, string : String) {
    logInternal(category, level: .Info, string: string)
  }

  public func info (category: T?, @autoclosure closure: () -> String?) {
    logInternal(category, level: .Info, closure: closure)
  }

  public func verbose (category: T?, string : String) {
    logInternal(category, level: .Verbose, string: string)
  }

  public func verbose (category: T?, @autoclosure closure: () -> String?) {
    logInternal(category, level: .Verbose, closure: closure)
  }


  // MARK: Private
  private func canLog (category: T?, level: Level) -> Bool {
    var operatingLevel = currentLevel
    if category != nil, let categoryLevel = categories[category!] {
      operatingLevel = categoryLevel
    }

    return level >= operatingLevel
  }

  private func logInternal (category: T?, level: Level, string : String) {
    print("[\(category)] (\(level)): \(string)")
  }

  private func logInternal (category: T?, level: Level, @autoclosure closure: () -> String?) {
    guard canLog(category, level: level) else {
      return;
    }

    if let string = closure() {
      logInternal(category, level: level, string: string)
    }
  }
}