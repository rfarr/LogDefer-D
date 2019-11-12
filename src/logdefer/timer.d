module logdefer.timer;


import std.typecons : RefCounted;

import logdefer.time.duration : Nanos;
import logdefer.time.utils : toDuration;

import unixtime : ClockType, UnixTimeHiRes;

@safe
class Timer
{   
    public:

        // This is what triggers the timer to stop when it goes out of scope
        private struct Trigger
        {
            public:
                @disable this();

                this(Timer timer)
                {
                    timer_ = timer;
                }

                ~this()
                {
                  timer_.stop();
                }

            private:
              Timer timer_;
        }
        
        this(string timerName, const UnixTimeHiRes startTime)
        {   
            startTime_ = startTime;
            timerName_ = timerName;
        }

        // Starts timer and returns struct which when destroyed will
        // stop timer
        auto startTimer()
        {
            startOffset_ = toDuration!Nanos(startTime_, UnixTimeHiRes.now!(ClockType.MONOTONIC)());
            return Trigger(this);
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

        void stop()
        {
            endOffset_ = toDuration!Nanos(startTime_, UnixTimeHiRes.now!(ClockType.MONOTONIC)());
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
    auto timer1 = new Timer("test1", now);
    auto timer2 = new Timer("test2", now);

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
