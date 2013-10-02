TMC_CHECK_CFLAGS=$(shell pkg-config --cflags tmccheck)
TMC_CHECK_LDFLAGS=$(shell pkg-config --libs tmccheck)
SRC_FILES=tmc-check-example.c

all: test

test: $(SRC_FILES)
	gcc $(TMC_CHECK_CFLAGS) -Wall -o $@ $(SRC_FILES) $(TMC_CHECK_LDFLAGS)

clean:
	rm -f test tmc_available_points.txt tmc_test_results.xml valgrind.log

run: test
	./test --print-available-points
	./test

get-points:
	./test --print-available-points
