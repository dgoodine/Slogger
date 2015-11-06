//
//  main.swift
//  SloggerConsole
//
//  Created by David Goodine on 11/6/15.
//  Copyright © 2015 David Goodine. All rights reserved.
//

import Foundation
import SloggerOSX

var log = Slogger<NoCategories>(defaultLevel: .Verbose)

let consoleDestination = ConsoleDestination()
consoleDestination.decorator = AnsiDecorator()
consoleDestination.colorMap = [
  .None : (colorFromHexString("02A8A8"), nil),
  .Severe : (colorFromHexString("FF0000"), nil),
  .Error : (colorFromHexString("FF5500"), nil),
  .Warning : (colorFromHexString("FF03FB"), nil),
  .Info : (colorFromHexString("008C31"), nil),
  .Debug : (colorFromHexString("035FFF"), nil),
  .Verbose : (colorFromHexString("555555"), nil),
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
      let joined = arglist.joinWithSeparator(" ")

      switch self {
        
      case None:
        log.none(joined)
      case Severe:
        log.severe(joined)
      case Error:
        log.error(joined)
      case Warning:
        log.warning(joined)
      case Info:
        log.info(joined)
      case Debug:
        log.debug(joined)
      case Verbose:
        log.verbose(joined)

      case Exit, Quit:
        exit(0)
      }
    }
  }

  @noreturn func enter () {
    while (true) {
      let ws = NSCharacterSet.whitespaceCharacterSet()
      print("> ", terminator:"")
      if let line = readLine() {
        let string = line.stringByTrimmingCharactersInSet(ws)
        var array = string.componentsSeparatedByCharactersInSet(ws).filter() { !$0.isEmpty }
        if array.count > 0 {
          let command = Command(rawValue:array.first!.capitalizedString)
          if command != nil {

            array.removeFirst()
            command?.execute(array)
            sleep(1)
          }
        }
      }
    }
  }
}

let console = Console()
console.enter()
