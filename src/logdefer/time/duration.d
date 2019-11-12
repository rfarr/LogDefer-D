module logdefer.time.duration;


import core.checkedint : muls;
import std.conv : to;
import std.traits : isIntegral;


alias Nanos = Duration!(TimeUnit.NANOS);
alias Micros = Duration!(TimeUnit.MICROS);
alias Millis = Duration!(TimeUnit.MILLIS);
alias Seconds = Duration!(TimeUnit.SECONDS);

enum TimeUnit
{
    NANOS=1,
    MICROS=1_000,
    MILLIS=1_000_000,
    SECONDS=1_000_000_000
}

@safe
struct Duration(TimeUnit timeUnit)
{
    public:
        long value;
        static immutable TimeUnit units = timeUnit;
        static immutable string displayUnits = getDisplayUnits();

        @nogc
        nothrow this(long value)
        {
            this.value = value;
        }

        @nogc
        nothrow this(OtherDuration)(const OtherDuration otherDuration)
        {
            this.value = toDuration!(Duration!timeUnit)(otherDuration).value;
        }

        @nogc
        nothrow ToDuration toDuration(ToDuration)() const
        {
            return toDuration!(ToDuration)(this);
        }

        @nogc
        nothrow double toUnits(ToUnits)() const
        {
            return toUnits!(ToUnits)(this);
        }

        nothrow string toString(ToUnits = TimeUnit)() const
        {
            //XXX
            return to!string(value) ~ " " ~ displayUnits;
        }

        @nogc
        nothrow bool opEquals(OtherDuration)(const OtherDuration otherDuration)
        {
            return opEquals(otherDuration);
        }

        @nogc
        nothrow bool opEquals(OtherDuration)(const ref OtherDuration otherDuration)
        {
            return toDuration!Nanos(this).value == toDuration!Nanos(otherDuration).value;
        }

        @nogc
        nothrow void opAssign(OtherDuration)(const OtherDuration otherDuration)
        {
            this.value = toDuration!(Duration!timeUnit)(otherDuration).value;
        }

        @nogc
        pure nothrow int opCmp(OtherDuration)(const OtherDuration other) const
        {
            return opCmp(other);
        }

        @nogc
        pure nothrow int opCmp(OtherDuration)(const ref OtherDuration other) const
        {
            static if (isIntegral!OtherDuration)
            {
                return this.value > other ? 1
                    : this.value < other ? -1
                    : 0;
            }
            else
            {
                long thisNanos = toDuration!Nanos(this).value;
                long otherNanos = toDuration!Nanos(other).value;

                return thisNanos > otherNanos ? 1
                    : thisNanos < otherNanos ? -1
                    : 0;
            }
        }

        Duration!timeUnit opBinary(string op)(long operand) const
        if (op == "*")
        {
            bool overflow;
            auto value = muls(this.value, operand, overflow);

            if (overflow)
            {
                throw new Exception("Overflow");
            }

            return Duration!timeUnit(value);
        }

        Duration!timeUnit opBinary(string op)(long operand) const
        if (op == "/")
        {
            if (operand == 0)
            {
                throw new Exception("Divide by 0");
            }

            return Duration!timeUnit(this.value / operand);
        }

        @nogc
        pure static nothrow ToDuration toDuration(ToDuration, FromDuration)(const FromDuration fromDuration)
        {
            static if (ToDuration.units > FromDuration.units)
            {
                return ToDuration(fromDuration.value / (ToDuration.units / FromDuration.units));
            }
            else static if (ToDuration.units < FromDuration.units)
            {
                return ToDuration(fromDuration.value * (FromDuration.units / ToDuration.units));
            }
            else
            {
                return ToDuration(fromDuration.value);
            }
        }

        @nogc
        pure static nothrow double toUnits(ToUnits, FromDuration)(const FromDuration fromDuration)
        {
            static if (ToUnits.units > FromDuration.units)
            {
                return cast(double)(fromDuration.value) / (ToUnits.units / FromDuration.units);
            }
            else static if (ToUnits.units < FromDuration.units)
            {
                return cast(double)(fromDuration.value) * (FromDuration.units / ToUnits.units);
            }
            else
            {
                return cast(double)fromDuration.value;
            }
        }

    private:
        static string getDisplayUnits()
        {
            final switch(timeUnit)
            {
                case TimeUnit.SECONDS: return "seconds";
                case TimeUnit.MILLIS: return "milliseconds";
                case TimeUnit.MICROS: return "microseconds";
                case TimeUnit.NANOS: return "nanoseconds";
            }
        }
}


version(unittest)
{
    import std.stdio : writeln;
}

unittest
{
    writeln("[UnitTest toDuration Seconds]");

    Nanos nanos = Seconds(1);
    Micros micros = Seconds(1);
    Millis millis = Seconds(1);
    Seconds seconds = Seconds(1);

    assert(nanos == Nanos(1_000_000_000));
    assert(micros == Micros(1_000_000));
    assert(millis == Millis(1_000));
    assert(seconds == Seconds(1));
}

