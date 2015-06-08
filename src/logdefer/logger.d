module logdefer.logger;

import std.array;
import std.datetime;
import std.string;
import std.conv;

import logdefer.serializer.json;

struct LogDefer
{
    public:

        alias Verbosity = immutable int;
        alias Metadata = string[string];
        alias Writer = void function(immutable string serializedLog);
        alias Serializer = immutable(string) function(const ref EventContext eventContext);

        enum LogLevel { Error = 10, Warn = 20, Info = 30, Trace = 40 };

        struct EventEntry
        {
            immutable TickDuration eventDuration;
            immutable Verbosity verbosity;
            immutable string msg;

            string toString() const
            {
                return "%s-%s-%s".format(eventDuration.msecs, verbosity, msg);
            }
        }

        struct EventContext
        {
            SysTime startTime;
            TickDuration endDuration;
            Metadata metadata;
            Appender!(EventEntry[]) events;

            string toString() const
            {
                return "Start: %s Duration: %s Metadata: %s Events: %(%s, %)".format(startTime.toUnixTime, endDuration.msecs, metadata, events.data);
            }
        }

        @disable this()();

        this(TimeProvider = Clock)(
            const Writer writer, const Serializer serializer = JsonSerializer
        )
        {
            writer_ = writer;
            serializer_ = serializer;
            eventContext_.startTime = TimeProvider.currTime;
            sw_.start();
        }

        ~this()
        {
            commit();
        }

        void add_log(Param...)(Verbosity verbosity, const ref Param params)
        {
            if (verbosity < filterLogLevel_)
            {
                return;
            }

            auto msg = Appender!string();
            foreach(param; params)
            {
                msg.put(to!string(param));
            }
            eventContext_.events.put(EventEntry(sw_.peek(), verbosity, msg.data));
        }

        void data(Key, Value)(const auto ref Key key, const auto ref Value value)
        {
            eventContext_.metadata[to!string(key)] = to!string(value);
        }

        void error(Param...)(auto const Param params)
        {
            add_log(LogLevel.Error, params);
        }

        void warn(Param...)(auto const Param params)
        {
            add_log(LogLevel.Warn, msg);
        }

        void info(Param...)(auto const Param params)
        {
            add_log(LogLevel.Info, msg);
        }

        void trace(Param...)(auto const Param params)
        {
            add_log(LogLevel.Trace, msg);
        }

        void commit()
        {
            eventContext_.endDuration = sw_.peek();
            writer_(serializer_(eventContext_));
            eventContext_.events.clear();
        }

        void filterLogLevel(LogLevel logLevel)
        {
            filterLogLevel_ = logLevel;
        }

    private:

        Writer writer_ = void;
        Serializer serializer_ = void;
        StopWatch sw_;
        EventContext eventContext_;
        int filterLogLevel_ = int.min;
}
