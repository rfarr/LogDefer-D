module logdefer.logger;


import std.array : Appender;
import std.conv : to;

public import logdefer.common : DefaultTimeProvider, DelegateWriter, EventContext, LogEntry, LogLevel, Verbosity;
import logdefer.serializer.json : JSONSerializer;
import logdefer.time.duration : Nanos;
import logdefer.time.utils : toDuration;
import logdefer.timer : Timer;

import unixtime : ClockType, UnixTimeHiRes;

alias DefaultLogger = Logger!();

/**
  The primary interface into the logging system.  Logger is templatized
  based on:

  Serializer - formats the output and passes it to writer
  TimeProvider - what source of time to use

  By default the Serializer is JSON and the TimeProvider uses the standard Clock
  in std.datetime.  In this case simply pass a delegate callback that takes the
  serialized string data and does whatever you want with it.  The constructor
  will take care of initializing the JSON serializer with your provided callback.

  If you want to use a different serializer simple pass it in instead to the
  properly templatized struct:

  auto mySerializer = MySerializer();
  auto logger = Logger!(MySerializer)(mySerializer);

  The only constraint is that your serializer implements opCall which takes
  a ref to the EventContext object.   Thus it could be a function, delegate,
  struct or class.

  If you want to provide your own source of time (for testing, or some external
  time provider) you just call the constructor with your TimeProvider which
  again must implement opCall and returns a UnixTime:

  auto myTimeProvider = () { return UnixTime(0); };
  auto logger = Logger!(MySerializer, typeof(myTimeProvider))(xxx, myTimeProvider);
  
  As you log against the log defer instance it will accumulate the logs into its
  internal buffer.  Once the object goes out of scope the logs are passed to the
  serializer which handles formatting and writing out the logs.
  */
struct Logger(
    Serializer = JSONSerializer!(DelegateWriter),
    TimeProvider = typeof(DefaultTimeProvider)
)
{
    public:
        
        @disable this(this);

        /*
           Convenience constructor.  Uses default serializer and time provider
           with provided delegate to write log
        */
        this()(void delegate(string msg) callback)
        {
            serializer_ = Serializer(callback);
            eventContext_.realStartTime = DefaultTimeProvider();
            eventContext_.monotonicStartTime = UnixTimeHiRes.now!(ClockType.MONOTONIC)();
        }

        /*
            Uses default time provider and provided serializer
        */
        this()(Serializer serializer)
        {
            serializer_  = serializer;
            eventContext_.realStartTime = DefaultTimeProvider();
            eventContext_.monotonicStartTime = UnixTimeHiRes.now!(ClockType.MONOTONIC)();
        }

        /*
           Uses provided serializer and time provider
        */
        this()(Serializer serializer, TimeProvider timeProvider)
        {
            serializer_ = serializer;
            eventContext_.realStartTime = timeProvider();
            eventContext_.monotonicStartTime = UnixTimeHiRes.now!(ClockType.MONOTONIC)();
        }

        // Commit log when going out of scope
        ~this()
        {
            commit();
        }

        // Add given parameters to the log with given verbosity
        void addLog(Param...)(Verbosity verbosity, const Param params)
        {
            // Log threshold not met, ignore log
            if (verbosity > logLevel_)
            {
                return;
            }

            // Concatenate all the log params into a string
            auto msg = Appender!string();
            foreach(param; params)
            {
                msg.put(to!string(param));
            }
            // Store the message along with verbosity and duration
            eventContext_.logs.put(LogEntry(toDuration!Nanos(eventContext_.monotonicStartTime, UnixTimeHiRes.now!(ClockType.MONOTONIC)()), verbosity, msg.data));
        }

        // Add/update associated metadata with the event context
        void opIndexAssign(Key, Value)(const auto ref Value value, const auto ref Key key)
        {
            eventContext_.metadata[to!string(key)] = to!string(value);
        }

        string opIndex(Key)(const auto ref Key key)
        {
            return eventContext_.metadata[to!string(key)];
        }

        auto timer(string timerName)
        {
            eventContext_.timers.put(Timer(timerName, eventContext_.monotonicStartTime));
            return eventContext_.timers.data[$-1].start_timer();
        }

        // Convenience wrappers...
        void error(Param...)(auto ref const Param params)
        {
            addLog(LogLevel.Error, params);
        }

        void warn(Param...)(auto ref const Param params)
        {
            addLog(LogLevel.Warn, params);
        }

        void info(Param...)(auto ref const Param params)
        {
            addLog(LogLevel.Info, params);
        }

        void trace(Param...)(auto ref const Param params)
        {
            addLog(LogLevel.Trace, params);
        }

        // Manipulate and view log levels...
        void setLogLevel(LogLevel logLevel)
        {
            logLevel_ = logLevel;
        }

        void setLogLevel(int logLevel)
        {
            logLevel_ = logLevel;
        }

        int logLevel()
        {
            return logLevel_;
        }

        bool isError()
        {
            return logLevel_ <= LogLevel.Error;
        }

        void setError()
        {
            logLevel_ = LogLevel.Error;
        }

        bool isWarn()
        {
            return logLevel_ <= LogLevel.Warn;
        }

        void setWarn()
        {
            logLevel_ = LogLevel.Warn;
        }

        bool isInfo()
        {
            return logLevel_ <= LogLevel.Info;
        }

        void setInfo()
        {
            logLevel_ = LogLevel.Info;
        }

        bool isTrace()
        {
            return logLevel_ <= LogLevel.Trace;
        }

        void setTrace()
        {
            logLevel_ = LogLevel.Trace;
        }


    private:

        Serializer serializer_ = void;
        TimeProvider timeProvider_;
        EventContext eventContext_;
        int logLevel_ = int.max;

        // Commit the logs in the buffer
        void commit()
        {
            eventContext_.endOffset = toDuration!Nanos(eventContext_.monotonicStartTime, UnixTimeHiRes.now!(ClockType.MONOTONIC)());
            serializer_(eventContext_);
        }
}

