
#include "tmc-check.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <ctype.h>

typedef struct SuitePoints
{
    Suite *s;
    const char *s_name;
    const char *points;
    struct SuitePoints *next;
} SuitePoints;

typedef struct PointsAssoc
{
    TCase *tc;
    const char *tc_name;
    const char *points;
    struct PointsAssoc *next;
} PointsAssoc;

typedef struct PointsList
{
    char *point;
    struct PointsList *next;
} PointsList;

static PointsAssoc *points_assocs = NULL;
static SuitePoints *suite_points = NULL;
static PointsList *all_points = NULL;

static void parse_points(const char *points, PointsList **target_list);
static void add_to_point_set(const char *point, ssize_t len, PointsList **target_list);
static int points_list_contains(const PointsList *list, const char *point, ssize_t len);

void tmc_set_tcase_points(TCase *tc, const char *tc_name, const char *points)
{
    PointsAssoc *pa = (PointsAssoc*)malloc(sizeof(PointsAssoc));
    pa->tc = tc;
    pa->tc_name = tc_name;
    pa->points = points;
    pa->next = points_assocs;
    points_assocs = pa;

    parse_points(points, &all_points);
}

void _tmc_register_test(Suite *s, TFun tf, const char *fname, const char *points)
{
    TCase *tc = tcase_create(fname);
    tmc_set_tcase_points(tc, fname, points);
    _tcase_add_test(tc, tf, fname, 0, 0, 0, 1);
    suite_add_tcase(s, tc);
}

void tmc_set_suite_points(Suite *s, const char *s_name, const char *points)
{
    SuitePoints *sp = (SuitePoints*) malloc(sizeof(SuitePoints));
    sp->s = s;
    sp->points = points;
    sp->s_name = s_name;
    sp->next = suite_points;
    suite_points = sp;

    parse_points(points, &all_points);
}

Suite* tmc_suite_create(const char *name, const char *points)
{
    Suite *s = suite_create(name);
    tmc_set_suite_points(s, name, points);
    return s;
}

int tmc_run_tests(int argc, const char **argv, Suite *s)
{
    int i;
    for (i = 1; i < argc; ++i) {
        if (strcmp(argv[i], "--print-available-points") == 0) {
            return tmc_print_available_points(stdout, '\n');
        }
    }

    FILE *points_file = fopen("tmc_available_points.txt", "wb");
    if (tmc_print_suite_points(points_file) != 0) {
        fclose(points_file);
        return EXIT_FAILURE;
    }
    if (tmc_print_test_points(points_file) != 0) {
        fclose(points_file);
        return EXIT_FAILURE;
    }
    fclose(points_file);

    SRunner *sr = srunner_create(s);
    srunner_set_xml(sr, "tmc_test_results.xml");
    srunner_run_all(sr, CK_VERBOSE);
    srunner_free(sr);

    return EXIT_SUCCESS;
}

int tmc_print_available_points(FILE *f, char delimiter)
{
    const PointsList *pl = all_points;
    while (pl != NULL) {
        fputs(pl->point, f);
        fputc(delimiter, f);
        pl = pl->next;
    }
    fflush(f);
    return 0;
}

int tmc_print_test_points(FILE *f)
{
    const PointsAssoc *pa = points_assocs;
    while (pa != NULL) {
        fprintf(f, "[test] %s %s\n", pa->tc_name, pa->points);
        pa = pa->next;
    }
    fflush(f);
    return 0;
}

int tmc_print_suite_points(FILE *f)
{
    const SuitePoints *sp = suite_points;
    while (sp != NULL) {
        fprintf(f, "[suite] %s %s\n", sp->s_name, sp->points);
        sp = sp->next;
    }
    fflush(f);
    return 0;
}

static void parse_points(const char *points, PointsList **target_list)
{
    const char *p = points;
    const char *q = p;
    while (*q != '\0') {
        if (isspace(*q)) {
            const ssize_t len = q - p;

            if (!isspace(*p)) {
                add_to_point_set(p, len, target_list);
            }

            p = q + 1;
            q = p;
        } else {
            q++;
        }
    }

    if (!isspace(*p) && q > p) {
        const ssize_t len = q - p;
        add_to_point_set(p, len, target_list);
    }
}

static void add_to_point_set(const char *point, ssize_t len, PointsList **target_list)
{
    if (!points_list_contains(*target_list, point, len)) {
        PointsList *pl = (PointsList*)malloc(sizeof(PointsList));
        pl->point = malloc(len + 1);
        memcpy(pl->point, point, len);
        pl->point[len] = '\0';
        pl->next = *target_list;
        *target_list = pl;
    }
}

static int points_list_contains(const PointsList *list, const char *point, ssize_t len)
{
    const PointsList *pl = all_points;
    while (pl != NULL) {
        if (strncmp(pl->point, point, len) == 0) {
            return 1;
        }
        pl = pl->next;
    }
    return 0;
}

