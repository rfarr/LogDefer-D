module logdefer.common;

public import std.array;
public import std.datetime;
public import std.string;

import std.stdio;

import logdefer.serializer.json;


alias Verbosity = immutable int;
alias Metadata = string[string];

alias Function = void function(immutable string msg);
alias Delegate = void delegate(immutable string msg);

// Define the basic log levels
enum LogLevel { Error = 10, Warn = 20, Info = 30, Trace = 40 };

// Represents a log entry
struct LogEntry
{
    immutable TickDuration eventDuration; // duration from start
    immutable Verbosity verbosity; // log level
    immutable string msg; // log message

    string toString() const
    {
        return "%s, %s, %s".format(eventDuration.msecs, verbosity, msg);
    }
}

// Represents the event that the logs entries pertain to
struct EventContext
{
    SysTime startTime; // Time when event first started
    TickDuration endDuration; // Duration of the event
    Metadata metadata; // Associated metadata with the event
    Appender!(LogEntry[]) logs; // log entries

    string toString() const
    {
        return "%s, %s, %s, %(%s, %), ".format(
            startTime.toUnixTime, endDuration.msecs, metadata, logs.data
        );
    }
}

// By default use the JSON serializer
alias DefaultSerializer = JsonSerializer;

static const DefaultTimeProvider = () {
    return Clock.currTime;
};
static const DefaultDateTimeProvider = () {
    return cast(DateTime)Clock.currTime;
};

alias OnError = immutable(void delegate (immutable string msg));
