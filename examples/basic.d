import std.stdio;

import logdefer.logger;

alias Logger = LogDefer!();

/* Simple example, creates a log defer instance that writes to
   stdout using the default serializer
*/
void main()
{
    auto logger = Logger((string data)
    {
        writeln(data);
    });

    logger.trace("Starting main...");
    
    logger.info("Multiline\noutput");

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

int multiply(const int x, const int y, ref Logger logger)
{
    logger.info("Calculating product of ", x, " and ", y);

    return x*y;
}
