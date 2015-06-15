DMD=/usr/bin/env dmd
RELEASE_DFLAGS=-O -w -g
LIB_DFLAGS=-lib
TEST_DFLAGS=-main -unittest -w -g
INCLUDES=-Isrc/

BUILD=builds/
SRCS=src/logdefer/*.d src/logdefer/serializer/*.d src/logdefer/writer/*.d
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
	simple \
	basicfile \
	concurrent \
	fileroller

simple: lib
	$(DMD) -of$(BUILD)simple $(INCLUDES) $(RELEASE_DFLAGS) examples/simple.d $(LIB)

basicfile: lib
	$(DMD) -of$(BUILD)basicfile $(INCLUDES) $(RELEASE_DFLAGS) examples/basicfile.d $(LIB)

concurrent: lib
	$(DMD) -of$(BUILD)concurrent $(INCLUDES) $(RELEASE_DFLAGS) examples/concurrent.d $(LIB)

fileroller: lib
	$(DMD) -of$(BUILD)fileroller $(INCLUDES) $(RELEASE_DFLAGS) examples/fileroller.d $(LIB)

clean:
	rm -r $(BUILD)
