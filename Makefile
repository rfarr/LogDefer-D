DMD=/usr/bin/env dmd
RELEASE_DFLAGS=-O -w -g -inline -release
LIB_DFLAGS=-lib
TEST_DFLAGS=-main -unittest -w -g
INCLUDES=-Isrc/

BUILD=builds/
SRCS=src/logdefer/*.d src/logdefer/serializer/*.d
EXAMPLES=examples/*.d

LIB_NAME=logdeferd
LIB=$(BUILD)$(LIB_NAME).a

TEST_NAME=logdefer_unittest
TEST=$(BUILD)$(TEST_NAME)

.PHONY: clean

all: test examples

lib:
	$(DMD) -of$(LIB) $(INCLUDES) $(LIB_DFLAGS) $(RELEASE_DFLAGS) $(SRCS)

test:
	$(DMD) -of$(TEST) $(INCLUDES) $(TEST_DFLAGS) $(SRCS)
	$(TEST)

examples: \
	basic \
	perf

basic: lib
	$(DMD) -of$(BUILD)basic $(INCLUDES) $(RELEASE_DFLAGS) examples/basic.d $(LIB)

perf: lib
	$(DMD) -of$(BUILD)perf $(INCLUDES) $(RELEASE_DFLAGS) examples/perf.d $(LIB)

clean:
	rm -rf $(BUILD)
