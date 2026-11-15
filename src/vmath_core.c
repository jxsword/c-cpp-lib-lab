/* src/vmath_core.c —— 库核心（F-01-03；实现依据 PLAN 5.2 表 1/2/5/7/8）
 *
 * 错误码约定（经 vmath_last_error() 读取；本项目刻意不导出任何数据符号之外
 * 的状态通道——vmath_errno 为裸符号教学对照，消费者禁止直接引用）：
 *   0 = 无错误；1 = vmath_dot 的 n == 0；2 = vmath_dot 空指针。
 */
#include "vmath.h"

/* 5.2 #7 教学对照：裸数据符号——gcc/MinGW 默认导出、MSVC 默认不导出、不进导出表 */
int vmath_errno = 0;

/* 5.2 #8 内部符号：归一化示范（-0.0 折为 +0.0）；被 vmath_add 实际引用，
 * 防止被优化器移除——导出表中不应出现 */
static double normalize_(double x)
{
    if (x == 0.0) {
        return 0.0;
    }
    return x;
}

int CALC_CALL vmath_last_error(void)
{
    return vmath_errno;
}

double CALC_CALL vmath_add(double a, double b)
{
    vmath_errno = 0;
    return normalize_(a) + normalize_(b);
}

int CALC_CALL vmath_dot(const double *a, const double *b, size_t n, double *out)
{
    vmath_errno = 0;
    if (n == 0) {
        vmath_errno = 1;
        return 1;
    }
    if (a == NULL || b == NULL || out == NULL) {
        vmath_errno = 2;
        return 2;
    }
    double sum = 0.0;
    for (size_t i = 0; i < n; ++i) {
        sum += a[i] * b[i];
    }
    *out = sum;
    return 0;
}
