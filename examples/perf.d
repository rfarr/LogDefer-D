import std.datetime;
import std.stdio;

import logdefer.logger;
import logdefer.serializer.json;

immutable uint RUNS = 10_000;

//Test raw serialization time
void main()
{
    none();
    json();
}

void none()
{
    StopWatch sw;
    sw.start();

    auto serializer = (const ref EventContext evt) {};

    foreach(i; 0..RUNS)
    {
        auto logger = Logger!(typeof(serializer))(serializer);

        logger["key"] = "value";
        logger["key2"] = "value2";
        logger["key3"] = "value3";
        logger.error("Example error message");
        logger.info("Example info message");
        logger.trace("Example trace message");
    }

    sw.stop();

    writeln("%s runs with no serialization took %s ms".format(RUNS, sw.peek().msecs));
}

void json()
{
    StopWatch sw;
    sw.start();

    foreach(i; 0..RUNS)
    {
        auto logger = DefaultLogger((string data) {
        });

        logger["key"] = "value";
        logger["key2"] = "value2";
        logger["key3"] = "value3";
        logger.error("Example error message");
        logger.info("Example info message");
        logger.trace("Example trace message");
    }

    sw.stop();

    writeln("%s runs with JSON serialization took %s ms".format(RUNS, sw.peek().msecs));
}
