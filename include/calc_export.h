/* include/calc_export.h —— 四模式导出宏头（F-01-01；实现依据 PLAN 5.1 六条 + 12.F.2）
 *
 * 四模式：CALC_STATIC（静态库）/ CALC_BUILD_DLL（建库侧）
 *        / CALC_USE_DLL（用库侧）/ CALC_NO_LIB（不建库直编源码）
 * 结构顺序：① 平台判定 → ② C++ 链接规格 → ③ 四模式分派
 *          → ④ CALC_CALL（32 位 Windows 统一 __cdecl，禁 __stdcall：
 *             x86 COFF 会产生 _foo@N 修饰名，与 .def 未修饰名不匹配）
 *          → ⑤ 本项目刻意不导出任何数据符号（错误码走 vmath_last_error() 访问器）
 *          → ⑥ 可选弃用标记。宏名一律 CALC_ 前缀。
 */
#ifndef CALC_EXPORT_H
#define CALC_EXPORT_H

/* ① 平台判定 */
#if defined(_WIN32) || defined(_WIN64) || defined(__CYGWIN__)
#  define CALC_PLATFORM_WINDOWS 1
#elif defined(__APPLE__)
#  define CALC_PLATFORM_MACOS 1
#else
#  define CALC_PLATFORM_UNIX 1
#endif

/* ② C++ 链接规格：C 库被 C++ 调用时不改名 */
#ifdef __cplusplus
#  define CALC_EXTERN_C_BEGIN extern "C" {
#  define CALC_EXTERN_C_END   }
#else
#  define CALC_EXTERN_C_BEGIN
#  define CALC_EXTERN_C_END
#endif

/* ③ 四模式分派 */
#if defined(CALC_STATIC) || defined(CALC_NO_LIB)
#  define CALC_API                                  /* 静态 / 不建库：展开为空 */
#elif defined(CALC_PLATFORM_WINDOWS)
#  if defined(CALC_BUILD_DLL)
#    define CALC_API __declspec(dllexport)
#  else
#    define CALC_API __declspec(dllimport)          /* 未指定时按导入侧 */
#  endif
#else
#  if defined(CALC_BUILD_DLL)
#    define CALC_API __attribute__((visibility("default")))
#  else
#    define CALC_API
#  endif
#endif

/* ④ 调用约定：32 位 Windows 统一 __cdecl（禁用 __stdcall，见 5.1 ④） */
#if defined(CALC_PLATFORM_WINDOWS) && !defined(_WIN64)
#  define CALC_CALL __cdecl
#else
#  define CALC_CALL
#endif

/* ⑤ 本项目刻意不导出任何数据符号：错误码走 vmath_last_error() 访问器 */

/* ⑥ 可选弃用标记 */
#if defined(__GNUC__) || defined(__clang__)
#  define CALC_DEPRECATED(msg) __attribute__((deprecated(msg)))
#elif defined(_MSC_VER)
#  define CALC_DEPRECATED(msg) __declspec(deprecated(msg))
#else
#  define CALC_DEPRECATED(msg)
#endif

#endif /* CALC_EXPORT_H */
