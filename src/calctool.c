/* src/calctool.c —— CLI 主程序（F-01-05 / F-02-02；实现依据 PLAN 5.4）
 *
 * 命令：add / dot / info / probe / --self-test / --dynamic；--bundle 为桩
 *（打包属 F-09-07——本里程碑返回明确提示）。
 * --dynamic 为 Unix 动态加载分支：**属运行验证（RV）通道（P5）**，仅在 RV step
 * 运行，分析脚本不得引用本分支（5.8.4 约束的是分析过程，不是 RV 功能）。
 * 错误码约定与库对齐（取值见 src/vmath_core.c 头注释），只经 vmath_last_error()
 * 访问器读取，禁止触碰裸数据符号。probe 静态自述自身结构，不调用外部分析器。
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#if defined(_WIN32)
#  include <windows.h>
#else
#  include <unistd.h>
#  include <dlfcn.h>
#endif

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

/* ---- RV 通道：Unix 动态加载（F-02-02） ------------------------------------
 * dlopen 绝对路径 → dlsym 按名取 6 个 API → 函数表结构体成员位置作为 ordinal
 * 的跨平台替代（成员顺序与 def/vmath.def 的 ordinal 1–6 一一对应）→ 调用 →
 * 卸载前 vmath_set_logger(NULL) 注销 → dlclose → 卸载后不持有库内地址。
 * 本分支只在 RV step 运行；分析脚本不得引用（5.8.4 / P5 边界）。
 */
typedef struct {
    double (*add)(double a, double b);                                /* ordinal 1 */
    int (*dot)(const double *a, const double *b, size_t n, double *out); /* ordinal 2 */
    void (*set_logger)(vmath_log_fn logger);                          /* ordinal 3 */
    void (*free_mem)(void *p);                                        /* ordinal 4 */
    const char *(*build_info)(void);                                  /* ordinal 5（def 中 NONAME，仅函数表可达） */
    int (*last_error)(void);                                          /* ordinal 6 */
} calc_api_table_;

/* 解析库绝对路径：默认取可执行文件同目录的 libvmath.so.1；
 * argv 提供的路径含 '/' 或以 .so 开头/结尾时优先采用（供 A4 传错路径测试） */
#if !defined(_WIN32)
static int dynamic_lib_path(int argc, char **argv, int *arg_base, char *path, size_t cap)
{
    char exe[4096];
    char *slash;
    ssize_t n;

    *arg_base = 2; /* 默认：argv[2] 起为子命令 */
    if (argc >= 3 && (strchr(argv[2], '/') != NULL ||
                      strncmp(argv[2], "libvmath.so", 11) == 0)) {
        if (strlen(argv[2]) >= cap) {
            return -1;
        }
        snprintf(path, cap, "%s", argv[2]);
        *arg_base = 3;
        return 0;
    }
    n = readlink("/proc/self/exe", exe, sizeof exe - 1);
    if (n <= 0) {
        return -1;
    }
    exe[n] = '\0';
    slash = strrchr(exe, '/');
    if (slash == NULL) {
        return -1;
    }
    *slash = '\0';
    {
        size_t dirlen = (size_t)(slash - exe);
        if (dirlen + sizeof "/libvmath.so.1" > cap) {
            return -1;
        }
        memcpy(path, exe, dirlen);
        memcpy(path + dirlen, "/libvmath.so.1", sizeof "/libvmath.so.1");
    }
    return 0;
}

#endif /* !_WIN32 */

/* ---- RV 通道：Windows 动态加载（F-04-03） ----
 * LoadLibrary 绝对路径；GetProcAddress 按名 6 API；MAKEINTRESOURCEA(5) 按
 * ordinal 取 vmath_build_info（.def @5 NONAME，按名必 NULL——A2 期望行为）；
 * FreeLibrary 前经函数表注销 logger；卸载后不持有库内地址。 */
#if defined(_WIN32)
static const char *err_name(int err);
static int win_lib_path(int argc, char **argv, int *arg_base, char *path, size_t cap)
{
    char exe[MAX_PATH];
    char *slash;
    DWORD n;

    *arg_base = 2;
    if (argc >= 3 && (strchr(argv[2], '\\') != NULL || strchr(argv[2], '/') != NULL)) {
        if (strlen(argv[2]) >= cap) {
            return -1;
        }
        snprintf(path, cap, "%s", argv[2]);
        *arg_base = 3;
        return 0;
    }
    n = GetModuleFileNameA(NULL, exe, MAX_PATH);
    if (n == 0 || n >= MAX_PATH) {
        return -1;
    }
    slash = strrchr(exe, '\\');
    if (slash == NULL) {
        return -1;
    }
    *slash = '\0';
    {
        size_t dirlen = (size_t)(slash - exe);
        if (dirlen + sizeof "\\vmath.dll" > cap) {
            return -1;
        }
        memcpy(path, exe, dirlen);
        memcpy(path + dirlen, "\\vmath.dll", sizeof "\\vmath.dll");
    }
    return 0;
}

