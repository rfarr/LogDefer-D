import std.concurrency;
import std.stdio;

import logdefer.logger;
import logdefer.writer.concurrent;

alias WriterWorker = ConcurrentWriterWorker!Function;
alias Writer = ConcurrentWriterClient;
alias Logger = LogDefer!Writer;

void main()
{
    // Spawn the background worker
    auto worker = WriterWorker((immutable string msg)
    {
        writeln(msg);
    });

    // "APP" thread
    auto thread = function(int id, Tid worker)
    {
        Logger getLogger()
        {
            return Logger(Writer(worker));
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
