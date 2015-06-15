import core.thread;

import std.concurrency;
import std.stdio;

import logdefer.logger;
import logdefer.writer.concurrent;
import logdefer.writer.file;

alias WriterWorker = ConcurrentWriterWorker!(FileRoller!());
alias Writer = ConcurrentWriterClient;
alias MyLogger = Logger!Writer;

void main()
{
    string logfile = "whatever.log";

    // Delegate to create worker writer
    // constructs a basic file writer that
    // is wrapped by a file roller
    auto immutable workerInit = delegate ()
    {
        return FileRoller!()(FileWriter(logfile));
    };

    auto immutable onError = delegate (immutable string errorMsg)
    {
        stderr.writeln("[ERROR] ", errorMsg);
    };

    // Spawn the background worker
    auto worker = WriterWorker(workerInit, onError);

    // "APP" thread, need to pass the Tid of the worker to it
    // alternatively could use register() and locate() for this
    auto thread = function(int id, Tid worker)
    {
        MyLogger getLogger()
        {
            return MyLogger(Writer(worker));
        }

        int count = 0;
        while(count++ < 480)
        {
            auto logger = getLogger();
            logger.info("Thread ", id);
            Thread.sleep(dur!"seconds"(10));
        }

        ownerTid.send(id);
    };

    foreach(i; 0..10)
    {
        spawn(thread, i, worker.handle);
    }

    foreach(i; 0..10)
    {
        receiveOnly!int();
    }
}
