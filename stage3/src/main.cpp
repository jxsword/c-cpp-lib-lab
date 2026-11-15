// stage3/src/main.cpp —— 阶段 3 OOP 自测驱动（F-08-02）
// 用法: calcpp --self-test
#include <cstdio>

#include "stats.hpp"
#include "vector.hpp"

static int run_self_test()
{
    int failures = 0;

    // Vector：push/at/normalize
    stage3::Vector v;
    v.push_back(2.0);
    v.push_back(4.0);
    v.push_back(6.0);
    v.normalize();
    if (v.size() != 3 || v.at(0) != 0.0 || v.at(2) != 1.0) {
        std::printf("self-test: vector normalize FAIL\n");
        failures++;
    } else {
        std::printf("self-test: vector normalize OK\n");
    }

    // Statistics：组合 Vector；min/max/mean
    stage3::Statistics s;
    s.add(3.0);
    s.add(1.0);
    s.add(2.0);
    if (s.count() != 3 || s.min() != 1.0 || s.max() != 3.0 || s.mean() != 2.0) {
        std::printf("self-test: statistics FAIL (count=%zu min=%g max=%g mean=%g)\n",
                    s.count(), s.min(), s.max(), s.mean());
        failures++;
    } else {
        std::printf("self-test: statistics OK\n");
    }

    // STL 不跨边界：库符号只含类成员，无 std:: 导出（运行侧无法直接断言，
    // 由 nm 断言承担；此处确认对象生命周期正常结束）
    stage3::Statistics local;
    local.add(42.0);
    std::printf("self-test: lifetime OK (local count=%zu)\n", local.count());

    if (failures != 0) {
        std::printf("self-test: %d FAILURES\n", failures);
        return 1;
    }
    std::printf("self-test: ALL OK\n");
    return 0;
}

int main(int argc, char **argv)
{
    if (argc > 1) {
        return run_self_test(); // 任意参数即 self-test（卡面命令 calcpp --self-test）
    }
    std::printf("usage: calcpp --self-test\n");
    return 1;
}
