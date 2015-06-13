module logdefer.writer.concurrent;

import std.stdio;
import std.concurrency;

import logdefer.common;

/**
  A wrapper that serializes concurrent writes from multiple threads,
  using a background worker thread that calls the underlying write
  mechanism.
   */
struct ConcurrentWriterWorker(SerializedWriter)
{
    public:

        @disable this();

        // Create and spawn the worker thread
        this(SerializedWriter writer)
        {
            worker_ = spawn(&writerThread, writer);
        }

        // Thread stopped when destroyed
        ~this()
        {
            worker_.send(ShutdownMsg());
        }

        // Get handle to worker so clients can send messages
        Tid handle()
        {
            return worker_;
        }

    private:
        Tid worker_;

        // Sent to inform worker thread to stop running
        struct ShutdownMsg
        {
        }

        // The actual worker thread function
        static void writerThread(SerializedWriter writer)
        {
            bool running = true;

            while (running)
            {
                try
                {
                    receive(
                        (string msg) {
                            try
                            {
                                // Call the underlying writer
                                writer(msg);
                            }
                            catch (Exception e)
                            {
                                stderr.writeln(
                                    "[WARN] unable to write msg (", msg, ") "
                                    "due to exception (", e.msg, ")"
                                );
                            }
                        },
                        (ShutdownMsg msg) {
                            running = false;
                        }
                    );
                }
                // If owner exits we keep going
                catch (OwnerTerminated e)
                {
                }
                catch (Exception e)
                {
                    stderr.writeln(
                        "[WARN] unable to receive due to exception (", e.msg, ")"
                    );
                }
            }
        }
}

// Provides basic wrapper around the worker
struct ConcurrentWriterClient
{
    public:
        @disable this();

        this(Tid workerHandle)
        {
            worker_ = workerHandle;
        }

        void opCall(immutable string data)
        {
            worker_.send(data);
        }

    private:
        Tid worker_;
}

version(unittest)
{
    import std.string;
    import std.conv;
}

unittest
{
    immutable int THREADS = 100;

    // Send logged messages back to our owner
    auto worker = ConcurrentWriterWorker!Function((immutable string msg)
    {
        ownerTid.send(msg);
    });

    // "APP" threads
    auto fn = (Tid worker, int id)
    {
        // Create and log
        auto client = ConcurrentWriterClient(worker);
        client(to!string(id));
    };

    // Spawn the threads
    foreach(i; 0..THREADS)
    {
        spawn(fn, worker.handle, i);
    }

    // Wait for logged messages to come through
    foreach(i; 0..THREADS)
    {
        receiveOnly!string();
    }
}
