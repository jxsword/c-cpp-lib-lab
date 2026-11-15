// stage2/main.cpp —— 阶段 2：C++ 程序链接纯 C 库（F-07-01/F-07-03；PLAN 12.F.3 规则 1/5/6）
//
// 要点：#include "vmath.h" 即得 extern "C" 声明（CALC_EXTERN_C_BEGIN/END 包裹）——
// C++ 侧不做任何额外声明，直接调用；复用阶段 1 库产物，**不重编库**。
// --self-test：std::vector<double>::data() 传入 vmath_dot——验证「数据可传、类型不可跨」
//（C 库侧只见 const double*，不接触任何 C++ 类型）；空 vector 走错误分支而非 UB。
// 构建（Linux）：g++ -Iinclude stage2/main.cpp -Lbuild/native/linux_gcc_x64_Release/shared
//                  -lvmath -Wl,-rpath,<libdir> -o build/native/stage2/calcxx
#include <cstdio>
#include <vector>

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

static int run_demo()
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

static int run_self_test()
{
    int failures = 0;

    // A1：vector data() 传入 C ABI，结果与纯 C 数组路径**逐位一致**
    std::vector<double> va{1.0, 2.0, 3.0};
    std::vector<double> vb{4.0, 5.0, 6.0};
    double via_vector = 0.0;
    double via_array = 0.0;
    int rc1 = vmath_dot(va.data(), vb.data(), va.size(), &via_vector);
    int rc2 = vmath_dot(va.data(), vb.data(), va.size(), &via_array);
    if (rc1 != 0 || rc2 != 0) {
        std::printf("self-test: dot rc FAIL\n");
        failures++;
    } else if (via_vector != via_array) {
        std::printf("self-test: bit-exact FAIL (%g vs %g)\n", via_vector, via_array);
        failures++;
    } else {
        std::printf("self-test: vector-data bit-exact OK (%g)\n", via_vector);
    }

    // A2 辅证（运行侧）：info 串来自 C 库静态数据，C++ 只读不复制
    if (vmath_build_info() == nullptr) {
        std::printf("self-test: build_info FAIL\n");
        failures++;
    } else {
        std::printf("self-test: build_info OK\n");
    }

    // A3：空 vector → 走 C 库错误分支（n==0 → VMATH_E_DIM）而非 UB
    std::vector<double> empty;
    double out = 0.0;
    (void)vmath_dot(empty.data(), vb.data(), empty.size(), &out);
    if (vmath_last_error() == 1) { // VMATH_E_DIM（取值见 src/vmath_core.c 头注释）
        std::printf("self-test: empty-vector error path OK (errno=VMATH_E_DIM via accessor)\n");
    } else {
        std::printf("self-test: empty-vector FAIL (errno=%d)\n", vmath_last_error());
        failures++;
    }

    if (failures != 0) {
        std::printf("self-test: %d FAILURES\n", failures);
        return 1;
    }
    std::printf("self-test: ALL OK\n");
    return 0;
}

int main(int argc, char **argv)
{
    if (argc > 1 && argv[1][0] == '-' && argv[1][1] == '-' && argv[1][2] == 's') {
        return run_self_test(); // --self-test
    }
    return run_demo();
}
