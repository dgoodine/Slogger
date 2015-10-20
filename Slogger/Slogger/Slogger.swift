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
public protocol Category : StringLiteralConvertible {}

public enum Categories : Category {
  case General
}

public enum Level : Int {
  case None = 0, Error, Warning, Info, Verbose
}

public enum Detail : Int {
  case Date = 0, Time, File, Function
}

public class Slogger : NSObject {

  public var defaultLevel : Level
  public var defaultCategory : Category = Categories.General
  public var dateFormatter : NSDateFormatter
  public var details : [Detail]?
  public var categories : [Category : Level]

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

    self.defaultLevel = defaultLevel
    self.dateFormatter = dateFormatter!
    self.details = details
  }

  // MARK: Private
  private func canLog (category: Category?, level: Level) -> Bool {
    if let category = category {

    }
  }

  private func logInternal (string : String) {

  }

  private func logInternal (category: Category?, level: Level, string : String) {

  }

  private func logInternal (category: Category?, level: Level, @autoclosure closure: () -> String?) {

  }
}