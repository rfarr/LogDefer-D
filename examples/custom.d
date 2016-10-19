import std.stdio : writeln;

import std.array : Appender;
import std.conv : to;
import std.datetime : dur, Clock, SysTime;
import std.string : replace;

import logdefer.logger : EventContext, Logger, LogLevel;
import logdefer.time.duration : Seconds, Nanos;

import unixtime : UnixTimeHiRes;

// Very basic custom serialier
auto mySerializer = (const ref EventContext evt)
{
    Appender!string buffer;

    foreach(ref entry; evt.logs.data)
    {
        buffer.put(to!string(evt.realStartTime + UnixTimeHiRes(
            entry.endOffset.toDuration!Seconds().value,
            entry.endOffset.toDuration!Nanos().value % 1_000_000_000,
        )));
        buffer.put(" ");

        buffer.put("[");
        buffer.put(to!string(cast(LogLevel)entry.verbosity));
        buffer.put("] ");

        buffer.put(entry.msg.replace("\n", "\\n"));
        buffer.put("\n");
    }

    writeln(buffer.data());
};

// Let's live in the past!
auto myTimeProvider = ()
{
    return Clock.currTime - dur!"seconds"(123);
};

alias MyLogger = Logger!(typeof(mySerializer), typeof(myTimeProvider));

void main()
{

    auto logger = MyLogger(mySerializer, myTimeProvider);

    logger.trace("Starting main...");
    
    logger.info("Multiline\noutput");

    try
    {
        logger["RequestID"] = 123;
        auto product = multiply(7, 5, logger);
        logger.info("Product is ", product);
    }
    catch (Exception e)
    {
        logger.error("Error doing something: ", e.msg);
    }
}

int multiply(const int x, const int y, ref MyLogger logger)
{
    logger.info("Calculating product of ", x, " and ", y);
    auto timer = logger.timer("multiply");
    return x*y;
}
