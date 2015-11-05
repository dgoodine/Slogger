//
//  TextFileDestination.swift
//  Slogger
//
//  Created by David Goodine on 10/28/15.
//  Copyright © 2015 David Goodine. All rights reserved.
//

import Foundation

/// A rotating and compressing local file-based destination.
public class TextFileDestination : BaseDestination {

  /// Configuration values for file destinations.
  public struct Configuration {

    /**
     A closure that is called when a file is opened and before it is closed.

     - Parameter isPreamble: If `true` the file has just been opened.  If it is `false`, it is about to be closed.
     */
    public typealias FileWrapperGenerator = (isPreamble: Bool) -> String

    /**
     A closure that is called after a file has been closed.

     - Parameter path: The path of the file just closed.
     */
    public typealias PostFileCloseHandler = (path : String) -> Void

    /**
     A closure that is called after an archiving operation has completed.

     - Parameter archive: The recently compressed archive.
     */
    public typealias PostArchiveHandler = (directory : String) -> Void

    /// Time interval in seconds for log file rotation. Defaults to 24 hours.
    public var fileRotationInterval : NSTimeInterval = 60 * 60 * 24

    /// Time interval in seconds for log directory archiving.  Defaults to 7 days.
    public var directoryArchivingInterval : NSTimeInterval = 60 * 60 * 24 * 30

    /// Generator for prepending and appending text to a file. Defaults to nil.
    public var fileWrapperGenerator : FileWrapperGenerator? = nil

    /// Handler called after closing a file. Defaults to nil.
    public var postFileCloseHandler : PostFileCloseHandler? = nil

    /// Handler called after archiving. Defaults to nil.
    public var postArchiveHandler : PostArchiveHandler? = nil


    /**
     File system attributes to use when creating the log directory and log files.

     - Warning: If you're developing for *iOS*, make sure you understand which directories are backed up to iCloud
     and either a) don't use them, or b) add the appropriate attributes so the log files aren't backed up. **If you
     don't, it's highly likely Apple will reject your binary when submitting to iTunes**.
     */
    public var fileAttributes : [String : AnyObject] = [:]

    /// Protocol property for Destination
    public var decorator : Decorator?

    /// Protocol property for Destination
    public var generator : Generator?

    /// Protocol property for Destination
    public var colorMap : ColorMap?

    /**
     Constructor for TextFileDestination configuration.

     - Parameter generator: Generator to use for this destination.  If nil, uses the logger's generator.
     - Parameter colorMap: Colormap to use for this destination. If nil, uses the logger's colorMap.
     - Parameter decorator: Decorator to use for this destination.  If nil, uses the logger's decorator.
     */
    init (generator: Generator? = nil, colorMap : ColorMap? = nil, decorator: Decorator? = nil) {
      self.generator = generator
      self.colorMap = colorMap
      self.decorator = decorator
    }
  }

  // MARK: - Public
  /// Directory path for the log files.
  public let directory : String

  /// Configuration for this destination.
  public let config : Configuration

  /**
   Designated initializer.

   - Parameter directory: Full path for the logging directory.  This will be created if necessary.  
   - Parameter config: The configuration to use for this destination.  Defaults to `Configuration()`.
   
   - SeeAlso: Configuration.fileAttributes for important information for iOS developers.
   */
  public init(directory: String, config: Configuration = Configuration()) {

    assert(false, "Not yet implemented.")

    self.directory = directory
    self.config = config
    super.init(generator: config.generator, colorMap: config.colorMap, decorator: config.decorator)
  }

  deinit {
    closeFile()
  }

  /// Protocol implementation
  public override func logString(string: String, level: Level) {
    guard let _ = outputStream else {
      return
    }

    fputs(string, _outputStream!)
    fputs("\n", _outputStream!)
  }

  // MARK: - Private

  /// Date format for log files
  private lazy var fileDateFormatter : NSDateFormatter = {
    let value = NSDateFormatter()
    value.dateFormat = "yyyy-MM-dd-HH-mm-ss-SSS-ZZZ"
    return value
  }()

  private var fileOpenDate :  NSDate? = nil
  private var _outputStream : UnsafeMutablePointer<FILE>? = nil
  private var outputStream : UnsafeMutablePointer<FILE>? {
    get {
      if let fileOpenDate = fileOpenDate
        where _outputStream != nil && NSDate().timeIntervalSinceDate(fileOpenDate) > config.fileRotationInterval {
          closeFile()
      }

      if _outputStream == nil {
        _outputStream = openFile()
      }

      return _outputStream
    }
  }

  /// Prevents error message spamming in the console.
  private var errorPrinted = false

  /// Utility function to open the logging file with the current date format
  private func openFile () -> UnsafeMutablePointer<FILE>? {
    let fm = NSFileManager.defaultManager()

    // Create the directory if it doesn't exist.
    if !fm.fileExistsAtPath(directory) {
      do {
        try fm.createDirectoryAtPath(directory, withIntermediateDirectories: true, attributes:config.fileAttributes)
      } catch {
        if !errorPrinted {
          print("*** Fatal error in Slogger.TextFileDestination: \n\(error)")
          errorPrinted = true
        }
        return nil
      }
    }

    let now = NSDate()
    let dateString = fileDateFormatter.stringFromDate(now)
    let filePath = "\(directory)/\(dateString).txt"
    guard fm.createFileAtPath(filePath, contents: NSData(), attributes: config.fileAttributes) else {
      if !errorPrinted {
        print("*** Slogger.TextFileDestination couldn't create log file.")
      }
      return nil
    }

    return fopen(filePath, "w")
  }

  /// Close the current file descriptor and check for archiving.
  private func closeFile () {
    if _outputStream != nil {
      fclose(_outputStream!)
      _outputStream = nil
      checkForArchiving()
    }
  }
  
  // Check existing log files for archiving.
  private func checkForArchiving () {
    // Not implemented.
  }
  
  
}

