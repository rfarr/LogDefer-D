import std.stdio;

import logdefer.logger;

alias Logger = LogDefer!Delegate;

Logger getLogger()
{
    auto file = new File("output.log", "w");

    auto logger = Logger((immutable string data)
    {
        file.writeln(data);
    });

    return logger;
}

void main()
{
    auto logger = getLogger();
    logger.error("Can't hack the Gibson!");
}

