CHECK_CFLAGS=$(shell pkg-config --cflags check)
CHECK_LDFLAGS=$(shell pkg-config --libs check)
SRC_FILES=main.c lib.c

all: main

main: $(SRC_FILES)
	gcc -Wall -o $@ $(SRC_FILES) $(CHECK_LDFLAGS)

clean:
	rm -f main

run: main
	# Running our main function from file main.c
	./main
