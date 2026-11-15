// stage3/src/vector.cpp —— Vector 类实现（F-08-01；声明见 include/vector.hpp）
#include "vector.hpp"

namespace stage3 {

Vector::Vector() : data_() {}

Vector::Vector(std::size_t n, double initial) : data_(n, initial) {}

double &Vector::at(std::size_t index)
{
    return data_.at(index); // 越界抛 std::out_of_range（C++ 侧语义，不跨 C 帧）
}

const double &Vector::at(std::size_t index) const
{
    return data_.at(index);
}

void Vector::push_back(double value)
{
    data_.push_back(value);
}

void Vector::normalize()
{
    // 归一化：所有元素缩放到 [0,1]（最小值归零）；空容器为 no-op
    if (data_.empty()) {
        return;
    }
    double minv = data_[0];
    double maxv = data_[0];
    for (double v : data_) {
        if (v < minv) {
            minv = v;
        }
        if (v > maxv) {
            maxv = v;
        }
    }
    const double range = maxv - minv;
    if (range == 0.0) {
        return;
    }
    for (double &v : data_) {
        v = (v - minv) / range;
    }
}

std::size_t Vector::size() const
{
    return data_.size();
}

} // namespace stage3
