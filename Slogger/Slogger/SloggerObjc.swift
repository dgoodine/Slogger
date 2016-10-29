//
//  SloggerObjc.swift
//  Slogger
//
//  Created by David Goodine on 11/10/15.
//  Copyright © 2015 David Goodine. All rights reserved.
//

import Foundation

@objc open class SloggerObjC: NSObject {
  fileprivate let logger: Slogger<NoCategories>

  public init (defaultLevel: Level) {
    logger = Slogger<NoCategories>(defaultLevel: .info)
  }

  open func log (_ level: Level, closure: @autoclosure () -> String, function: String = #function, file: String = #file, line: Int = #line) {
    logger.logInternal(closure: closure, category: nil, override: nil, level: level, function: function, file: file, line: line)
  }
}
