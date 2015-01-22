
#include "tmc-check.h"
#include <stdio.h>

START_TEST(test_foo)
{
    const unsigned char horrible_mess[] = {
        116, 114, 111, 108, 7, 27, 228, 228, 7, 7, 108, 111, 108, 0
    };
    fail_unless(1+1 == 3, horrible_mess);
}
END_TEST

int main(int argc, const char *argv[])
{
    Suite *s = tmc_suite_create("my-suite", "suitePoints");
    tmc_register_test(s, test_foo, "point1");
    return tmc_run_tests(argc, argv, s);
}
