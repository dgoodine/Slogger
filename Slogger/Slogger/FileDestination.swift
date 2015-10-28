//
//  FileDestination.swift
//  Slogger
//
//  Created by David Goodine on 10/28/15.
//  Copyright © 2015 David Goodine. All rights reserved.
//

import Foundation

public class FileDestination : BaseDestination {

  /// Time interval in seconds for log file rotation
  private var fileRotationInterval : Float = 60 * 60 * 24

  /// Time interval in seconds for log direction archiving
  public var directoryArchivingInterval : Float = 60 * 60 * 24 * 30

  /// Directory path for the log files.
  public let directory : String

  /// Date format for log files
  private lazy var fileDateFormatter : NSDateFormatter = {
    let value = NSDateFormatter()
    value.dateFormat = "HH-mm-ss-SSS"
    return value
  }()

  /// Date format for log files
  private lazy var directoryDateFormatter : NSDateFormatter = {
    let value = NSDateFormatter()
    value.dateFormat = "yyyy-MM-dd"
    return value
  }()

  /// A buffer used to log entries while directory archiving is taking place.
  private var buffer : [String] = []

  /**
   Designated initializer.
   
   - Parameter directory: Full directory path for log files
   - Parameter fileRotataionInterval: Interval in seconds for rotating log files (defaults to 24 hours)
   - Parameter generator: Generator to use for this destination.  If nil, uses the logger's generator.
   - Parameter colorMap: Colormap to use for this destination. If nil, uses the logger's colorMap.
   - Parameter decorator: Decorator to use for this destination.  If nil, uses the logger's decorator.
   */
  public init(directory: String, generator: Generator? = nil, colorMap: ColorMap? = nil, decorator: Decorator? = nil) {
    self.directory = directory
    super.init(generator: generator, colorMap: colorMap, decorator: decorator)
  }

  /**
   Protocol implementation – Writes the log entry to the current log file.

   - Parameter string: The line to be logged.
   - Parameter level: The level provided at the logging site.
   */
  public override func logString(string: String, level: Level) {

  }

  /// Utility function to open the logging file with the current date format
  private func openFile () {

  }
}

