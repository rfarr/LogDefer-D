module logdefer.timer;

import std.datetime;

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
        
        this(string timerName)
        {   
            timerName_ = timerName;
        }

        ~this()
        {
            if (sw_.running)
            {
                sw_.stop();
            }
            // If child freed don't do anything, else terminate
            child_ && child_.terminate();
        }

        // Starts timer and returns struct which when destroyed will
        // stop timer
        Scoped start_timer(TickDuration start)
        {
            start_ = start;
            sw_.start();
            auto child = Scoped(&this);
            child_ = &child;
            return child;
        }

        string name() const
        {
            return timerName_;
        }

        // Get the start offset of the timer
        TickDuration startDuration() const
        {
            return start_;
        }

        // Get the end offset of the timer
        TickDuration endDuration() const
        {
            return sw_.peek() + start_;
        }

    private:
        string timerName_;
        TickDuration start_;
        StopWatch sw_;
        Scoped* child_;

        // Called by child when it is freed
        void stop()
        {
            sw_.stop();
            child_ = null;
        }
}

version (unittest)
{
    import core.thread;
    import std.stdio;
}

unittest
{
    writeln("[UnitTest Timer] - aprox duration");

    auto timer1 = Timer("test1");
    auto timer2 = Timer("test2");

    auto start1 = TickDuration(123);
    auto start2 = TickDuration(456);
    {
        auto scope1 = timer1.start_timer(start1);
        {
            auto scope2 = timer2.start_timer(start2);
            Thread.sleep(dur!"msecs"(250));
        }
        Thread.sleep(dur!"msecs"(250));
    }

    assert(timer1.name == "test1");
    assert(timer1.startDuration == start1);
    assert(cast(Duration)timer1.endDuration > start1 + dur!"msecs"(400));
    assert(cast(Duration)timer1.endDuration < start1 + dur!"msecs"(600));

    assert(timer2.name == "test2");
    assert(timer2.startDuration == start2);
    assert(cast(Duration)timer2.endDuration > start2 + dur!"msecs"(200));
    assert(cast(Duration)timer2.endDuration < start2 + dur!"msecs"(300));
}
