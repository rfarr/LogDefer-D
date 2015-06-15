module logdefer.writer.file;

import std.datetime;
import std.path;
import std.stdio;
import std.string;
import std.traits;

import logdefer.common;

enum LogPeriod { NONE, HOURLY, DAILY };

struct FileRoller(Writer = FileWriter, DateTimeProvider = typeof(DefaultDateTimeProvider))
{
    public:


        this()(Writer writer, const LogPeriod logPeriod = LogPeriod.HOURLY, DateTimeProvider dateTimeProvider = DefaultDateTimeProvider)
        if (is(DateTimeProvider == typeof(DefaultDateTimeProvider)))
        {
            writer_ = writer;
            logPeriod_ = logPeriod;
            dateTimeProvider_ = dateTimeProvider;
            lastRolledAt_ = dateTimeProvider_();
        }


        this()(Writer writer, const LogPeriod logPeriod, DateTimeProvider dateTimeProvider)
        if (!is(DateTimeProvider == typeof(DefaultDateTimeProvider)))
        {
            writer_ = writer;
            logPeriod_ = logPeriod;
            dateTimeProvider_ = dateTimeProvider;
            lastRolledAt_ = dateTimeProvider_();
        }

        void opCall(immutable string msg)
        {
            rollLog();
            writer_(msg);
        }

    private:

        Writer writer_;

        const LogPeriod logPeriod_;
        DateTimeProvider dateTimeProvider_;
        DateTime lastRolledAt_;

        void rollLog()
        {
            auto now = dateTimeProvider_();

            if (!shouldRollLog(now))
            {
                return;
            }

            // Move the current file to the archived name
            // If moving fails (file exists, etc) then don't move
            // it and just keep open existing file 
            if (writer_.move(getRolledFilename(writer_.filename)))
            {
                writer_.reopen();
            }

            lastRolledAt_ = now;
        }

        bool shouldRollLog(const ref DateTime now) const
        {
            switch (logPeriod_)
            {
                case LogPeriod.HOURLY:
                    return
                           now.hour != lastRolledAt_.hour
                        || now.dayOfYear != lastRolledAt_.dayOfYear
                        || now.year != lastRolledAt_.year;
                case LogPeriod.DAILY:
                    return 
                           now.dayOfYear != lastRolledAt_.dayOfYear
                        || now.year != lastRolledAt_.year;
                default:
                    return false;
            }
        }

        string getRolledFilename(const string filename) const
        {
            switch (logPeriod_)
            {
                case LogPeriod.HOURLY:
                    return dirName(filename) ~ dirSeparator ~ "%04d-%02d-%02dT%02d".format(
                        lastRolledAt_.year, lastRolledAt_.month,
                        lastRolledAt_.day, lastRolledAt_.hour
                    ) ~ "_" ~ baseName(filename);
                case LogPeriod.DAILY:
                    return dirName(filename) ~ dirSeparator ~ "%04d-%02d-%02d".format(
                        lastRolledAt_.year, lastRolledAt_.month,
                        lastRolledAt_.day
                    ) ~ "_" ~ baseName(filename);
                default:
                    return filename;
            }
        }
}

version (unittest)
{
    import std.exception;

    struct MockFileWriter
    {
        string moveFilename;
        bool moved = true;
        bool calledReopen = false;
        bool reopenFailed = false;
        bool writeFailed = false;
        Appender!(string[]) wrote;

        this(string filename)
        {
            this.filename = filename;
        }

        string filename;

        void reopen()
        {
            calledReopen = true;
            if (reopenFailed)
            {
                throw new Exception("OMG");
            }
        }

        bool move(string newFilename)
        {
            moveFilename = newFilename;
            return moved;
        }

        void opCall (immutable string msg)
        {
            if (writeFailed)
            {
                throw new Exception("OMG");
            }
            wrote.put(msg);
        }
    }

    alias MockDateTimeProvider = DateTime delegate ();
    alias TestFileRoller = FileRoller!(MockFileWriter, MockDateTimeProvider);
    static auto dateTime = DateTime(2015, 6, 30, 23, 30, 30);

    alias seconds = dur!"seconds";
    alias minutes = dur!"minutes";
    alias hours = dur!"hours";
    alias days = dur!"days";
}

