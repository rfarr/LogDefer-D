import std.stdio;

import logdefer.logger;

alias MyLogger = Logger!Function;

/* Simple example, creates a log defer instance that writes to
   stdout using the default serializer
*/
void main()
{
    auto logger = MyLogger((immutable string data)
    {
        writeln(data);
    });

    logger.trace("Starting main\nMultiline output\n");


    try
    {
        logger.data("RequestID", 123);
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

    return x*y;
}