unittest
{
    writeln("[UnitTest toDuration Millis]");

    Nanos nanos = Millis(1);
    Micros micros = Millis(1);
    Millis millis = Millis(1);
    Seconds seconds = Millis(1);

    assert(nanos == Nanos(1_000_000));
    assert(micros == Micros(1_000));
    assert(millis == Millis(1));
    assert(seconds == Seconds(0));
}

unittest
{
    writeln("[UnitTest toDuration Micros]");

    Nanos nanos = Micros(1);
    Micros micros = Micros(1);
    Millis millis = Micros(1);
    Seconds seconds = Micros(1);

    assert(nanos == Nanos(1_000));
    assert(micros == Micros(1));
    assert(millis == Millis(0));
    assert(seconds == Seconds(0));
}

unittest
{
    writeln("[UnitTest toDuration Nanos]");

    Nanos nanos = Nanos(1);
    Micros micros = Nanos(1);
    Millis millis = Nanos(1);
    Seconds seconds = Nanos(1);

    assert(nanos == Nanos(1));
    assert(micros == Micros(0));
    assert(millis == Millis(0));
    assert(seconds == Seconds(0));
}

unittest
{
    writeln("[UnitTest toUnits Seconds]");

    auto nanos = Seconds(1).toUnits!Nanos;
    auto micros = Seconds(1).toUnits!Micros;
    auto millis = Seconds(1).toUnits!Millis;
    auto seconds = Seconds(1).toUnits!Seconds;

    assert(nanos == 1_000_000_000f);
    assert(micros == 1_000_000f);
    assert(millis == 1_000f);
    assert(seconds == 1f);
}

unittest
{
    writeln("[UnitTest toUnits Millis]");

    auto nanos = Millis(1).toUnits!Nanos;
    auto micros = Millis(1).toUnits!Micros;
    auto millis = Millis(1).toUnits!Millis;
    auto seconds = Millis(1).toUnits!Seconds;

    assert(nanos == 1_000_000f);
    assert(micros == 1_000f);
    assert(millis == 1f);
    assert(seconds == 0.001f);
}

unittest
{
    writeln("[UnitTest toUnits Micros]");

    auto nanos = Micros(1).toUnits!Nanos;
    auto micros = Micros(1).toUnits!Micros;
    auto millis = Micros(1).toUnits!Millis;
    auto seconds = Micros(1).toUnits!Seconds;

    assert(nanos == 1_000f);
    assert(micros == 1f);
    assert(millis == 0.001f);
    assert(seconds == 0.000001f);
}

unittest
{
    writeln("[UnitTest toUnits Nanos]");

    auto nanos = Nanos(1).toUnits!Nanos;
    auto micros = Nanos(1).toUnits!Micros;
    auto millis = Nanos(1).toUnits!Millis;
    auto seconds = Nanos(1).toUnits!Seconds;

    assert(nanos == 1f);
    assert(micros == 0.001f);
    assert(millis == 0.000001f);
    assert(seconds == 0.000000001f);
}

unittest
{
    writeln("[UnitTest opAssign]");

    Nanos nanos;
    Micros micros;
    Millis millis;
    Seconds seconds;

    nanos = Micros(10);
    micros = Nanos(1_000);
    millis = Seconds(1);
    seconds = Millis(5_999);

    assert(nanos == Nanos(10_000));
    assert(micros == Micros(1));
    assert(millis == Millis(1_000));
    assert(seconds == Seconds(5));
}

unittest
{
    writeln("[UnitTest opCmp]");

    assert(Seconds(1) > Seconds(0));
    assert(Seconds(1) == Seconds(1));
    assert(Seconds(1) < Seconds(2));

    assert(Seconds(1) > Millis(999));
    assert(Seconds(1) == Millis(1_000));
    assert(Seconds(1) < Millis(1_001));

    assert(Seconds(1) > Micros(999_999));
    assert(Seconds(1) == Micros(1_000_000));
    assert(Seconds(1) < Micros(1_000_001));

    assert(Seconds(1) > Nanos(999_999_999));
    assert(Seconds(1) == Nanos(1_000_000_000));
    assert(Seconds(1) < Nanos(1_000_000_001));

    assert(Nanos(1) < Micros(1));
    assert(Nanos(1_000) == Micros(1));
    assert(Nanos(1_001) > Micros(1));
}

unittest
{
    writeln("[UnitTest Duration]");

    Seconds seconds = Seconds(100);
    Millis millis = Millis(100);
    Micros micros = Micros(100);
    Nanos nanos = Nanos(100);

    assert(seconds.units == TimeUnit.SECONDS);
    assert(seconds.toString() == "100 seconds");

    assert(millis.units == TimeUnit.MILLIS);
    assert(millis.toString() == "100 milliseconds");

    assert(micros.units == TimeUnit.MICROS);
    assert(micros.toString() == "100 microseconds");

    assert(nanos.units == TimeUnit.NANOS);
    assert(nanos.toString() == "100 nanoseconds");
}