// No file rolling
unittest
{
    auto now = dateTime;
    auto roller = TestFileRoller(MockFileWriter("/tmp/foo.log"), LogPeriod.NONE, () { return now; });

    roller("Test 1");
    assert(roller.writer_.wrote.data.length == 1);
    assert(roller.writer_.wrote.data[0] == "Test 1");
    assert(roller.writer_.calledReopen == false);
    assert(roller.writer_.moveFilename == "");

    now.month(Month.jul);
    roller("Test 2");
    assert(roller.writer_.wrote.data.length == 2);
    assert(roller.writer_.wrote.data[1] == "Test 2");
    assert(roller.writer_.calledReopen == false);
    assert(roller.writer_.moveFilename == "");

    now.year(2016);
    roller("Test 3");
    assert(roller.writer_.wrote.data.length == 3);
    assert(roller.writer_.wrote.data[2] == "Test 3");
    assert(roller.writer_.calledReopen == false);
    assert(roller.writer_.moveFilename == "");
}

// Hourly file rolling
unittest
{
    auto now = dateTime;
    auto roller = TestFileRoller(MockFileWriter("/tmp/foo.log"), LogPeriod.HOURLY, () { return now; });

    roller("Test 1");
    assert(roller.writer_.wrote.data.length == 1);
    assert(roller.writer_.wrote.data[0] == "Test 1");
    assert(roller.writer_.calledReopen == false);
    assert(roller.writer_.moveFilename == "");

    now.month(Month.jul);
    now.day(1);
    now.hour(0);
    roller("Test 2");
    assert(roller.writer_.wrote.data.length == 2);
    assert(roller.writer_.wrote.data[1] == "Test 2");
    assert(roller.writer_.calledReopen == true);
    assert(roller.writer_.moveFilename == "/tmp/2015-06-30T23_foo.log");

    roller.writer_.calledReopen = false;
    roller.writer_.moveFilename = "";

    now.minute(59);
    now.second(59);
    roller("Test 3");
    assert(roller.writer_.wrote.data.length == 3);
    assert(roller.writer_.wrote.data[2] == "Test 3");
    assert(roller.writer_.calledReopen == false);
    assert(roller.writer_.moveFilename == "");

    now.hour(1);
    now.minute(0);
    now.second(0);
    roller("Test 4");
    assert(roller.writer_.wrote.data.length == 4);
    assert(roller.writer_.wrote.data[3] == "Test 4");
    assert(roller.writer_.calledReopen == true);
    assert(roller.writer_.moveFilename == "/tmp/2015-07-01T00_foo.log");

    roller.writer_.calledReopen = false;
    roller.writer_.moveFilename = "";

    now.year(2016);
    roller("Test 5");
    assert(roller.writer_.wrote.data.length == 5);
    assert(roller.writer_.wrote.data[4] == "Test 5");
    assert(roller.writer_.calledReopen == true);
    assert(roller.writer_.moveFilename == "/tmp/2015-07-01T01_foo.log");
}

