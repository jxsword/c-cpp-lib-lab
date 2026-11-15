/* src/vmath_report.c —— 库报告与资源桥（F-01-04；实现依据 PLAN 5.2 表 3/4/6）
 *
 * vmath_build_info() 返回静态常量字符串：全部字段编译期选择并拼接进 .rodata，
 * 供 SA-3 以 strings 静态提取（不经运行即可读出位数/数据模型/编译器等标记）。
 * vmath_free() 在库自身 CRT 内执行释放——释放与分配必须同 CRT 才跨 CRT 安全。
 * vmath_set_logger() 允许传 NULL 注销回调。
 */
#include "vmath.h"
#include <stdlib.h>

/* ---- 编译期字符串化辅助（内部宏，不导出） ---- */
#define CALC_STR_(x) #x
#define CALC_STR(x) CALC_STR_(x)

/* ---- ① 位数 / 数据模型 / 宽度（编译期选择，与 sizeof 静态断言互锁） ---- */
#if defined(_WIN64)
#  define CALC_BITS_       "64"
#  define CALC_MODEL_      "LLP64"
#  define CALC_LONG_SIZE_V 4
#  define CALC_PTR_SIZE_V  8
#elif defined(__LP64__) || defined(__x86_64__) || defined(__aarch64__)
#  define CALC_BITS_       "64"
#  define CALC_MODEL_      "LP64"
#  define CALC_LONG_SIZE_V 8
#  define CALC_PTR_SIZE_V  8
#else
#  define CALC_BITS_       "32"
#  define CALC_MODEL_      "ILP32"
#  define CALC_LONG_SIZE_V 4
#  define CALC_PTR_SIZE_V  4
#endif
#define CALC_LONG_SIZE_ CALC_STR(CALC_LONG_SIZE_V)
#define CALC_PTR_SIZE_ CALC_STR(CALC_PTR_SIZE_V)

/* 字符串值与真实 sizeof 的编译期互锁（防 #if 分支与实际数据模型不符） */
typedef char calc_assert_long_[(sizeof(long) == CALC_LONG_SIZE_V) ? 1 : -1];
typedef char calc_assert_ptr_[(sizeof(void *) == CALC_PTR_SIZE_V) ? 1 : -1];

/* ---- ② 编译器名 + 版本 ---- */
#if defined(__clang__)
#  define CALC_COMPILER_ "clang " __VERSION__
#elif defined(__GNUC__)
#  define CALC_COMPILER_ "gcc " __VERSION__
#elif defined(_MSC_VER)
#  define CALC_COMPILER_ "msvc " CALC_STR(_MSC_VER)
#else
#  define CALC_COMPILER_ "unknown"
#endif

/* ---- ③ 配置（NDEBUG / _DEBUG） ---- */
#if defined(_DEBUG)
#  define CALC_CFG_ "_DEBUG"
#elif defined(NDEBUG)
#  define CALC_CFG_ "NDEBUG"
#else
#  define CALC_CFG_ "no-NDEBUG"
#endif

/* ---- ④ MSVC 迭代器调试层（非 MSVC 平台记 n/a） ---- */
#if defined(_ITERATOR_DEBUG_LEVEL)
#  define CALC_IDL_ CALC_STR(_ITERATOR_DEBUG_LEVEL)
#else
#  define CALC_IDL_ "n/a"
#endif

/* ---- ⑤ 库形态（四模式，见 calc_export.h） ---- */
#if defined(CALC_STATIC)
#  define CALC_LIBFORM_ "static"
#elif defined(CALC_BUILD_DLL)
#  define CALC_LIBFORM_ "shared-build(dll)"
#elif defined(CALC_USE_DLL)
#  define CALC_LIBFORM_ "shared-use(dllimport)"
#elif defined(CALC_NO_LIB)
#  define CALC_LIBFORM_ "no-lib(sources)"
#else
#  define CALC_LIBFORM_ "unspecified"
#endif

/* ---- ⑥ CRT 模式 ---- */
#if defined(_MSC_VER)
#  if defined(_DLL)
#    define CALC_CRT_ "dynamic"
#  else
#    define CALC_CRT_ "static"
#  endif
#else
#  define CALC_CRT_ "default-dynamic(libc)"
#endif

/* ---- 静态常量报告串（.rodata；SA-3 静态提取目标） ---- */
static const char CALC_BUILD_INFO_[] =
    "vmath build info:"
    " bits=" CALC_BITS_
    " datamodel=" CALC_MODEL_
    " sizeof(long)=" CALC_LONG_SIZE_
    " sizeof(void*)=" CALC_PTR_SIZE_
    " compiler=" CALC_COMPILER_
    " cfg=" CALC_CFG_
    " iterator_debug_level=" CALC_IDL_
    " libform=" CALC_LIBFORM_
    " crt=" CALC_CRT_
    ";";

/* ---- 日志回调注册表（允许 NULL = 注销） ---- */
static vmath_log_fn calc_logger_ = 0;

void CALC_CALL vmath_set_logger(vmath_log_fn logger)
{
    calc_logger_ = logger;
}

void CALC_CALL vmath_free(void *p)
{
    /* 释放发生在本库的 CRT 内：跨 CRT 场景下谁分配谁释放 */
    free(p);
}

const char *CALC_CALL vmath_build_info(void)
{
    return CALC_BUILD_INFO_;
}
