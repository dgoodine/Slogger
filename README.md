# Slogger
A simple, fast and flexible logging framework for Swift.

[![Pod Platform](http://img.shields.io/cocoapods/p/Slogger.svg?style=flat)](http://cocoadocs.org/docsets/Slogger/)
[![Pod License](http://img.shields.io/cocoapods/l/Slogger.svg?style=flat)](http://opensource.org/licenses/MIT)
[![Pod Version](http://img.shields.io/cocoapods/v/Slogger.svg?style=flat)](http://cocoadocs.org/docsets/Slogger/)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/dgoodine/Slogger)

## Why Another Swift Logging Framework?

When I started doing serious Swift development, I naturally looked around for a logging framework.  I found [*XCGLogger*](https://github.com/DaveWoodCom/XCGLogger) by Dave Wood @DaveWoodCom.  While it's fast and well constructed, I needed some extra features and decided to build my own.  But I did learn a few things from him so he deserves some props. 🍺🍺🍺

*Slogger* uses much the same approach and identical function signatures as *XCGLogger*, so they are interchangeable without modifying existing logging sites. Be sure to check the **Advanced Features** section below – particularly *Radioactive Logging* and *Categories* – to see why I decided to go this route.

Also note: Slogger is completely API independent, except for the Swift standard library and the `Foundation` import.  So it can be used in Mac OS X projects projects as well.

**Slogger requires Xcode 7.1 and Swift 2.1.**

## General Info

### Logging Levels
The typical logger levels are supported:

	public enum Level : Int, Comparable {
	  case None, Severe, Error, Warning, Info, Debug, Verbose

	  static let allValues = [None, Severe, Error, Warning, Info, Debug, Verbose]
	}
	
The order of the levels is higher-priority first. Thus the threshold is evaluated using the *<=* operator. Here's the function that's used internally to determine if a message should be logged.  (See below for information on the *override* and *category* parameters.)

	public func canLog (override override: Level?, category: T?, siteLevel: Level) -> Bool {
	  let effectiveLevel : Level
	  if override != nil {
	    effectiveLevel = override!
	  } else if category != nil, let categoryLevel = categories[category!] {
	    effectiveLevel = categoryLevel
	  } else {
	    effectiveLevel = level
	  }

	  return effectiveLevel == .None ? false : siteLevel <= effectiveLevel
	}
  
### Creating a *Slogger* Instance
Setting up a logger can be as simple as one line of code:

	let log = Slogger<NoCategories>(defaultLevel: .Info)
	
And you'll likely want to tailor your build for debug/release:

	#if DEBUG
	let log = Slogger<NoCategories>(defaultLevel: .Info)
	#else
	let log = Slogger<NoCategories>(defaultLevel: .Warning)
	#endif 

The public interface is fully documented in the headers for reference in *Xcode* (use Alt-Click).  See the Docs directory for an HTML-based version.  (At some point there will be a docset available, but at the moment there are issues with both Jazzy and AppleDoc that I haven't had time to resolve.)

The *Slogger* class is generic to support categories, as explained below.

### Logging Site Functions
Each log level has *autoclosure* and *noescape* trailing closure implementations, so the following are both valid forms:

	log.debug("Enter")
	log.debug() { "Enter" }
	
**Important Note**: The resulting closures **are not evaluated if the logging site doesn't pass the level threshold**.  So don't worry about expensive computations inside them.  And don't rely on them for side-effects.

For completeness, functions are provided for the .None level that have no-op implementations.  Thus the only overhead would be allocating the closure on the stack and the function call.  You can use them to effectively disable certain logging sites with the highest efficiency.  (*See the Performance sections below for more details.*)

	log.none("Enter")
	log.none() { "Enter" }
	
### Log Instance Properties
The following properties of each log instance are exposed and have read/write access (except for default implementations).  They can be modified at runtime, either programmatically or by using the debugger at a breakpoint.

Property | Type | Comments
--- | --- | ---
level | Level | The active, global level of the logger instance.
categories | [T : Level] | A mapping between categories and levels.
destinations | [Destination] | Destinations this logger will write to.  Defaults to `ConsoleDestination` with *XcodeColors* decorator.
hits | UInt64 | Number of events logged.
misses | UInt64 | Number of events not logged due to logging threshold evaluation.

## Implementation Note

*Slogger* uses a private, serial dispatch queue for most of its work, including calls to the 
generator, decorator, and all logging destinations.  The only code executed synchronously by the
logging functions is threshold evaluation (and only if `destinations.count > 0`) and,
if that passes, evaulation of the closure to produce the message from the logging site.

Thus, all *Slogger* types are inherently thread-safe. If you decide to implement your own, you can
do so without concern for concurrency issues. However, if you create a custom implementation
of any type that requires code be executed on the main thread, you **MUST** wrap that code inside a
`dispatch_async` call to the main queue.

## Advanced Features

### Destinations
The *Destination* class allows you to write your own log destination subclasses and add them to the logger. The following destinations are provided in the implementation:

Class | Status | Notes
--- | --- | ---
ConsoleDestination | ✔️ | Defaults to sensible output with *XcodeColors* support
MemoryDestination | ✔️ | Appends entries to in-memory array.
TextFileDestination | ✔️ | Mimics ConsoleDestination behavior by default w/o decoration
JSONFileDestination | ✔️ | Outputs one-entry-per-line JSON format
XMLFileDestination | ✔️ | Outputs one-entry-per-line XML format
TabFileDestination | ✔️ | Outputs tab-delimited files.
CSVFileDestination | ✔️ | Outputs comma-separated values files.
NetworkDestination | 🤔  | Planned but no ETA

### Generators
These are classes that output a log entry based on information from the logging site. They are configurable per logging destination.  You can use the provided generators or implement your own.

The default uses the typical pattern:

	- [2015-11-07 23:53:18.187 -0500] File.swift (82) function() [] Error : Message...
	
List of supported generators (see the source for details):

Generator | Status
--- | ---
Generator | ✔️
JSONGenerator | ✔️
XMLGenerator | ✔️
CSVGenerator | ✔️
TSVGenerator | ✔️


### Details
You can configure what details you want to see in the logs – and in what order – by providing an array of enum values for each detail supported.  This makes it easy to customize your output format.

The default value includes all available *Detail* values, in a typical order:

	[.Override, .Date, .File, .Line, .Function, .Category, .Level, .Message]
	
### Configurable Decorators
You can supply a decorator that will further adjust the format of the generator output.  These are configured per destination.

Decorators | Status | Info
--- | --- | ---
XcodeColors | Supported | Get [*XcodeColors*](https://github.com/robbiehanson/XcodeColors).
ANSI | On Hold | Currently trying to sort out supporting this.

### Configurable Colormaps
Make your own color map to customize log entry color by *Level* in a platform- and decorator-independent
way.  See the *ColorMap* type for more information.  (Note: You can use the *XcodeColorsDecorator*
class for non-log use in your console without writing your own.)

### Radioactive Logging
Radioactive logging allows logging to execute based on evaluation of an optional *override* value at logging sites.  If the *override* value is non-nil, it is evaluated first. If the level of the logging function is less than or equal to the *override* value, the site will be logged.  If not, logging threshold evaluation will proceed by the normal process.

As an example, imagine you have a *Request* object base class in a services implementation.  You could define a *logOverride* property of type *Level*, defaulting to *nil*. In the service code that processes requests, you would then provide the value of the *logOverride* property of requests as the *override* parameter at all logging sites.  This would cause any non-nil value in requests being processed to be used to override logging for the service.

As a use-case, if you had a service that was processing tons of request, but a specific one was failing in a subtle way, you could use the following procedure to get more information for just that request, as follows:

1. Add code to set a *logOverride* value (typically .Verbose) where the request is created
1. Set the *activeLevel* property in the log instance to *.None*
1. Run your code

You would then see logging for *only* that specific request, at whatever level you specified as the override.  This allows you to focus diagnosis on a particular object as it flows through the system, rather than getting a firehose of logging information for requests that you don't care about if you were to simply set the logger's *level* property to a higher value.

This procedure can be done by simply modifying your code at the site of creation of the request, or it can be done by setting a breakpoint at runtime and using the debugger to modify the properties.

### Categories
In addition to the two logging site functions for each level mentioned above, *Slogger* adds two more with an additional *Category* parameter.  While a category could be any type conforming to the protocol, it's best to define them as an *enum* for type safety and convenience.

Once the categories are defined, you can configure your logger to customize the logging level for that category (.Debug or .Verbose, for example), even at runtime.  This allows more fine-tuning of logging if, for example, you want to see more logging of the events for a particular concern (database calls, networking transactions, etc).

The design of *Slogger* also allows third-party frameworks that use it to expose their log instance and document their category values for developers using them.  If you need to diagnose a problem inside the framework, you can simply adjust the logging levels for particular categories – or make objects radioactive if the framework supports it – to get more information.  This is particularly useful in cases where the framework developer doesn't release the source code.

## Implementing Categories

Here's an example of how you should implement your custom categories and your *Slogger* subclass.

First, define your category enum:

	public enum MyCategories : String, SloggerCategory {
	  case Foo, Bar, Baz
	  }
	}

Second, subclass the generic *Slogger* class to bind it to your category type:

	class MyLogger : Slogger<MyCategories> {}
	
Then create your logger in the obvious way:

	public let log = MyLogger(defaultLevel: .Info)
	
Naturally, if you want your logger to have customized values (generators, decorators, etc.), you can override the *init* method and provide that information there.

Creating your logger as a top-level, global variable gives you convenient access to it anywhere in your code.  And since your *Swift* code defines a module, you a) don't have to worry about name collisions, and b) can document your categories and allow other modules to modify its behavior, as described above.

## Performance
Here are initial performance figures for logging calls with a release build (as of version 1.0).  See the *PerformanceTest* class and *SloggerPerformanceIOS* project for details.  (The performance of *Slogger* for Mac OS X applications should be identical to that of the simulator.)

Destinations | Level | Can Log | Simulator | iPhone 6 
--- | --- | --- | --- | ---
[]                   | Verbose | true  | 53ns  | 108ns
[MemoryDestination]  | Severe  | false | 374ns | 1µs
[ConsoleDestination] | Severe  | false | 370ns | 1µs
[JSONFileDestination] | Severe | false | 463ns | 1µs
[XMLFileDestination] | Severe | false | 425ns | 1µs
[MemoryDestination]  | Verbose | true  | 3µs   | 8µs
[ConsoleDestination] | Verbose | true  | 4µs   | 15µs
[JSONFileDestination] | Verbose | true | 4µs | 10µs
[XMLFileDestination] | Verbose | true | 12µs | 16µs

It's clear from the timing that if you want to completely turn off logging in the most efficient way, set the *destinations* property to an empty array.  This avoids even performing the level threshold test.

It should be noted that the timing for where *Can Log* is *true* does not include the generator, decoration or destination overhead.  If a site can log, the only thing done inline is evaluating the message closure (required because it's noescape).  The rest of the work is done via `dispatch_async` to a private, serial queue.

## Feedback
Please do use the issues section on Github report bugs, raise questions, offer suggestions for improvements or ask questions about the implementation.  And if you want to contribute, feel free to discuss it in the issues section and/or issue a pull request.

***Happy logging!***

## Version History

Version | Status | Comments
--- | --- | ---
2.0 | Released | Update for Swift 2.2.  Minor fixes.
1.0 | Released | First release.
0.1.x | Available | **Pre-release** (CocoaPods/Carthage support and TextFileDestination variants).

## TODO
- Make docset