// Daily file rolling
unittest
{
    auto now = dateTime;
    auto roller = TestFileRoller(MockFileWriter("/tmp/foo.log"), LogPeriod.DAILY, () { return now; });

    roller("Test 1");
    assert(roller.writer_.wrote.data.length == 1);
    assert(roller.writer_.wrote.data[0] == "Test 1");
    assert(roller.writer_.calledReopen == false);
    assert(roller.writer_.moveFilename == "");

    now.month(Month.jul);
    now.day(1);
    now.hour(0);
    roller("Test 2");
    assert(roller.writer_.wrote.data.length == 2);
    assert(roller.writer_.wrote.data[1] == "Test 2");
    assert(roller.writer_.calledReopen == true);
    assert(roller.writer_.moveFilename == "/tmp/2015-06-30_foo.log");

    roller.writer_.calledReopen = false;
    roller.writer_.moveFilename = "";

    now.hour(23);
    now.minute(59);
    now.second(59);
    roller("Test 3");
    assert(roller.writer_.wrote.data.length == 3);
    assert(roller.writer_.wrote.data[2] == "Test 3");
    assert(roller.writer_.calledReopen == false);
    assert(roller.writer_.moveFilename == "");

    now.day(2);
    now.hour(0);
    now.minute(0);
    now.second(0);
    roller("Test 4");
    assert(roller.writer_.wrote.data.length == 4);
    assert(roller.writer_.wrote.data[3] == "Test 4");
    assert(roller.writer_.calledReopen == true);
    assert(roller.writer_.moveFilename == "/tmp/2015-07-01_foo.log");

    roller.writer_.calledReopen = false;
    roller.writer_.moveFilename = "";

    now.year(2016);
    roller("Test 5");
    assert(roller.writer_.wrote.data.length == 5);
    assert(roller.writer_.wrote.data[4] == "Test 5");
    assert(roller.writer_.calledReopen == true);
    assert(roller.writer_.moveFilename == "/tmp/2015-07-02_foo.log");
}

// Failed to roll, continues writing to old file 
unittest
{
    auto now = dateTime;
    auto roller = TestFileRoller(MockFileWriter("/tmp/foo.log"), LogPeriod.DAILY, () { return now; });

    now.month(Month.jul);
    now.day(1);

    // simulate move failing
    roller.writer_.moved = false;

    roller("Test 1");

    assert(roller.writer_.wrote.data.length == 1);
    assert(roller.writer_.wrote.data[0] == "Test 1");
    assert(roller.writer_.calledReopen == false);
    assert(roller.writer_.moveFilename == "/tmp/2015-06-30_foo.log");

    now.day(2);
    // next move succeeds
    roller.writer_.moved = true;

    roller("Test 2");

    assert(roller.writer_.wrote.data.length == 2);
    assert(roller.writer_.wrote.data[1] == "Test 2");
    assert(roller.writer_.calledReopen == true);
    assert(roller.writer_.moveFilename == "/tmp/2015-07-01_foo.log");
}

// Failed to reopen
unittest
{
    auto now = dateTime;
    auto roller = TestFileRoller(MockFileWriter("/tmp/foo.log"), LogPeriod.DAILY, () { return now; });

    now.month(Month.jul);
    now.day(1);

    // simulate reopen failing
    roller.writer_.reopenFailed = true;

    assertThrown!Exception(roller("Test 1"));
}

// Failed to write
unittest
{
    auto now = dateTime;
    auto roller = TestFileRoller(MockFileWriter("/tmp/foo.log"), LogPeriod.DAILY, () { return now; });

    // simulate write failing
    roller.writer_.writeFailed = true;

    assertThrown!Exception(roller("Test 1"));
}


struct FileWriter
{
    public:

        @disable this();

        this(const string filename)
        {
            filename_ = filename;
            reopen();
        }

        void opCall(immutable string msg)
        {
            logfile_.writeln(msg);
            logfile_.flush();
        }

        void reopen()
        {
            logfile_ = File(filename_, "a");
        }

        void close()
        {
            logfile_.close();
        }

        bool move(string newFilename)
        {
            return movefile(filename_, newFilename);
        }


        @property const string filename()
        {
            return filename_;
        }


    private:

        File logfile_;
        const string filename_;


version(Posix)
{
        import core.sys.posix.unistd;
        import core.stdc.errno;

        alias unistd = core.sys.posix.unistd;

        // move file without overwriting existing without race condition
        bool movefile(const string originalFilename, const string newFilename)
        {
            return 
                unistd.link(originalFilename.ptr, newFilename.ptr) == 0 &&
                unistd.unlink(filename.ptr) == 0;
        }
}
else
{
        pragma(msg, "WARNING: Log rolling not guaranteed atomic");

        import std.file;

        // move file without overwriting, contains race condition
        bool movefile(const string originalFilename, const string newFilename)
        {
            scope(failure) return false;

            if (exists(newFilename))
            {
                return false;
            }

            rename(originalFilename, newFilename);
        }
}

}

