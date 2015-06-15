import std.concurrency;
import std.stdio;

import logdefer.logger;
import logdefer.writer.concurrent;

alias WriterWorker = ConcurrentWriterWorker!Function;
alias Writer = ConcurrentWriterClient;
alias MyLogger = Logger!Writer;

void main()
{
    // Delegate to create worker writer
    auto immutable workerInit = delegate ()
    {
        return (immutable string msg) { writeln(msg); };
    };

    // Spawn the background worker
    auto worker = WriterWorker(workerInit);

    // "APP" thread
    auto thread = function(int id, Tid worker)
    {
        MyLogger getLogger()
        {
            return MyLogger(Writer(worker));
        }

        auto logger = getLogger();
        logger.info("Thread ", id);

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
