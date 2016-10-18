module logdefer.common;


import std.array : Appender, front;
import std.string : format;

import logdefer.timer : Timer;
import logdefer.time.duration : Nanos;

import unixtime : UnixTimeHiRes;


alias Verbosity = immutable int;
alias Metadata = string[string];

// Define the basic log levels
enum LogLevel { Error = 10, Warn = 20, Info = 30, Trace = 40 };

// Represents a log entry
struct LogEntry
{
    immutable Nanos endOffset; // duration from start
    immutable Verbosity verbosity; // log level
    immutable string msg; // log message

    string toString() const
    {
        return "%s, %s, %s".format(endOffset, verbosity, msg);
    }
}

// Represents the event that the logs entries pertain to
struct EventContext
{
    UnixTimeHiRes realStartTime; // Time when event first started
    UnixTimeHiRes monotonicStartTime; // Time when event first started in monotonic clock
    Nanos endOffset; // Monotonic duration of the event
    Metadata metadata; // Associated metadata with the event
    Appender!(LogEntry[]) logs; // log entries
    Appender!(Timer[]) timers; // user timers

    this(immutable EventContext other) immutable
    {
        realStartTime = other.realStartTime;
        monotonicStartTime = other.monotonicStartTime;
        endOffset = other.endOffset;
        metadata = other.metadata;
        logs = other.logs;
        timers = other.timers;
    }

    this(shared EventContext other) shared
    {
        realStartTime = other.realStartTime;
        monotonicStartTime = other.monotonicStartTime;
        endOffset = other.endOffset;
        metadata = other.metadata;
        logs = other.logs;
        timers = other.timers;
    }

    string toString() const
    {
        return "%s, %s, %s, %(%s, %), ".format(
            realStartTime, endOffset, metadata, logs.data
        );
    }
}

alias DelegateWriter = void delegate(string msg);

// By default use system clock
static const DefaultTimeProvider = () {
    return UnixTimeHiRes.now();
};
