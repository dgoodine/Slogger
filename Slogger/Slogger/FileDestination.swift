//
//  FileDestination.swift
//  Slogger
//
//  Created by David Goodine on 10/28/15.
//  Copyright © 2015 David Goodine. All rights reserved.
//

import Foundation

/// A rotating and compressing local file-based destination.
public class FileDestination : BaseDestination {

  // MARK: - Public

  /// Time interval in seconds for log file rotation
  private var fileRotationInterval : Float = 60 * 60 * 24

  /// Time interval in seconds for log direction archiving
  public var directoryArchivingInterval : Float = 60 * 60 * 24 * 30

  /// Directory path for the log files.
  public let directory : String

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

  /// Protocol implementation
  public override func logString(string: String, level: Level) {
    guard outputStream != nil else {
      return
    }
  }

  // MARK: - Private
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

  private lazy var outputStream : NSOutputStream? = nil // self.openFile()

  /// A buffer used to log entries while directory archiving is taking place.
  private var buffer : [String] = []


  /// Utility function to open the logging file with the current date format
  private var errorPrinted = false
  private func openFile () -> NSOutputStream? {
    let fileManager = NSFileManager.defaultManager()
    let now = NSDate()
    let dateString = directoryDateFormatter.stringFromDate(now)
    let directoryPath = "\(directory)/\(dateString)"
    let attributes : [String : AnyObject] = Dictionary<String, AnyObject>()

    do {
      try fileManager.createDirectoryAtPath(directoryPath, withIntermediateDirectories: true, attributes:attributes)
    } catch {
      if (!errorPrinted) {
        print("Fatal error in Slogger: \(error)")
        errorPrinted = true
      }

      return nil
    }

    // let value = NSOutputStream(toFileAtPath: path, append: true)

    return nil
  }

  private func closeFile (reopen : Bool = true) {
    guard outputStream != nil else {
      return
    }

    outputStream!.close()
    outputStream = (reopen) ? openFile() : nil
  }
}

