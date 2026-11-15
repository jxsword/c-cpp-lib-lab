// stage2/main.cpp —— 阶段 2：C++ 程序链接纯 C 库（F-07-01；PLAN 12.F.3 规则 1/5）
//
// 要点：#include "vmath.h" 即得 extern "C" 声明（CALC_EXTERN_C_BEGIN/END 包裹）——
// C++ 侧不做任何额外声明，直接调用；复用阶段 1 库产物，**不重编库**。
// 构建（Linux）：g++ -Iinclude stage2/main.cpp -Lbuild/native/linux_gcc_x64_Release/shared \
//                  -lvmath -Wl,-rpath,'$ORIGIN' -o build/native/stage2/calcxx
#include <cstdio>

#include "vmath.h"

// 异常不得穿过 C 帧（F.3 规则 5）：C++ 侧边界内捕获并转错误码
static int safe_dot(const double *a, const double *b, size_t n, double *out)
{
    try {
        return vmath_dot(a, b, n, out);
    } catch (...) {
        return -1; // C 函数自身不抛异常，此处为防御性边界示范
    }
}

int main()
{
    // ① 标量：extern "C" 未修饰名直调
    std::printf("add(1.5,2.5) = %g\n", vmath_add(1.5, 2.5));

    // ② 点积：指针/size_t 跨 ABI 边界；错误码经访问器
    double out = 0.0;
    double a[3] = {1.0, 2.0, 3.0};
    double b[3] = {4.0, 5.0, 6.0};
    int rc = safe_dot(a, b, 3, &out);
    std::printf("dot(a,b,3) rc=%d out=%g errno=%d\n", rc, out, vmath_last_error());

    // ③ 构建信息（C 库静态串，C++ 只读）
    std::printf("info: %s\n", vmath_build_info());

    return (rc == 0) ? 0 : 1;
}