version (unittest)
{
    import std.array : front;
    import std.stdio : writeln;
    import std.typecons : Tuple;

    auto time = ()
    {
        return UnixTimeHiRes(1234);
    };

    const(EventContext)[] events;
    auto serializer = (const ref EventContext eventContext)
    {
        events ~= eventContext;
    };

    alias Spec = Tuple!(int, string);

    auto testSpecs = [
        Spec(45, "custom 1"),
        Spec(40, "trace"),
        Spec(30, "info"),
        Spec(20, "warn"),
        Spec(10, "error"),
        Spec(5, "custom 2"),
    ];

    void verifyLogs(const ref EventContext evt, Spec[] specs)
    {
        auto logs = evt.logs.data;
        assert(logs.length == specs.length);
        uint i;
        foreach(spec; specs)
        {
            assert(logs[i].verbosity == spec[0]);
            assert(logs[i].msg == spec[1]);
            i++;
        }
    }

    alias TestLogger = Logger!(typeof(serializer), typeof(time));

    void testLog(ref TestLogger logger)
    {
        logger.addLog(45, "custom 1");
        logger.trace("trace");
        logger.info("info");
        logger.warn("warn");
        logger.error("error");
        logger.addLog(5, "custom 2");

    }
}

unittest
{
    writeln("[UnitTest Logger] - default log level, start time");

    events.destroy;

    {
        auto logger = TestLogger(serializer, time);
        testLog(logger);
        {
            auto timer = logger.timer("timer");
        }
        logger["RequestID"] = 7;
        assert(events.length == 0);
    }

    assert(events.length == 1);

    auto evt = events.front;
    assert(evt.realStartTime == time());
    assert(evt.endOffset.value > 0);

    assert(evt.metadata.length == 1);
    assert(evt.metadata["RequestID"] == "7");

    assert(evt.timers.data.length == 1);
    assert(evt.timers.data.front.name == "timer");
    assert(evt.timers.data.front.start > 0);
    assert(evt.timers.data.front.end > 0);

    verifyLogs(evt, testSpecs);
}

unittest
{
    writeln("[UnitTest Logger] - trace log level");

    events.destroy;

    {
        auto logger = TestLogger(serializer, time);
        logger.setTrace();

        testLog(logger);
    }

    verifyLogs(events.front, testSpecs[1..$]);
}

unittest
{
    writeln("[UnitTest Logger] - info log level");

    events.destroy;

    {
        auto logger = TestLogger(serializer, time);
        logger.setInfo();

        testLog(logger);
    }

    verifyLogs(events.front, testSpecs[2..$]);
}

// Log level set to warn 
unittest
{
    writeln("[UnitTest Logger] - warn log level");

    events.destroy;

    {
        auto logger = TestLogger(serializer, time);
        logger.setWarn();

        testLog(logger);
    }

    verifyLogs(events.front, testSpecs[3..$]);
}


// Log level set to error 
unittest
{
    writeln("[UnitTest Logger] - error log level");

    events.destroy;

    {
        auto logger = TestLogger(serializer, time);
        logger.setError();

        testLog(logger);
    }

    verifyLogs(events.front, testSpecs[4..$]);
}

// Log level set to custom
unittest
{
    writeln("[UnitTest Logger] - custom log level");

    events.destroy;

    {
        auto logger = TestLogger(serializer, time);
        logger.setLogLevel(7);

        testLog(logger);
    }

    verifyLogs(events.front, testSpecs[5..$]);
}

// Log level set to 0
unittest
{
    writeln("[UnitTest Logger] - 0 log level");

    events.destroy;

    {
        auto logger = TestLogger(serializer, time);
        logger.setLogLevel(0);

        testLog(logger);
    }

    verifyLogs(events.front, testSpecs[6..$]);
}
