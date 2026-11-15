/* include/vmath.h —— vmath 库公共 API（F-01-02；实现依据 PLAN 5.2 九符号 / 5.3 ordinal）
 *
 * 恰 6 个导出函数（见 5.2 表 1–6）；错误码裸符号为教学对照（表 7），
 * 消费者禁止直接引用，统一走 vmath_last_error() 访问器。
 * 内部符号 normalize_（表 8）与 CLI 入口 main（表 9）不出现在本头文件。
 */
#ifndef VMATH_H
#define VMATH_H

#include <stddef.h> /* size_t（32/64 位宽度差异由平台头保证） */

#include "calc_export.h"

CALC_EXTERN_C_BEGIN

/* 日志回调函数指针（5.2 #6 的配套类型） */
typedef void (CALC_CALL *vmath_log_fn)(const char *message);

/* 标量加法：最简导出（vmath_core.c） */
CALC_API double CALC_CALL vmath_add(double a, double b);

/* 点积：指针 / size_t 跨 32-64 宽度边界；n==0 或空指针置错误码并返回非零（vmath_core.c） */
CALC_API int CALC_CALL vmath_dot(const double *a, const double *b, size_t n, double *out);

/* 构建信息：静态字符串，含位数 / 数据模型 / sizeof(long) / sizeof(void*) /
 * 编译器 / NDEBUG-_DEBUG / _ITERATOR_DEBUG_LEVEL / 库形态 / CRT 模式（vmath_report.c） */
CALC_API const char *CALC_CALL vmath_build_info(void);

/* 库侧释放：跨 CRT 安全（vmath_report.c） */
CALC_API void CALC_CALL vmath_free(void *p);

/* 错误码访问器：跨 CRT / 跨编译器的正确做法（vmath_core.c） */
CALC_API int CALC_CALL vmath_last_error(void);

/* 日志回调注册（vmath_report.c） */
CALC_API void CALC_CALL vmath_set_logger(vmath_log_fn logger);

/* 教学对照：裸数据符号——gcc/MinGW 默认导出、MSVC 默认不导出、刻意不进导出表；
 * 消费者禁止直接引用（5.2 #7） */
extern int vmath_errno;

CALC_EXTERN_C_END

#endif /* VMATH_H */