static int cmd_dynamic_win(int argc, char **argv)
{
    char path[MAX_PATH];
    HMODULE handle = NULL;
    calc_api_table_ api;
    int arg_base = 0;
    int rc = 0;
    char buf[128];

    if (win_lib_path(argc, argv, &arg_base, path, sizeof path) != 0) {
        fprintf(stderr, "--dynamic: cannot resolve library path\n");
        return 2;
    }
    if (arg_base >= argc) {
        fprintf(stderr, "usage: calctool --dynamic [libpath] <command> [args]\n");
        return 2;
    }
    handle = LoadLibraryA(path);
    if (handle == NULL) {
        fprintf(stderr, "--dynamic: cannot load '%s' (GetLastError=%lu)\n", path, (unsigned long)GetLastError());
        return 2;
    }
    /* 按名取 6 API（A1）；@5 NONAME 使按名取 build_info 必为 NULL（A2 期望） */
    api.add        = (double (*)(double, double))(void *)GetProcAddress(handle, "vmath_add");
    api.dot        = (int (*)(const double *, const double *, size_t, double *))(void *)GetProcAddress(handle, "vmath_dot");
    api.set_logger = (void (*)(vmath_log_fn))(void *)GetProcAddress(handle, "vmath_set_logger");
    api.free_mem   = (void (*)(void *))(void *)GetProcAddress(handle, "vmath_free");
    api.build_info = (const char *(*)(void))(void *)GetProcAddress(handle, "vmath_build_info");
    api.last_error = (int (*)(void))(void *)GetProcAddress(handle, "vmath_last_error");
    if (api.add == NULL || api.dot == NULL || api.set_logger == NULL ||
        api.free_mem == NULL || api.last_error == NULL) {
        fprintf(stderr, "--dynamic: named lookup incomplete\n");
        (void)FreeLibrary(handle);
        return 2;
    }
    printf("--dynamic: loaded %s, named lookups 5/6 (+build_info by ordinal below)\n", path);
    if (api.build_info != NULL) {
        fprintf(stderr, "--dynamic: UNEXPECTED: NONAME symbol resolved by name (A2 violated)\n");
        rc = 2;
    } else {
        printf("--dynamic: GetProcAddress(h, \"vmath_build_info\") == NULL as expected (NONAME)\n");
    }
    /* ordinal 5 取 build_info（A3；NONAME 只能按 ordinal 寻址） */
    api.build_info = (const char *(*)(void))(void *)GetProcAddress(handle, MAKEINTRESOURCEA(5));
    if (api.build_info == NULL) {
        fprintf(stderr, "--dynamic: ordinal-5 lookup FAILED (A3 violated)\n");
        (void)FreeLibrary(handle);
        return 2;
    }
    printf("--dynamic: GetProcAddress(h, MAKEINTRESOURCEA(5)) resolved vmath_build_info\n");

    api.set_logger(cli_log);
    if (strcmp(argv[arg_base], "add") == 0 && arg_base + 2 < argc) {
        double a = strtod(argv[arg_base + 1], NULL);
        double b = strtod(argv[arg_base + 2], NULL);
        (void)snprintf(buf, sizeof buf, "add(%s,%s) = %g", argv[arg_base + 1], argv[arg_base + 2], api.add(a, b));
        cli_log(buf);
    } else if (strcmp(argv[arg_base], "info") == 0) {
        printf("%s\n", api.build_info());
    } else if (strcmp(argv[arg_base], "dot") == 0 && arg_base + 2 < argc) {
        double xs[CALC_LIST_CAP_];
        double ys[CALC_LIST_CAP_];
        size_t nx = 0;
        size_t ny = 0;
        double out = 0.0;
        if (parse_list(argv[arg_base + 1], xs, CALC_LIST_CAP_, &nx) != 0 ||
            parse_list(argv[arg_base + 2], ys, CALC_LIST_CAP_, &ny) != 0 ||
            nx != ny || nx == 0) {
            fprintf(stderr, "--dynamic dot: invalid or mismatched lists\n");
            rc = 2;
        } else if (api.dot(xs, ys, nx, &out) != 0) {
            fprintf(stderr, "--dynamic dot: failed, error=%s\n", err_name(api.last_error()));
            rc = 2;
        } else {
            (void)snprintf(buf, sizeof buf, "dot(len=%zu) = %g", nx, out);
            cli_log(buf);
        }
    } else {
        fprintf(stderr, "--dynamic: unsupported command '%s' (add/dot/info)\n", argv[arg_base]);
        rc = 2;
    }
    /* FreeLibrary 前注销 logger（A4：卸载后无悬空调用） */
    api.set_logger(0);
    if (!FreeLibrary(handle)) {
        fprintf(stderr, "--dynamic: FreeLibrary failed (GetLastError=%lu)\n", (unsigned long)GetLastError());
        rc = 2;
    } else {
        printf("--dynamic: library unloaded (no dangling calls)\n");
    }
    memset(&api, 0, sizeof api);
    return rc;
}
#endif /* _WIN32 */

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

