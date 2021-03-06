module logdefer.serializer.json;


import logdefer.common : DelegateWriter, EventContext, LogEntry;

import std.array : Appender;
import std.string : format;
import std.traits : isSafe;
import std.utf : stride, UTFException;

import logdefer.time.duration : Seconds;

/**
  Basic JSON serializer that outputs in the standard Log::Defer format.
  See https://metacpan.org/pod/Log::Defer for more details on the format
  and tools to render it.
  Since output format is fixed this uses an optimized algorithm.
  This is about 2x faster than using std.json
  */
@safe
struct JSONSerializer(Writer = DelegateWriter) if (isSafe!Writer)
{
    public:

        @disable this();

        this(Writer writer)
        {
            writer_ = writer;
        }

        void opCall(const ref EventContext eventContext)
        {
            write("{");

            serializeEventTimers(eventContext);
            serializeLogs(eventContext);
            serializeMetadata(eventContext);
            serializeUserTimers(eventContext);

            write("}");

            writer_(buffer_[0..length_].idup);

            length_ = 0;
        }

    private:

        Writer writer_ = void;

        // Maximum JSON size
        immutable enum BUFFER_SIZE = 32 * 1024;

        char[BUFFER_SIZE] buffer_;
        uint length_;

        void serializeEventTimers(const ref EventContext eventContext)
        {
            writeAll([
                `"start":`,
                "%s".format(eventContext.realStartTime),
                `,"end":`,
                "%.6f".format(eventContext.endOffset.toUnits!Seconds),
            ]);
        }

        void serializeMetadata(const ref EventContext eventContext)
        {
            if (eventContext.metadata)
            {
                write(`,"data":{`);
                foreach(const ref entry; eventContext.metadata.byKeyValue())
                {
                    writeAll([
                        `"`,
                        encode(entry.key),
                        `":"`,
                        encode(entry.value),
                        `",`
                    ]);
                }
                buffer_[length_ - 1] = '}';
            }
        }

        void serializeLogs(const ref EventContext eventContext)
        {
            if (eventContext.logs.data)
            {
                write(`,"logs":[`);

                foreach(ref entry; eventContext.logs.data)
                {
                    writeAll([
                        "[",
                        "%.6f".format(entry.endOffset.toUnits!Seconds),
                        ",",
                        "%d".format(entry.verbosity),
                        `,"`,
                        encode(entry.msg),
                        `"],`
                    ]);
                }
                buffer_[length_ - 1] = ']'; 
            }
        }

        void serializeUserTimers(const ref EventContext eventContext)
        {
            if (eventContext.timers.data)
            {
                write(`,"timers":[`);

                foreach(ref timer; eventContext.timers.data)
                {
                    writeAll([
                        `["`,
                        timer.name,
                        `",`,
                        "%.6f".format(timer.start.toUnits!Seconds),
                        `,`,
                        "%.6f".format(timer.end.toUnits!Seconds),
                        `],`
                    ]);
                }
                buffer_[length_ - 1] = ']';
            }
        }

        void writeAll(string[] strings)
        {
            foreach(ref str; strings)
            {
                write(str);
            }
        }

        void write(string output)
        {
            foreach(ref c; output)
            {
                buffer_[length_++] = c;
            }
        }


        // Fast lookup for escapes
        static immutable string[256] mapping;
        shared static this()
        {
            foreach (i; 0..32)
            {
                mapping[i] = `\u` ~ format("%04x", i);
            }

            mapping[8] = `\b`;
            mapping[9] = `\t`;
            mapping[10] = `\n`;
            mapping[12] = `\f`;
            mapping[13] = `\r`;
            mapping[34] = `\"`;
            mapping[47] = `\/`;
            mapping[92] = `\\`;
        }

        /*
           Encodes string literals.  Input is assumed to be valid UTF8 string
           and will throw a UTFException if this is not the case

           - Control characters 0x0-0x1F plus 34, 47, 92 are escaped
           - Multibyte characters are written as is (not encoded using \uXXXX)
           */
        string encode(string input)
        {
            auto buffer = Appender!string();
            // Should be enough to handle most cases (except where most
            // characters are control characters
            buffer.reserve(input.length * 2);

            uint index;
            while (index < input.length)
            {   
                auto size = input.stride(index);
                // Single byte character
                if (size == 1)
                {
                    const char c = input[index++];
                    const string mapped = mapping[c];

                    // char is mapped to escape
                    if (mapped != string.init)
                    {
                        buffer.put(mapped);
                    }
                    // normal char
                    else
                    {
                        buffer.put(c);
                    }
                }
                // Multibyte
                else
                {
                    buffer.put(input[index..index+size]);
                    index += size;
                }
            }

            return buffer.data;
        }
}

version (unittest)
{
    import core.exception : RangeError;
    import std.conv : hexString;
    import std.exception : assertThrown;
    import std.json : JSONValue, parseJSON;
    import std.stdio : writeln;

    import logdefer.time.duration : Millis, Nanos;
    import unixtime : UnixTimeHiRes;

    auto now = UnixTimeHiRes(1434608500);
    Nanos duration = Millis(250);
}

