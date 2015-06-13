module logdefer.serializer.json;

import logdefer.common;

import std.algorithm;
import std.array;
import std.datetime;
import std.string;

import std.json;
/**
  Basic JSON serializer that outputs in the standard Log::Defer format.
  See https://metacpan.org/pod/Log::Defer for more details on the format
  and tools to render it.
  */
struct JsonSerializer
{
    public:
        immutable(string) opCall (const ref EventContext eventContext)
        {
            return JSONValue([
                "start": JSONValue(format(eventContext.startTime)),
                "end": JSONValue(format(eventContext.endDuration)),
                "data": JSONValue(eventContext.metadata),
                "logs": JSONValue(
                    eventContext.logs.data.map!(
                        log => JSONValue([
                            JSONValue(format(log.eventDuration)),
                            JSONValue(log.verbosity),
                            JSONValue(log.msg)
                        ])
                    ).array
                 ),
            ]).toString();
        }

    private:

        static string format(const ref SysTime time)
        {
            return std.string.format("%f",
                cast(double)time.toUnixTime
                + cast(double)time.fracSec.usecs
                / 1000000.0
            );
        }

        static string format(const ref TickDuration duration)
        {
            return std.string.format("%f",
                cast(double)duration.seconds
                + cast(double)duration.usecs
                / 1000000.0
            );
        }
}
