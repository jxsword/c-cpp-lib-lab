// stage3/include/stats.hpp —— 阶段 3：Statistics 类（F-08-02）
// 组合（composition）Vector——**非继承**（F.3 规则 6：STL 布局不跨边界；
// 组合使 STL 容器始终留在实现侧）。声明与实现分离。
#ifndef STAGE3_STATS_HPP
#define STAGE3_STATS_HPP

#include <cstddef>

#include "vector.hpp"

namespace stage3 {

class Statistics {
public:
    Statistics();

    // ≥2 成员方法：加样 + 最小/最大 + 均值
    void add(double value);
    double min() const;
    double max() const;
    double mean() const;
    std::size_t count() const;

private:
    Vector samples_; // 组合 Vector（STL 留在实现侧）
};

} // namespace stage3

#endif // STAGE3_STATS_HPP
