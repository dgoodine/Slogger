//
//  main.swift
//  SloggerConsole
//
//  Created by David Goodine on 11/6/15.
//  Copyright © 2015 David Goodine. All rights reserved.
//

import Foundation
import SloggerOSX

var log = Slogger<NoCategories>(defaultLevel: .verbose)

let consoleDestination = ConsoleDestination()
consoleDestination.decorator = AnsiDecorator()
consoleDestination.colorMap = [
  .off : (colorFromHexString("02A8A8"), nil),
  .severe : (colorFromHexString("FF0000"), nil),
  .error : (colorFromHexString("FF5500"), nil),
  .warning : (colorFromHexString("FF03FB"), nil),
  .info : (colorFromHexString("008C31"), nil),
  .debug : (colorFromHexString("035FFF"), nil),
  .verbose : (colorFromHexString("555555"), nil),
]

log.destinations = [consoleDestination]

class Console {

  enum Destination {
    case File, Console
  }

  enum Command : String {
    case None, Severe, Error, Warning, Info, Debug, Verbose
    case Exit, Quit

    func execute(arglist : [String]) {
      let joined = arglist.joined(separator: " ")

      switch self {
        
      case .None:
        log.none(joined)
      case .Severe:
        log.severe(joined)
      case .Error:
        log.error(joined)
      case .Warning:
        log.warning(joined)
      case .Info:
        log.info(joined)
      case .Debug:
        log.debug(joined)
      case .Verbose:
        log.verbose(joined)

      case .Exit, .Quit:
        exit(0)
      }
    }
  }

  func enter () -> Never  {
    while (true) {
      let ws = NSCharacterSet.whitespaces
      print("> ", terminator:"")
      if let line = readLine() {
        let string = line.trimmingCharacters(in: ws)
				var array: [String] = string.components(separatedBy: ws).filter() { !$0.isEmpty }
				guard array.count > 0 else { continue }
				let first = array.first!.capitalized
				guard let command = Command(rawValue:first) else { continue }
				array.removeFirst()
				command.execute(arglist: array)
				sleep(1)
      }
    }
  }
}

let console = Console()
console.enter()
