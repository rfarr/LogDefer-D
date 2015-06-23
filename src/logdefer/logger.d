module logdefer.logger;

public import logdefer.common;

import std.conv;
import std.traits;

/**
  The primary interface into the logging system.  LogDefer is templatized
  based on:

  Serializer - formats the output and passes it to writer
  TimeProvider - what source of time to use

  By default the Serializer is JSON and the TimeProvider uses the standard Clock
  in std.datetime.
  
  You have to provide the Serializer which can be a function, delegate or object.
  The only requirement is that your serializer implement the opCall
  function which will receive the serialized string of data as it's only parameter.

  As you log against the log defer instance it will accumulate the logs into its
  internal buffer.  Once the object goes out of scope the logs are serialized
  and written to the provided serializer.
  */
struct LogDefer(Serializer = DefaultSerializer, TimeProvider = typeof(DefaultTimeProvider))
{
    public:
        
        @disable this();

        @disable this(this);

        /*
           Convenience constructor.  Uses default serializer and time provider
           with provided delegate to write log
        */
        this()(void delegate(string msg) callback)
        {
            serializer_ = Serializer(callback);
            eventContext_.startTime = DefaultTimeProvider();
            sw_.start();
        }

        /*
            Uses default time provider and provided serializer
        */
        this()(Serializer serializer)
        {
            serializer_  = serializer;
            eventContext_.startTime = DefaultTimeProvider();
            sw_.start();
        }

        /*
           Uses provided serializer and time provider
        */
        this()(Serializer serializer, TimeProvider timeProvider)
        {
            serializer_ = serializer;
            eventContext_.startTime = timeProvider();
            sw_.start();
        }

        // Commit log when going out of scope
        ~this()
        {
            commit();
        }

        // Add given parameters to the log with given verbosity
        void add_log(Param...)(Verbosity verbosity, const ref Param params)
        {
            // Log threshold not met, ignore log
            if (verbosity < logLevel_)
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
            eventContext_.logs.put(LogEntry(sw_.peek(), verbosity, msg.data));
        }

        // Add/update associated metadata with the event context
        void data(Key, Value)(const auto ref Key key, const auto ref Value value)
        {
            eventContext_.metadata[to!string(key)] = to!string(value);
        }

        string opIndex(Key)(const auto ref Key key)
        {
            return eventContext_.metadata[to!string(key)];
        }

        // Convenience wrappers...
        void error(Param...)(auto const Param params)
        {
            add_log(LogLevel.Error, params);
        }

        void warn(Param...)(auto const Param params)
        {
            add_log(LogLevel.Warn, params);
        }

        void info(Param...)(auto const Param params)
        {
            add_log(LogLevel.Info, params);
        }

        void trace(Param...)(auto const Param params)
        {
            add_log(LogLevel.Trace, params);
        }

        // Manipulate and view log levels...
        void logLevel(LogLevel logLevel)
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

        bool isWarn()
        {
            return logLevel_ <= LogLevel.Warn;
        }

        bool isInfo()
        {
            return logLevel_ <= LogLevel.Info;
        }

        bool isTrace()
        {
            return logLevel_ <= LogLevel.Trace;
        }


    private:

        Serializer serializer_ = void;
        TimeProvider timeProvider_;
        StopWatch sw_;
        EventContext eventContext_;
        int logLevel_ = int.min;

        // Commit the logs in the buffer
        void commit()
        {
            eventContext_.endDuration = sw_.peek();
            serializer_(eventContext_);
        }
}
