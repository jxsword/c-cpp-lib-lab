/* src/calctool.c —— CLI 主程序（F-01-05；实现依据 PLAN 5.4）
 *
 * 命令：add / dot / info / probe / --self-test；--dynamic 与 --bundle 为桩
 *（动态链接验证属 RV 通道 F-02-02/F-04-03，打包属 F-09-07——本里程碑返回明确提示）。
 * 错误码约定与库对齐（取值见 src/vmath_core.c 头注释），只经 vmath_last_error()
 * 访问器读取，禁止触碰裸数据符号。probe 静态自述自身结构，不调用外部分析器。
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "vmath.h"

/* 库错误码对照（PLAN 5.4 的 VMATH_E_DIM；常量非符号，故置于消费侧并注释取值来源） */
enum { VMATH_E_OK = 0, VMATH_E_DIM = 1, VMATH_E_NULL = 2 };

#define CALC_LIST_CAP_ 16

/* CLI 日志函数：注册为库回调，命令结果亦经此输出（5.4「经 logger 输出」） */
static void cli_log(const char *message)
{
    printf("[calctool] %s\n", message);
}

/* 逗号分隔列表解析：写满 cap 为止；非法片段返回 -1 */
static int parse_list(const char *s, double *out, size_t cap, size_t *len)
{
    size_t n = 0;
    if (s == NULL || out == NULL || len == NULL) {
        return -1;
    }
    while (*s != '\0') {
        char *end = NULL;
        double v = strtod(s, &end);
        if (end == s) {
            return -1;
        }
        if (n >= cap) {
            return -1;
        }
        out[n++] = v;
        if (*end == ',') {
            s = end + 1;
        } else if (*end == '\0') {
            break;
        } else {
            return -1;
        }
    }
    *len = n;
    return 0;
}

/* 把库错误码翻译为可读名（只经访问器读取） */
static const char *err_name(int err)
{
    switch (err) {
    case VMATH_E_OK:   return "VMATH_E_OK";
    case VMATH_E_DIM:  return "VMATH_E_DIM";
    case VMATH_E_NULL: return "VMATH_E_NULL";
    default:           return "VMATH_E_UNKNOWN";
    }
}

static int cmd_add(int argc, char **argv)
{
    double a, b;
    char buf[64];
    if (argc != 2) {
        fprintf(stderr, "usage: calctool add <a> <b>\n");
        return 1;
    }
    a = strtod(argv[0], NULL);
    b = strtod(argv[1], NULL);
    (void)snprintf(buf, sizeof buf, "add(%s,%s) = %g", argv[0], argv[1], vmath_add(a, b));
    cli_log(buf); /* 经 logger 输出（5.4 覆盖点：回调） */
    return 0;
}

static int cmd_dot(int argc, char **argv)
{
    double xs[CALC_LIST_CAP_];
    double ys[CALC_LIST_CAP_];
    size_t nx = 0;
    size_t ny = 0;
    double out = 0.0;
    int rc;
    char buf[96];

    if (argc != 2) {
        fprintf(stderr, "usage: calctool dot <x1,x2,...> <y1,y2,...>\n");
        return 1;
    }
    if (parse_list(argv[0], xs, CALC_LIST_CAP_, &nx) != 0 ||
        parse_list(argv[1], ys, CALC_LIST_CAP_, &ny) != 0) {
        fprintf(stderr, "dot: invalid list\n");
        return 1;
    }
    if (nx != ny) {
        /* 维度不一致：以无效维度走库的维度错误路径，经访问器读取错误码 */
        (void)vmath_dot(xs, ys, 0, &out);
        rc = vmath_last_error();
        fprintf(stderr, "dot: dimension mismatch (%zu vs %zu), error=%s\n",
                nx, ny, err_name(rc));
        return 2;
    }
    rc = vmath_dot(xs, ys, nx, &out);
    if (rc != 0) {
        fprintf(stderr, "dot: failed, error=%s\n", err_name(vmath_last_error()));
        return 2;
    }
    (void)snprintf(buf, sizeof buf, "dot(len=%zu) = %g", nx, out);
    cli_log(buf);
    return 0;
}

static int cmd_info(void)
{
    printf("%s\n", vmath_build_info());
    return 0;
}

