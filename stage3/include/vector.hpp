// stage3/include/vector.hpp —— 阶段 3：纯 C++ Vector 类（F-08-01；PLAN F-08-01 要点）
//
// 声明与实现分离（实现见 stage3/src/vector.cpp）；含 STL 容器成员（std::vector）；
// **不导出 STL 类型到库边界**——公开接口只用基本类型与自定义类型，
// STL 容器作为私有实现细节（跨编译器/跨 CRT 边界安全，F.3 规则 6/7）。
// 与 vmath.h 无类型耦合（阶段 3 为纯 C++ 面向对象，独立于阶段 1 的 C 接口）。
#ifndef STAGE3_VECTOR_HPP
#define STAGE3_VECTOR_HPP

#include <cstddef>
#include <vector>

namespace stage3 {

class Vector {
public:
    Vector();
    explicit Vector(std::size_t n, double initial = 0.0);

    // ≥2 成员方法：下标读写 + 归一化 + 元素数
    double &at(std::size_t index);
    const double &at(std::size_t index) const;
    void normalize();
    std::size_t size() const;

private:
    std::vector<double> data_; // STL 容器成员（私有，不跨边界）
};

} // namespace stage3

#endif // STAGE3_VECTOR_HPP
