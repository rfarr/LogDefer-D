## Log DeferD

Structured and deferred logging.

### Background

This module lets you defer log processing in two ways:

* defer recording of log messages until some "transaction" has completed
  * this could be an HTTP request, cron, event handler, etc

* defer rendering and processing of log messages
  * by storing logs in a structured format - you don't need to choose up front how you will render them or process them
  * structured logging allows log entries to be processed and queried much easier than a grep

By itself, this module doesn't actually do any logging.  It provides to you a hook that you implement to actually write/persist/whatever your log messages.

This logger is inspired by the Log::Defer CPAN module written by Doug Hoyte. For more information about deferred logging see https://github.com/hoytech/Log-Defer

### Basic Usage

```d
import logdefer.logger;

void someEventHandler(Foo foo, Bar bar)
{
    auto logger = DefaultLogger((string msg)
    {
        writeln(msg);
    });

    logger["RequestID"] = 123; // stored in data section

    logger.info("Processing event: ", foo);
    scope(failure) { logger.error("Error processing ", bar); };

    ... // do stuff
} // <-- logger goes out of scope and log is written
```

In this example the provided callback will log messages to standard out.  Once constructed you simply use the logger instance as you would a typical logger.  Once the logger goes out of scope it will automatically "commit" the stream of collected log messages by serializing them to a structured format and then calling your provided writer callback.

**NOTE**: Until the logger commits the messages *nothing* will actually be written.  If your program calls exit or seg faults you will not see any logs for that event!  In the future I hope to support an incremental logging feature that will allow you to write out log messages as they come in.

### Log Serialization

Currently the only built in serialization format is JSON, but you can easily provide your own serializer.  Simply implement a callable (function/delegate/opCall) that takes a LogDefer EventContext struct:

```d
import logdefer.logger;

alias MySerializer = function void (const ref EventContext eventContext);

void main()
{
    auto serializer = function void(const ref EventContext eventContext)
    {
        auto startTime = eventContext.startTime; // SysTime of event start
        auto endDuration = eventContext.endDuration; // TickDuration
        auto logs = eventContext.logs.data; // Log array of strings
        auto metadata = eventContext.metadata; // Associated data

        // format the date how you like
        // write the data how you like
    };

    auto logger = Logger!(MySerializer)(serializer);

    logger.info(...);
...
}
```

The provided JSON serializer follows the following structure:

```json
{
    "start": 1434568358.123,
    "end": 0.732,
    "data": {
        "requestID": "123"
    },
    "logs": [
        [ 0.13, 30, "log message 1" ],
        [ 0.15, 20, "log message 2" ]
    ]
}

```

### Data

The data section is useful for storing data that is associated with the 'context' of the event.  For example storing a user's IP or session cookie.  Also things like global request ids, operation status (ie whether the requested operation suceeded or failed), event data, etc.  Basically anything you can think of that you would like to be able to query by later.  The only constraint on the key/value is that they are serializable to string via to!string.

**NOTE**: The stringification of the key/value of the data is done eagerly when assigned.  Slow to!string can thus slow down the app thread.

### Timers

By default the start time and duration from when the logger is first created until it is destroyed is recorded under `start` and `end`.  If you desire finer grained timing there is also a timer facility that allows you to create your own sub-timers:

```d
auto logger = ...;

void map()
{
    auto timer = logger.timer("Mapping");

    // do stuff
    ...
} // <-- timer stops here

void reduce()
{
    auto timer = logger.timer("Reduce");

    // do stuff
    ...
} // <-- timer stops here
```

Will produce the normal log output as well as a `timers` section:

```json
{
    "start": 12345.12345,
    "end": 1.2,
    "logs": [ ... ],
    "timers": [
        [ "Mapping", 0.2, 0.9 ],
        [ "Reduce", 0.91, 1.15 ]
    ]
}
```

Each entry will contain the timer name, and start and end offset of that timer relative to the entire log event's start time.  This allows you to get detailed timing data for all aspects of the execution path.

### Custom Time Provider

By default LogDefer will use Clock.currTime to determine the start timestamp for logging events.  If you would like to override this behaviour with your own time source you just need to implement the opCall to return a SysTime:

```d
auto timeProvider = () { return SysTime(12345); };
auto serializer = JSONSerializer!()((string msg) {});

auto logger = Logger!(typeof(serializer), typeof(timeProvider))(serializer, timeProvider);

logger.info(...);

```

### Visualization

Once the logs are written, you can use a separate tool to process and render the data into a useable format.  An excellent tool to use is `log-defer-viz` available at https://github.com/hoytech/Log-Defer-Viz
