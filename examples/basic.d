import std.stdio : writeln;

import logdefer.logger : DefaultLogger;

/* Simple example, creates a log defer instance that writes to
   stdout using the default serializer
*/
void main()
{
    auto logger = DefaultLogger((string data)
    {
        writeln(data);
    });

    logger.trace("Starting main...");
    
    logger.info("Multiline\noutput");

    try
    {
        auto timer = logger.timer("The try block");

        logger["RequestID"] = 123;
        auto product = multiply(7, 5, logger);
        logger.info("Product is ", product);
    }
    catch (Exception e)
    {
        logger.error("Error doing something: ", e.msg);
    }
}

int multiply(const int x, const int y, ref DefaultLogger logger)
{
    logger.info("Calculating product of ", x, " and ", y);
    auto timer = logger.timer("multiply");
    return x*y;
}
