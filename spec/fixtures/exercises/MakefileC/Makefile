MAIN_DIR = src
TEST_DIR = test

.PHONY: main test 

all: main test

main: 
	$(MAKE) -C $(MAIN_DIR)

test:
	$(MAKE) -C $(TEST_DIR)

clean:
	rm -f tmc_available_points.txt tmc_test_results.xml valgrind.log
	$(MAKE) -C $(MAIN_DIR) clean
	$(MAKE) -C $(TEST_DIR) clean

run-main:
	$(MAKE) -C $(MAIN_DIR) run

run-test:
	$(MAKE) -C $(TEST_DIR) run