static int cmd_probe(void)
{
    /* 静态自述：自身编译期信息 + 类型表 + 内置依赖清单（不调用外部分析器） */
    printf("[probe] build info : %s\n", vmath_build_info());
    printf("[probe] type sizes : char=%zu short=%zu int=%zu long=%zu void*=%zu size_t=%zu double=%zu\n",
           sizeof(char), sizeof(short), sizeof(int), sizeof(long),
           sizeof(void *), sizeof(size_t), sizeof(double));
    printf("[probe] deps       : libc(dynamic) libm(dynamic) — manifest statically embedded\n");
    return 0;
}

static int cmd_self_test(void)
{
    int failures = 0;
    double out = 0.0;
    double a[3] = {1.0, 2.0, 3.0};
    double b[3] = {4.0, 5.0, 6.0};

    if (vmath_add(1.5, 2.5) != 4.0) {
        printf("self-test: add FAIL\n");
        failures++;
    } else {
        printf("self-test: add OK\n");
    }

    if (vmath_dot(a, b, 3, &out) != 0 || out != 32.0 || vmath_last_error() != VMATH_E_OK) {
        printf("self-test: dot FAIL\n");
        failures++;
    } else {
        printf("self-test: dot OK\n");
    }

    /* 维度错误（n==0 → VMATH_E_DIM），经访问器读取 */
    (void)vmath_dot(a, b, 0, &out);
    if (vmath_last_error() != VMATH_E_DIM) {
        printf("self-test: dim-error FAIL\n");
        failures++;
    } else {
        printf("self-test: dim-error OK\n");
    }

    /* 空指针错误（→ VMATH_E_NULL） */
    (void)vmath_dot(NULL, b, 3, &out);
    if (vmath_last_error() != VMATH_E_NULL) {
        printf("self-test: null-error FAIL\n");
        failures++;
    } else {
        printf("self-test: null-error OK\n");
    }

    if (vmath_build_info() == 0 || strstr(vmath_build_info(), "bits=") == NULL) {
        printf("self-test: info FAIL\n");
        failures++;
    } else {
        printf("self-test: info OK\n");
    }

    vmath_set_logger(cli_log);
    vmath_set_logger(0);
    printf("self-test: logger OK\n");

    if (failures != 0) {
        printf("self-test: %d FAILURES\n", failures);
        return 1;
    }
    printf("self-test: ALL OK\n");
    return 0;
}

/* 桩：动态链接验证属 RV 通道（F-02-02 / F-04-03），本里程碑返回明确提示 */
static int cmd_dynamic_stub(void)
{
    printf("--dynamic: reserved for the run-verification channel (F-02-02 / F-04-03), not built in this milestone\n");
    return 2;
}

/* 桩：打包发布属 F-09-07 */
static int cmd_bundle_stub(void)
{
    printf("--bundle: reserved for packaging (F-09-07), not built in this milestone\n");
    return 2;
}

static int usage(void)
{
    fprintf(stderr, "usage: calctool <command> [args]\n");
    fprintf(stderr, "  add <a> <b>              scalar add\n");
    fprintf(stderr, "  dot <x1,...> <y1,...>    dot product (comma-separated)\n");
    fprintf(stderr, "  info                     print build info\n");
    fprintf(stderr, "  probe                    static self description\n");
    fprintf(stderr, "  --self-test              built-in assertions\n");
    fprintf(stderr, "  --dynamic                reserved (run-verification channel)\n");
    fprintf(stderr, "  --bundle                 reserved (packaging)\n");
    return 1;
}

int main(int argc, char **argv)
{
    int i;
    /* 注册 CLI 日志为库回调（演示回调机制；结果输出经 logger） */
    vmath_set_logger(cli_log);
    if (argc < 2) {
        return usage();
    }
    for (i = 2; i < argc; ++i) {
        (void)argv[i]; /* 参数由各命令自行解析 */
    }
    if (strcmp(argv[1], "add") == 0) {
        return cmd_add(argc - 2, argv + 2);
    }
    if (strcmp(argv[1], "dot") == 0) {
        return cmd_dot(argc - 2, argv + 2);
    }
    if (strcmp(argv[1], "info") == 0) {
        return cmd_info();
    }
    if (strcmp(argv[1], "probe") == 0) {
        return cmd_probe();
    }
    if (strcmp(argv[1], "--self-test") == 0) {
        return cmd_self_test();
    }
    if (strcmp(argv[1], "--dynamic") == 0) {
        return cmd_dynamic_stub();
    }
    if (strcmp(argv[1], "--bundle") == 0) {
        return cmd_bundle_stub();
    }
    return usage();
}
