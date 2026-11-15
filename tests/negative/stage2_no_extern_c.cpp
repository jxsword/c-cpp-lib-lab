// stage2_no_extern_c.cpp —— 反例（期望失败）：去掉 extern "C"（F-07-02）
//
// 本文件刻意**不**包含 vmath.h（其 CALC_EXTERN_C_BEGIN/END 守卫提供 extern "C"），
// 而以 C++ 语法重新声明同一函数——C++ 编译器将其修饰为
//   Itanium ABI:  _Z9vmath_adddd
//   MSVC ABI:     ?vmath_add@@YANN@Z
// 纯 C 库导出的是未修饰名 vmath_add → 链接期 undefined reference（A1 特征串）。
// 修复方式 = 恢复 extern "C" 守卫（即改用 vmath.h）——A3 记录于报告。
// 本文件不进任何主构建。

double vmath_add(double a, double b);

int main()
{
    return (int)(vmath_add(1.5, 2.5) - 4.0);
}