/* RV 通道命令：--dynamic [libpath] <command> [args]
 * dlopen 绝对路径 → dlsym 按名 → 函数表（成员序=ordinal）→ 调用 →
 * set_logger(NULL) 注销 → dlclose → 卸载后不持有库内地址。 */
#if !defined(_WIN32) /* dlopen/dlsym/dlclose 为 POSIX 专属；Windows 走 cmd_dynamic_win */
static int cmd_dynamic(int argc, char **argv)
{
    char path[4096];
    void *handle = NULL;
    calc_api_table_ api;
    int arg_base = 0;
    int rc;
    const char *err;
    char buf[128];

    if (dynamic_lib_path(argc, argv, &arg_base, path, sizeof path) != 0) {
        fprintf(stderr, "--dynamic: cannot resolve library path\n");
        return 2;
    }
    if (arg_base >= argc) {
        fprintf(stderr, "usage: calctool --dynamic [libpath] <command> [args]\n");
        return 2;
    }

    handle = dlopen(path, RTLD_NOW | RTLD_LOCAL);
    if (handle == NULL) {
        err = dlerror();
        fprintf(stderr, "--dynamic: cannot load '%s': %s\n", path, err != NULL ? err : "unknown");
        return 2; /* A4：明确错误，不崩溃 */
    }

    /* dlsym 按名取 6 个 API，装入函数表（成员位置 = ordinal 跨平台替代） */
    api.add         = (double (*)(double, double))dlsym(handle, "vmath_add");
    api.dot         = (int (*)(const double *, const double *, size_t, double *))dlsym(handle, "vmath_dot");
    api.set_logger  = (void (*)(vmath_log_fn))dlsym(handle, "vmath_set_logger");
    api.free_mem    = (void (*)(void *))dlsym(handle, "vmath_free");
    api.build_info  = (const char *(*)(void))dlsym(handle, "vmath_build_info");
    api.last_error  = (int (*)(void))dlsym(handle, "vmath_last_error");
    if (api.add == NULL || api.dot == NULL || api.set_logger == NULL ||
        api.free_mem == NULL || api.build_info == NULL || api.last_error == NULL) {
        err = dlerror();
        fprintf(stderr, "--dynamic: dlsym incomplete: %s\n", err != NULL ? err : "symbol missing");
        (void)dlclose(handle);
        return 2;
    }
    printf("--dynamic: loaded %s, 6/6 API symbols resolved\n", path);

    /* 回调注册经函数表完成（加载副本自己的 logger 槽位） */
    api.set_logger(cli_log);

    rc = 0;
    if (strcmp(argv[arg_base], "add") == 0 && arg_base + 2 < argc) {
        double a = strtod(argv[arg_base + 1], NULL);
        double b = strtod(argv[arg_base + 2], NULL);
        (void)snprintf(buf, sizeof buf, "add(%s,%s) = %g", argv[arg_base + 1],
                       argv[arg_base + 2], api.add(a, b));
        cli_log(buf); /* 输出格式与静态链接路径一致（A1） */
    } else if (strcmp(argv[arg_base], "info") == 0) {
        printf("%s\n", api.build_info());
    } else if (strcmp(argv[arg_base], "dot") == 0 && arg_base + 2 < argc) {
        double xs[CALC_LIST_CAP_];
        double ys[CALC_LIST_CAP_];
        size_t nx = 0;
        size_t ny = 0;
        double out = 0.0;
        if (parse_list(argv[arg_base + 1], xs, CALC_LIST_CAP_, &nx) != 0 ||
            parse_list(argv[arg_base + 2], ys, CALC_LIST_CAP_, &ny) != 0 ||
            nx != ny || nx == 0) {
            fprintf(stderr, "--dynamic dot: invalid or mismatched lists\n");
            rc = 2;
        } else if (api.dot(xs, ys, nx, &out) != 0) {
            fprintf(stderr, "--dynamic dot: failed, error=%s\n", err_name(api.last_error()));
            rc = 2;
        } else {
            (void)snprintf(buf, sizeof buf, "dot(len=%zu) = %g", nx, out);
            cli_log(buf);
        }
    } else {
        fprintf(stderr, "--dynamic: unsupported command '%s' (add/dot/info)\n", argv[arg_base]);
        rc = 2;
    }

    /* 卸载前注销回调，dlclose 后不持有任何库内地址 */
    api.set_logger(0);
    if (dlclose(handle) != 0) {
        err = dlerror();
        fprintf(stderr, "--dynamic: dlclose failed: %s\n", err != NULL ? err : "unknown");
        rc = 2;
    } else {
        printf("--dynamic: library unloaded\n");
    }
    memset(&api, 0, sizeof api);
    return rc;
}

#endif /* !_WIN32 */

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
#if defined(_WIN32)
        return cmd_dynamic_win(argc, argv);
#else
        return cmd_dynamic(argc, argv);
#endif
    }
    if (strcmp(argv[1], "--bundle") == 0) {
        return cmd_bundle_stub();
    }
    return usage();
}
