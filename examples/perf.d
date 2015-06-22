import std.datetime;
import std.stdio;

import logdefer.logger;

alias Logger = LogDefer!();

//Test raw serialization time
void main()
{
    StopWatch sw;
    sw.start();

    immutable uint RUNS = 10_000;

    foreach(i; 0..RUNS)
    {
        auto logger = Logger((string data) { });

        logger.data("key", "value");
        logger.data("key2", "value2");
        logger.data("key3", "value3");
        logger.error("Example error message");
        logger.info("Example info message");
        logger.trace("Example trace message");
    }

    sw.stop();

    writeln("%s runs took %s ms".format(RUNS, sw.peek().msecs));
}
