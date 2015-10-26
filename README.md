# Slogger
A simple, fast and highly-customizable logging framework for Swift on all Apple platforms.

## Version History

Version | Status | Comments
--- | --- | ---
1.0 | In Progress | Finishing up for initial release


## Why Another Swift logger?

When I started doing serious Swift development, I naturally looked around for a logging framework.  I found Dave Wood's excellent *XCGLogger* (https://github.com/DaveWoodCom/XCGLogger) implementation.  While it's fast and well constructed, I needed some extra features and decided to build my own.

*Slogger* uses much the same approach and function signatures as *XCGLogger*, and as such, in its basic use can be easily switched with *XCGLogger* without modifying the logging sites.

## How To Get it
Here are the ways you can get and use slogger:

Means | Status | Comment
--- | --- | ---
Github | Supported | https://github.com/dgoodine/Slogger
Carthage | In process |
Cocoapods | Considering it | Not a fan of invasive development tools, but it's popular

## General Info

The logger levels supported are as follows:

	public enum Level : Int, Comparable {
	  case None, Severe, Error, Warning, Info, Debug, Verbose

	  static func allValues () -> [Level] {
	    return [None, Severe, Error, Warning, Info, Debug, Verbose]
	  }
	}

Each log level has both an @autoclosure and @noescape trailing closure implementation, so the following are both valid forms:

	log.debug("Enter")
	log.debug() {
		return "Enter"
	}

By necessity, the function parameters include defaulted parameters to capture the source code information at the logging site.

Setting up a logger can be as simple as one line of code:

	let log = Slogger<NoCategories>(defaultLevel: .Debug)
	
And you'll likely want to tailor your build for debug/release:

	#if DEBUG
	let log = Slogger<NoCategories>(defaultLevel: .Info)
	#else
	let log = Slogger<NoCategories>(defaultLevel: .Warning)
	#endif

The *Slogger* class is generic, to support categories.  This is explained below.

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

	- [10/25/2015, 15:33:57.435 EDT] SloggerTests.swift:117 callIt [] Severe: Message...
	
But you could easily output custom JSON, XML, or whatever you want.  These generators are configurable per logging destination.

### Details
You can configure what details you want to see in the logs by providing an array of enum values for each detail supported.  This makes it easy to customize your output format.

### Configurable Decorators
You can supply a decorator that will further adjust the format of the generator output.  These are configured on a per-destination.

Decorators | Status
--- | ---
XCodeColors | Implemented
ANSI | Coming Soon™

### Configurable Colormaps
Make your own color map for mapping *Level* to color in a platform- and decorator-independent way.

### Radioactive Tracing
Radioactive tracing allows logging sites to log based on a boolean override value, not the logging level.  If the *override* argument in a logging site is true, the event is logged, regardless of the log level.

For example, if you were to define a *Request* object base class in a services implementation, you could define a boolean *trace* property, defaulting to false.  In your code that processes the request, you would provide the *condition* argument to the logging site.  If a particular request is causing a problem (but you have tons of them to process), you can set the *trace* flag for only that request and logging sites for all levels would be logged.

### Categories
In addition to the two convenience functions for each level mentioned above, logging sites allow a *Category* to be defined which is passed to the logging function.  While a category could be any type conforming to the *Hashable* protocol, you would typically define an *enum* for type safety.

Once the categories are defined, you can configure your logger to customize the logging level for that category (.Debug or .Verbose, for example), even at runtime.  This allows more fine-tuning of logging if, for example, you want to see more logging of the events for a particular concern (database calls, networking transactions, etc.

The design of categories is such that third-party frameworks can expose their *Slogger* object and document their category values for developers using the framework.  Then, if the developers need to diagnose a problem inside the framework, they can simple fine-tune the logging levels to get more information.  This is especially useful the framework developer doesn't release the source code.

## Implementing Categories

Here's an example of how you should implement your custom categories, taken from the unit test code in *Slogger*.

First, define your category enum:

	enum TestCategory : String, SloggerCategory {
	  case First, Second, Third

	  static func allValues () -> [TestCategory] {
	    return [First, Second, Third]
	  }
	}

Then, you need to subclass *Slogger*, which is generic, to bind the type to your category type:

	class TestLogger : Slogger<TestCategory> {}
	
Then create your logger in the obvious way:

	public let log = TestLogger()
	
Naturally, if you want your logger to have customize values (generators, decorators, etc.), you can override the *init* method and provide that information there.

Remember, *Slogger* is designed so that all public public properties for a *Slogger* instance can be modified at runtime, without having to worry about state.





