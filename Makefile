DMD=/usr/bin/env dmd
RELEASE_DFLAGS=-O -w -lib -g
TEST_DFLAGS=-main -unittest -w -g
INCLUDES=-Isrc/

SRCS=src/logdefer/logger.d src/logdefer/serializer/json.d

.PHONY: all test clean

all:
	$(DMD) -ofbuilds/logdeferd.a $(INCLUDES) $(RELEASE_DFLAGS) $(SRCS)

test:
	$(DMD) -ofbuilds/logdeferd_test $(INCLUDES) $(TEST_DFLAGS) $(SRCS)
	builds/logdeferd_test

clean:
	rm -r builds
