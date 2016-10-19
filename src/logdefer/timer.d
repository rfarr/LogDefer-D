module logdefer.timer;


import std.typecons : RefCounted;

import logdefer.time.duration : Nanos;
import logdefer.time.utils : toDuration;

import unixtime : ClockType, UnixTimeHiRes;


struct Timer
{   
    public:

        // This is what triggers the timer to stop when it goes out of scope
        private struct Trigger
        {
            public:
                this(Timer* timer)
                {
                    timer_ = timer;
                }

                ~this()
                {
                    // If timer freed don't do anything, else stop timer
                    timer_ && timer_.stopTimer();
                }

            private:
                Timer* timer_;

                // Timer freed
                void terminate()
                {
                    timer_ = null;
                }
        }
        
        @disable this();
        
        this(string timerName, const UnixTimeHiRes startTime)
        {   
            startTime_ = startTime;
            timerName_ = timerName;
        }

        ~this()
        {
            // If trigger freed don't do anything, else terminate
            trigger_ && trigger_.terminate();
        }

        // Starts timer and returns struct which when destroyed will
        // stop timer
        auto startTimer()
        {
            trigger_ && trigger_.terminate();

            startOffset_ = toDuration!Nanos(startTime_, UnixTimeHiRes.now!(ClockType.MONOTONIC)());

            auto trigger = Trigger(&this);
            trigger_ = &trigger;
            return trigger;
        }

        @property
        string name() const
        {
            return timerName_;
        }

        @property
        Nanos start() const
        {
            return startOffset_;
        }

        @property
        Nanos end() const
        {
            return endOffset_;
        }

    private:
        const UnixTimeHiRes startTime_;

        Nanos startOffset_;
        Nanos endOffset_;

        Trigger* trigger_;

        immutable string timerName_;

        // Called by trigger when it is freed
        void stopTimer()
        {
            endOffset_ = toDuration!Nanos(startTime_, UnixTimeHiRes.now!(ClockType.MONOTONIC)());
            trigger_ = null;
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

    auto now = UnixTimeHiRes.now!(ClockType.MONOTONIC)();
    auto timer1 = Timer("test1", now);
    auto timer2 = Timer("test2", now);

    {
        auto scope1 = timer1.startTimer();
        {
            auto scope2 = timer2.startTimer();
            Thread.sleep(dur!"msecs"(250));
        }
        Thread.sleep(dur!"msecs"(250));
    }

    assert(timer1.name == "test1");
    assert(timer1.start > 0);
    assert(timer1.end > Millis(450));
    assert(timer1.end < Millis(600));

    assert(timer2.name == "test2");
    assert(timer2.start > 0);
    assert(timer2.end > Millis(200));
    assert(timer2.end < Millis(400));
}
