import std.stdio;

import logdefer.logger;
import logdefer.writer.file;

alias MyLogger = Logger!FileWriter;

MyLogger getLogger()
{
    return MyLogger(FileWriter("output.log"));
}

void main()
{
    auto logger = getLogger();
    logger.error("Can't hack the Gibson!");
}

