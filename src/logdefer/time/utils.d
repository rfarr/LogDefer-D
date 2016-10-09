module logdefer.time.utils;

import logdefer.time.duration : Seconds, Millis, Micros, Nanos;
import unixtime : UnixTime, UnixTimeHiRes;

pure UnixTimeHiRes toUnixTimeHiRes(ADuration)(const ADuration aDuration)
{
    static if (is(ADuration == Seconds))
    {
        return UnixTimeHiRes(aDuration.value, 0);
    }
    else static if (is(ADuration == Millis))
    {
        return UnixTimeHiRes(aDuration.value / 1_000, aDuration.value % 1_000 * 1_000_000);
    }
    else static if (is(ADuration == Micros))
    {
        return UnixTimeHiRes(aDuration.value / 1_000_000, aDuration.value % 1_000_000 * 1_000);
    }
    else static if (is(ADuration == Nanos))
    {
        return UnixTimeHiRes(aDuration.value / 1_000_000_000, aDuration.value % 1_000_000_000);
    }
    else
    {
        static assert(false, "Unknown duration");
    }
}

pure UnixTime toUnixTime(ADuration)(const ADuration aDuration)
{
    static if (is(ADuration == Seconds))
    {
        return UnixTime(aDuration.value);
    }
    else static if (is(ADuration == Millis))
    {
        return UnixTime(aDuration.value / 1_000);
    }
    else static if (is(ADuration == Micros))
    {
        return UnixTime(aDuration.value / 1_000_000);
    }
    else static if (is(ADuration == Nanos))
    {
        return UnixTime(aDuration.value / 1_000_000_000);
    }
    else
    {
        static assert(false, "Unknown duration");
    }
}

pure ADuration toDuration(ADuration)(const UnixTimeHiRes start, const UnixTimeHiRes end)
{
    return (end - start).toDuration!ADuration();
}

pure ADuration toDuration(ADuration)(const UnixTime start, const UnixTime end)
{
    return (end - start).toDuration!ADuration();
}

pure ADuration toDuration(ADuration)(const UnixTimeHiRes timestamp)
{
    static if (is(ADuration == Seconds))
    {
        return Seconds(timestamp.seconds);
    }
    else static if (is(ADuration == Millis))
    {
        return Millis(timestamp.seconds * 1_000 + timestamp.nanos / 1_000_000);
    }
    else static if (is(ADuration == Micros))
    {
        return Micros(timestamp.seconds * 1_000_000 + timestamp.nanos / 1_000);
    }
    else static if (is(ADuration == Nanos))
    {
        return Nanos(timestamp.seconds * 1_000_000_000 + timestamp.nanos);
    }
    else
    {
        static assert(false, "Unknown duration");
    }
}

pure ADuration toDuration(ADuration)(const UnixTime timestamp)
{
    static if (is(ADuration == Seconds))
    {
        return Seconds(timestamp.seconds);
    }
    else static if (is(ADuration == Millis))
    {
        return Millis(timestamp.seconds * 1_000);
    }
    else static if (is(ADuration == Micros))
    {
        return Micros(timestamp.seconds * 1_000_000);
    }
    else static if (is(ADuration == Nanos))
    {
        return Nanos(timestamp.seconds * 1_000_000_000);
    }
    else
    {
        static assert(false, "Unknown duration");
    }
}

version(unittest)
{
    import std.stdio : writeln;
}