unittest
{
    writeln("[UnitTest JSONSerializer] - basic start and end timer");

    auto ec = EventContext();
    ec.realStartTime = now;
    ec.endOffset = duration;
    
    JSONValue json;
    auto serializer = JSONSerializer!(DelegateWriter)((string msg) { json = parseJSON(msg); });
    serializer(ec);

    assert(json["start"].floating == 1434608500.0);
    assert(json["end"].floating == 0.250000);
    assert("logs" !in json);
    assert("data" !in json);

}

unittest
{
    writeln("[UnitTest JSONSerializer] - data section");

    auto ec = EventContext();
    ec.realStartTime = now;
    ec.endOffset = duration;
    ec.metadata["7"] = "2.1";
    ec.metadata["foo"] = "bar";

    JSONValue json;
    auto serializer = JSONSerializer!(DelegateWriter)((string msg) { json = parseJSON(msg); });
    serializer(ec);

    assert("start" in json);
    assert("end" in json);
    assert("logs" !in json);
    assert("data" in json);
    assert(json["data"].object().length == 2);
    assert(json["data"]["7"].str == "2.1");
    assert(json["data"]["foo"].str == "bar");
}

unittest
{
    writeln("[UnitTest JSONSerializer] - log entries");

    auto ec = EventContext();
    ec.realStartTime = now;
    ec.endOffset = duration;
    ec.logs.put(LogEntry(duration, 10, "line 1"));
    ec.logs.put(LogEntry((duration * 2), 15, "line 2"));
    ec.logs.put(LogEntry((duration * 3), 15, ""));

    JSONValue json;
    auto serializer = JSONSerializer!(DelegateWriter)((string msg) { json = parseJSON(msg); });
    serializer(ec);

    assert("start" in json);
    assert("end" in json);
    assert("logs" in json);
    assert("data" !in json);
    assert(json["logs"].array.length == 3);

    assert(json["logs"][0][0].floating == 0.25);
    assert(json["logs"][0][1].integer == 10);
    assert(json["logs"][0][2].str == "line 1");

    assert(json["logs"][1][0].floating == 0.5);
    assert(json["logs"][1][1].integer == 15);
    assert(json["logs"][1][2].str == "line 2");

    assert(json["logs"][2][0].floating == 0.75);
    assert(json["logs"][2][1].integer == 15);
    assert(json["logs"][2][2].str == "");
}

unittest
{
    writeln("[UnitTest JSONSerializer] - UTF-8");

    auto ec = EventContext();
    ec.realStartTime = now;
    ec.endOffset = duration;
    ec.metadata[hexString!("e8af b7e6 b182 4944 0a00")] = hexString!("3731 202d 20e9 98bf e5b0 94e6 b395 0a00");
    ec.logs.put(LogEntry(duration, 1, hexString!("e994 99e8 afaf 0a00")));

    JSONValue json;
    auto serializer = JSONSerializer!(DelegateWriter)((string msg) { json = parseJSON(msg); });
    serializer(ec);

    assert("start" in json);
    assert("end" in json);
    assert("logs" in json);
    assert("data" in json);

    assert(json["logs"].array.length == 1);
    assert(json["logs"][0][2].str == hexString!("e994 99e8 afaf 0a00"));

    assert(json["data"][hexString!("e8af b7e6 b182 4944 0a00")].str == hexString!("3731 202d 20e9 98bf e5b0 94e6 b395 0a00"));
}

unittest
{
    writeln("[UnitTest JSONSerializer] - invalid UTF-8");

    auto ec = EventContext();
    ec.realStartTime = now;
    ec.endOffset = duration;
    // Invalid sequence
    ec.logs.put(LogEntry(duration, 1, hexString!("ff01")));

    JSONValue json;
    auto serializer = JSONSerializer!(DelegateWriter)((string msg) { json = parseJSON(msg); });
    assertThrown!UTFException(serializer(ec));
}

unittest
{
    writeln("[UnitTest JSONSerializer] - control characters");

    auto ec = EventContext();
    ec.realStartTime = now;
    ec.endOffset = duration;
    ec.logs.put(LogEntry(
        duration, 10, "\t\tconh\btrol\nchar//a\\cters\0")
    );

    JSONValue json;
    auto serializer = JSONSerializer!(DelegateWriter)((string msg) { json = parseJSON(msg); });
    serializer(ec);

    assert("start" in json);
    assert("end" in json);
    assert("logs" in json);

    assert(json["logs"][0][2].str == "\t\tconh\btrol\nchar//a\\cters\0");
}

unittest
{
    writeln("[UnitTest JSONSerializer] - message too long");

    auto ec = EventContext();
    ec.realStartTime = now;
    ec.endOffset = duration;

    foreach(i; 0..10000)
    {
        ec.logs.put(LogEntry(
            duration, 10, "too long")
        );
    }

    JSONValue json;
    auto serializer = JSONSerializer!(DelegateWriter)((string msg) { json = parseJSON(msg); });
    assertThrown!RangeError(serializer(ec));
}
