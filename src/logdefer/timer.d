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
            sw_.stop();
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
        TickDuration start() const
        {
            return start_;
        }

        // Get the end offset of the timer
        TickDuration end() const
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
