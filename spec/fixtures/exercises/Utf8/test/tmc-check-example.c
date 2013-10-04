
#include "tmc-check.h"
#include <stdio.h>

START_TEST(test_foo)
{
    const unsigned char valid_utf8_string[] = {
        0x6d, 0xc3, 0xa4, 0xc3, 0xa4, 0x20,
        0x6d, 0xc3, 0xb6, 0xc3, 0xb6, 0x20,
        0x6d, 0xc3, 0xbc, 0xc3, 0xbc, 0x0a,
        0
    };
    fail_unless(1+1 == 3, valid_utf8_string);
}
END_TEST

int main(int argc, const char *argv[])
{
    Suite *s  = tmc_suite_create("my-suite", "suitePoints");
    tmc_register_test(s, test_foo, "point1");
    return tmc_run_tests(argc, argv, s);
}