unittest
{
    writeln("[UnitTest utils] - toUnixTimeHiRes]");

    // Nanos
    assert(Nanos(0).toUnixTimeHiRes() == UnixTimeHiRes(0, 0));
    assert(Nanos(1).toUnixTimeHiRes() == UnixTimeHiRes(0, 1));
    assert(Nanos(999_999_999).toUnixTimeHiRes() == UnixTimeHiRes(0, 999_999_999));
    assert(Nanos(1_000_000_000).toUnixTimeHiRes() == UnixTimeHiRes(1, 0));
    assert(Nanos(1_000_000_001).toUnixTimeHiRes() == UnixTimeHiRes(1, 1));
    assert(Nanos(79_231_938_229).toUnixTimeHiRes() == UnixTimeHiRes(79, 231_938_229));

    assert(Nanos(-1).toUnixTimeHiRes() == UnixTimeHiRes(0, -1));
    assert(Nanos(-999_999_999).toUnixTimeHiRes() == UnixTimeHiRes(0, -999_999_999));
    assert(Nanos(-1_000_000_000).toUnixTimeHiRes() == UnixTimeHiRes(-1, 0));
    assert(Nanos(-1_000_000_001).toUnixTimeHiRes() == UnixTimeHiRes(-1, -1));
    assert(Nanos(-79_231_938_229).toUnixTimeHiRes() == UnixTimeHiRes(-79, -231_938_229));

    // Micros
    assert(Micros(0).toUnixTimeHiRes() == UnixTimeHiRes(0, 0));
    assert(Micros(1).toUnixTimeHiRes() == UnixTimeHiRes(0, 1_000));
    assert(Micros(999_999).toUnixTimeHiRes() == UnixTimeHiRes(0, 999_999_000));
    assert(Micros(1_000_000).toUnixTimeHiRes() == UnixTimeHiRes(1, 0));
    assert(Micros(1_000_001).toUnixTimeHiRes() == UnixTimeHiRes(1, 1_000));
    assert(Micros(79_231_938).toUnixTimeHiRes() == UnixTimeHiRes(79, 231_938_000));

    assert(Micros(-1).toUnixTimeHiRes() == UnixTimeHiRes(0, -1_000));
    assert(Micros(-999_999).toUnixTimeHiRes() == UnixTimeHiRes(0, -999_999_000));
    assert(Micros(-1_000_000).toUnixTimeHiRes() == UnixTimeHiRes(-1, 0));
    assert(Micros(-1_000_001).toUnixTimeHiRes() == UnixTimeHiRes(-1, -1_000));
    assert(Micros(-79_231_938).toUnixTimeHiRes() == UnixTimeHiRes(-79, -231_938_000));

    // Millis
    assert(Millis(0).toUnixTimeHiRes() == UnixTimeHiRes(0, 0));
    assert(Millis(1).toUnixTimeHiRes() == UnixTimeHiRes(0, 1_000_000));
    assert(Millis(999).toUnixTimeHiRes() == UnixTimeHiRes(0, 999_000_000));
    assert(Millis(1_000).toUnixTimeHiRes() == UnixTimeHiRes(1, 0));
    assert(Millis(1_001).toUnixTimeHiRes() == UnixTimeHiRes(1, 1_000_000));
    assert(Millis(79_231).toUnixTimeHiRes() == UnixTimeHiRes(79, 231_000_000));

    assert(Millis(-1).toUnixTimeHiRes() == UnixTimeHiRes(0, -1_000_000));
    assert(Millis(-999).toUnixTimeHiRes() == UnixTimeHiRes(0, -999_000_000));
    assert(Millis(-1_000).toUnixTimeHiRes() == UnixTimeHiRes(-1, 0));
    assert(Millis(-1_001).toUnixTimeHiRes() == UnixTimeHiRes(-1, -1_000_000));
    assert(Millis(-79_231).toUnixTimeHiRes() == UnixTimeHiRes(-79, -231_000_000));

    // Seconds
    assert(Seconds(0).toUnixTimeHiRes() == UnixTimeHiRes(0, 0));
    assert(Seconds(1).toUnixTimeHiRes() == UnixTimeHiRes(1, 0));
    assert(Seconds(999).toUnixTimeHiRes() == UnixTimeHiRes(999, 0));
    assert(Seconds(-1).toUnixTimeHiRes() == UnixTimeHiRes(-1, 0));
    assert(Seconds(-999).toUnixTimeHiRes() == UnixTimeHiRes(-999, 0));
}

unittest
{
    writeln("[UnitTest utils] - toUnixTime");

    // Nanos
    assert(Nanos(0).toUnixTime() == UnixTime(0));
    assert(Nanos(1).toUnixTime() == UnixTime(0));
    assert(Nanos(999_999_999).toUnixTime() == UnixTime(0));
    assert(Nanos(1_000_000_000).toUnixTime() == UnixTime(1));
    assert(Nanos(1_000_000_001).toUnixTime() == UnixTime(1));
    assert(Nanos(79_231_938_229).toUnixTime() == UnixTime(79));

    assert(Nanos(-1).toUnixTime() == UnixTime(0));
    assert(Nanos(-999_999_999).toUnixTime() == UnixTime(0));
    assert(Nanos(-1_000_000_000).toUnixTime() == UnixTime(-1));
    assert(Nanos(-1_000_000_001).toUnixTime() == UnixTime(-1));
    assert(Nanos(-79_231_938_229).toUnixTime() == UnixTime(-79));

    // Micros
    assert(Micros(0).toUnixTime() == UnixTime(0));
    assert(Micros(1).toUnixTime() == UnixTime(0));
    assert(Micros(999_999).toUnixTime() == UnixTime(0));
    assert(Micros(1_000_000).toUnixTime() == UnixTime(1));
    assert(Micros(1_000_001).toUnixTime() == UnixTime(1));
    assert(Micros(79_231_938).toUnixTime() == UnixTime(79));

    assert(Micros(-1).toUnixTime() == UnixTime(0));
    assert(Micros(-999_999).toUnixTime() == UnixTime(0));
    assert(Micros(-1_000_000).toUnixTime() == UnixTime(-1));
    assert(Micros(-1_000_001).toUnixTime() == UnixTime(-1));
    assert(Micros(-79_231_938).toUnixTime() == UnixTime(-79));

    // Millis
    assert(Millis(0).toUnixTime() == UnixTime(0));
    assert(Millis(1).toUnixTime() == UnixTime(0));
    assert(Millis(999).toUnixTime() == UnixTime(0));
    assert(Millis(1_000).toUnixTime() == UnixTime(1));
    assert(Millis(1_001).toUnixTime() == UnixTime(1));
    assert(Millis(79_231).toUnixTime() == UnixTime(79));

    assert(Millis(-1).toUnixTime() == UnixTime(0));
    assert(Millis(-999).toUnixTime() == UnixTime(0));
    assert(Millis(-1_000).toUnixTime() == UnixTime(-1));
    assert(Millis(-1_001).toUnixTime() == UnixTime(-1));
    assert(Millis(-79_231).toUnixTime() == UnixTime(-79));

    // Seconds
    assert(Seconds(0).toUnixTime() == UnixTime(0));
    assert(Seconds(1).toUnixTime() == UnixTime(1));
    assert(Seconds(999).toUnixTime() == UnixTime(999));

    assert(Seconds(-1).toUnixTime() == UnixTime(-1));
    assert(Seconds(-999).toUnixTime() == UnixTime(-999));
}
