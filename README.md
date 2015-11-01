# Slogger
A simple, fast and flexible logging framework for Swift on all Apple platforms.

## Version History

Version | Status | Comments
--- | --- | ---
1.0 | In Progress | Finishing up for initial release

## TODO
- Finish FileDestination (*currently not supported*)
- Add *Carthage* support.
- Make docset

## Why Another Swift Logging Framework?

When I started doing serious Swift development, I naturally looked around for a logging framework.  I found [*XCGLogger*](https://github.com/DaveWoodCom/XCGLogger) by Dave Wood @DaveWoodCom.  While it's fast and well constructed, I needed some extra features and decided to build my own.  But I did learn a few things from him so he deserves some props. 🍺🍺🍺

*Slogger* uses much the same approach and identical function signatures as *XCGLogger*, so they are interchangeable without modifying existing logging sites. Be sure to check the **Advanced Features** section below – particularly *Radioactive Logging* and *Categories* – to see why I decided to go this route.

## General Info

### Logging Levels
The typical logger levels are supported:

	public enum Level : Int, Comparable {
	  case None, Severe, Error, Warning, Info, Debug, Verbose

	  static let allValues = [None, Severe, Error, Warning, Info, Debug, Verbose]
	}
	
The order of the levels is higher-priority first. Thus the threshold is evaluated using the *<=* operator. Here's the function that's used internally to determine if a message should be logged.  (See below for information on the *override* and *category* parameters.)

	public func canLog (override override: Level?, category: T?, siteLevel: Level) -> Bool {
	  if override != nil {
	    return (override == .None) ? false : siteLevel <= override
	  }

	  if category != nil, let categoryLevel = categories[category!] {
	    return siteLevel <= categoryLevel
	  }

	  return siteLevel <= self.level
	}
	  
Note that the exception that specifying an *override* value of *.None* disables logging for the logging site.

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

For completeness, functions are provided for the .None level that have no-op implementations.  Thus the only overhead would be allocating the closure on the stack and the function call.

	log.none("Enter")
	log.none() { "Enter" }
	
### Log Instance Properties
The following properties of each log instance are exposed and have read/write access.  They can be modified at runtime, either programmatically or by using the debugger at a breakpoint.

Property | Type | Comments
--- | --- | ---
level | Level | The active, global level of the logger instance.
dateFormatter | NSDateFormatter | Formatter to use for dates.
details | [Detail] | Determines what to output and in what order.
categories | [T : Level] | A mapping between categories and levels (see below)
generator | Generator | Current generator.  Defaults to *defaultGenerator*.
destinations | [Destination] | Destinations this logger will write to.  Defaults to [*consoleDestination*].
colorMap | ColorMap | The current colorMap.
defaultGenerator | Generator | Default generator implementation.
consoleDestination | Destination | The default console implementation with an XCodeColors/ANSI decorator.
hits | UInt64 | Number of events logged.
misses | UInt64 | Number of events not logged due to logging threshold evaluation.

**Important Note**: *Slogger* instances are implemented to be thread-safe, as are all supported implementations of *Slogger* types and protocols.  If you provide an implementation for a protocol, it **MUST** be thread-safe as well.

## Advanced Features

### Destinations
The *Destination* protocol allows you to write your own log destinations and add them to the logger. The following destinations are provided:

Destination | Status
--- | ---
Console | Supported
Memory | Supported
File | Coming Soon™
Network | Planned but no ETA

### Generators
These are closures that output a log entry based on information from the logging site. They are configurable per logging destination.  You can use the provided generators or implement your own.

The default uses the typical pattern:

	- [2015-11-01 15:33:57.435 EDT] SloggerTests.swift:117 callIt [] Severe: Message...
	
List of supported generators (see the source for details):

Generator | Status
--- | ---
defaultGenerator | Supported
jsonGenerator | Coming Soon™
xmlGenerator | Coming Soon™
tabGenerator | Coming Soon™
csvGenerator | Coming Soon™

### Details
You can configure what details you want to see in the logs – and in what order – by providing an array of enum values for each detail supported.  This makes it easy to customize your output format.

The default value includes all available *Detail* values, in a typical order:

	[.Date, .File, .Function, .Category, .Level]
	
The inclusion of the message at the logging site is implicit.

### Configurable Decorators
You can supply a decorator that will further adjust the format of the generator output.  These are configured per destination.  Note: XCodeColors uses ANSI standard format, so you can use it to decorate your file logs too.

Decorators | Status | Info
--- | --- | ---
XCodeColors (ANSI) | Supported | Get [*XCodeColors*](https://github.com/robbiehanson/XcodeColors).

### Configurable Colormaps
Make your own color map to customize log line color by *Level* in a platform- and decorator-independent way.  See the *ColorMap* type for more information.  (Note: You can use the *XCodeColorsDecorator* class yourself for non-log use in your console without writing your own.)

### Radioactive Logging
Radioactive logging allows logging to execute based on evaluation of an optional *override* value at logging sites.  If the *override* value is non-nil, it is evaluated first. If it is less than or equal to the level of the site, the site will be logged.  If not, logging evaluation will proceed by the normal process.

As an example, imagine you have a *Request* object base class in a services implementation.  You could define a *logOverride* property of type *Level*, defaulting to *nil*. In the service code that processes requests, you would then provide the value of the *logOverride* property of requests as the *override* parameter at all logging sites.  This would cause any non-nil value in requests being processed to be used to override logging for the service.

As a use-case, if you had a service that was processing tons of request, but a specific one was failing in a subtle way, you could use the following procedure to get more information for just that request, as follows:

1. Add code to set a *logOverride* value (typically .Verbose) where the request is created
1. Set the *activeLevel* property in the log instance to *.None*
1. Run your code

You would then see logging for *only* that specific request, at whatever level you specified as the override.  This allows you to focus diagnosis on a particular object as it flows through the system, rather than getting a firehose of logging information for requests that you don't care about if you were to simply set the logger's *level* property to a higher value.

This procedure can be done by simply modifying your code at the site of creation of the request, or it can be done by setting a breakpoint at runtime and using the debugger to modify the properties.

### Categories
In addition to the two logging site functions for each level mentioned above, *Slogger* adds two more with an additional *Category* parameter.  While a category could be any type conforming to the protocol, it's best to define them an *enum* for type safety and convenience.

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

Creating your logger as a top-level, global variable gives you convenient access to it anywhere in your code.  And since your *Swift* code defines a module, you a) don't have to worry about name collisions, and b) you can document your categories and allow other modules to modify its behavior, as described above.

## Performance
Here are initial performance figures for logging calls with a release build (as of version 1.0).  See the *SloggerPerformanceIOS* project for details.  (The performance of *Slogger* for Mac OS X applications should be identical to that of the simulator.)

Device | Destinations | Level | log.Debug(.Only, "Message")
--- | --- | --- | ---
Simulator | [MemoryDestination] | .None | 363ns
Simulator | [] | .Severe | 51ns
Simulator | [MemoryDestination] | .Severe | 28µs
Simulator | [ConsoleDestination] | .Severe | 240µs
iPhone 6 | [MemoryDestination] | .None | 921ns
iPhone 6 | [] | .Severe | 943ns
iPhone 6 | [MemoryDestination] | .Severe | 65µs
iPhone 6 | [ConsoleDestination] | .Severe | 718µs

## How To Get it
Here's how you can get *Slogger* if you want to give it a try:

Means | Status | Comment
--- | --- | ---
Github | Supported | https://github.com/dgoodine/Slogger
Carthage | In process |
Cocoapods | In process | 


## Feedback
Please do use the issues section on Github report bugs, raise questions, offer suggestions for improvements or ask questions about the implementation.  And if you want to contribute, feel free to discuss it in the issues section and/or issue a pull request.

***Happy logging!***
