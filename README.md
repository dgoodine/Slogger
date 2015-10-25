# Slogger
A simple, fast and highly-customizable logging framework for Swift on all Apple platforms.

## Version History

Version | Status | Comments
--- | --- | ---
1.0 | In Progress | Finishing up for initial release


## Why another Swift logger?

When I started doing serious Swift development, I naturally looked around for a logging framework.  I found Dave Wood excellent *XCGLogger* (https://github.com/DaveWoodCom/XCGLogger) implementation.  While it's fast and well constructed, I needed some extra features and decided to build my own.

*Slogger* uses much the same approach and function signatures as *XCGLogger*, and as such, in its basic use can be easily switched with *XCGLogger* without modifying the logging sites.

## General Info

The logger levels supported are as follows:

	public enum Level : Int, Comparable {
	  case None, Severe, Error, Warning, Info, Debug, Verbose, Trace

	  static func allValues () -> [Level] {
	    return [None, Severe, Error, Warning, Info, Debug, Verbose, Trace]
	  }
	}

*Trace* is a special logging level with different semantics explained below.

Each log level has both an @autoclosure and @noescape trailing closure implementation, so the following are both valid forms:

	log.debug("Enter")
	log.debug() {
		return "Enter"
	}

By necessity, the function parameters include defaulted parameters to capture the source code information at the logging site.

Setting up a simple, default logger can be as simple as one line of code:

	let log = Slogger<NoCategories>(defaultLevel: .Debug)
	
And you'll likely want to tailor your build for debug/release:

	#if DEBUG
	let log = Slogger<NoCategories>(defaultLevel: .Info)
	#else
	let log = Slogger<NoCategories>(defaultLevel: .Warning)
	#endif

The *Slogger* class is generic, to support categories as explained below.

## Advanced Features

### Destinations
The *Destination* protocol allows you to write your own log destinations and add them to the logger.  This would enable you to add a destination to log over the network if you wanted to.

*Slogger* natively supports the following logging destinations:

Destination | Status
--- | ---
Console | Implemented
File | Coming Soon™


### Generators
You can supply your own closure for outputting a log entry in any format.  The default uses the ubiquitous log4j pattern

	- [10/25/2015, 15:33:57 EDT] SloggerTests.swift:117 callIt [] Severe: Message...
	
But you could easily output custom JSON, XML, or whatever you want.  These generators are configurable per logging destination.

### Details
You can configure what details you want to see in the logs by providing an array of enum values for each detail supported.  Generators will 


### Configurable Decorators
You can supply a decorator that will further adjust the format of the generator output.  These are configured on a per-destination.

Decorators | Status
--- | ---
XCodeColors | Implemented
ANSI | Coming Soon™

### Configurable Colormaps
Make your own color map for mapping *Level* to color in a platform- and decorator-independent way.

## Categories














## Tracing









