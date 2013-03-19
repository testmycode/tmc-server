
#include "tmc-check.h"
#include <stdio.h>
#include "../src/lib.h"

START_TEST(test_foo)
{
    fail_unless(1+1 == 2, "that's weird");
}
END_TEST

START_TEST(test_bar)
{
    fail_unless(1+1 == 123123, "Well this should really fail - 1+1 should not be 123123!");
}
END_TEST

START_TEST(test_lib_function)
{
	fail_unless(returns_zero() == 0, "The library function returns_zero should do what is says.");
}
END_TEST

int main(int argc, const char *argv[])
{
    // Suite *s = suite_create("test-tmc-check");
    Suite *s  = tmc_suite_create("test-tmc-check", "2.5 2.6 2.7");
    tmc_register_test(s, test_foo, "1.1 1.2");
    tmc_register_test(s, test_bar, "1.2");
    tmc_register_test(s, test_lib_function, "1.3ftio");
    return tmc_run_tests(argc, argv, s);
}
