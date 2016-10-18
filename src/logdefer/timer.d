module logdefer.timer;


import logdefer.time.duration : Nanos;
import logdefer.time.utils : toDuration;

import unixtime : ClockType, UnixTimeHiRes;

struct Timer
{   
    public:

        // This is what triggers the timer to stop when it goes out of scope
        struct Scoped
        {
            public:
                @disable this();

                this(Timer* parent)
                {
                    parent_ = parent;
                }

                ~this()
                {
                    // If parent freed don't do anything, else stop timer
                    parent_ && parent_.stop();
                }

            private:
                Timer* parent_;

                // Parent freed
                void terminate()
                {
                    parent_ = null;
                }
        }
        
        @disable this();
        
        this(string timerName, UnixTimeHiRes startTime)
        {   
            timerName_ = timerName;
            startTime_ = startTime;
        }

        ~this()
        {
            // If child freed don't do anything, else terminate
            child_ && child_.terminate();
        }

        // Starts timer and returns struct which when destroyed will
        // stop timer
        Scoped start_timer()
        {
            startOffset_ = toDuration!Nanos(startTime_, UnixTimeHiRes.now!(ClockType.MONOTONIC_PRECISE)());
            auto child = Scoped(&this);
            child_ = &child;
            return child;
        }

        string name() const
        {
            return timerName_;
        }

        // Get the start offset of the timer
        Nanos start() const
        {
            return startOffset_;
        }

        // Get the end offset of the timer
        Nanos end() const
        {
            return toDuration!Nanos(startTime_, UnixTimeHiRes.now!(ClockType.MONOTONIC_PRECISE)());
        }

    private:
        string timerName_;
        UnixTimeHiRes startTime_;
        Nanos startOffset_;
        Scoped* child_;

        // Called by child when it is freed
        void stop()
        {
            child_ = null;
        }
}

version (unittest)
{
    import core.thread;
    import std.stdio;

    import logdefer.time.duration : Millis;
}

unittest
{
    writeln("[UnitTest Timer] - aprox duration");

    auto now = UnixTimeHiRes.now!(ClockType.MONOTONIC_PRECISE)();
    auto timer1 = Timer("test1", now);
    auto timer2 = Timer("test2", now);

    {
        auto scope1 = timer1.start_timer();
        {
            auto scope2 = timer2.start_timer();
            Thread.sleep(dur!"msecs"(250));
        }
        Thread.sleep(dur!"msecs"(250));
    }

    assert(timer1.name == "test1");
    assert(timer1.start > 0);
    assert(timer1.end > Millis(400));
    assert(timer1.end < Millis(600));

    assert(timer2.name == "test2");
    assert(timer2.start > 0);
    assert(timer2.end > Millis(400));
    assert(timer2.end < Millis(600));
}
