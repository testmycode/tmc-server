CHECK_CFLAGS=$(shell pkg-config --cflags check)
CHECK_LDFLAGS=$(shell pkg-config --libs check)
SRC_FILES=tmc-check-example.c tmc-check.c ../src/lib.c

all: test

test: $(SRC_FILES)
	gcc $(CHECK_CFLAGS) -Wall -o $@ $(SRC_FILES) $(CHECK_LDFLAGS)

clean:
	rm -f test tmc_available_points.txt tmc_test_results.xml valgrind.log

run: test
	./test --print-available-points
	./test

get-points:
	./test --print-available-points