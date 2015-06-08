module logdefer.serializer.json;

import logdefer.logger;

import std.algorithm;
import std.array;
import std.datetime;
import std.string;

import std.json;

immutable(string) JsonSerializer (const ref LogDefer.EventContext eventContext)
{
    return JSONValue([
        "start": JSONValue(eventContext.startTime.format()),
        "end": JSONValue(eventContext.endDuration.format()),
        "logs": JSONValue(
            eventContext.events.data.map!(
                event => JSONValue([
                    JSONValue(event.eventDuration.format()),
                    JSONValue(event.verbosity),
                    JSONValue(event.msg)
                ])
            ).array
         ),
    ]).toString();
}

string format(const ref SysTime time)
{
    return std.string.format("%f",
        cast(double)time.toUnixTime
        + cast(double)time.fracSec.usecs
        / 1000000.0
        );
}

string format(const ref TickDuration duration)
{
    return std.string.format("%f",
        cast(double)duration.seconds
        + cast(double)duration.usecs
        / 1000000.0
    );
}
