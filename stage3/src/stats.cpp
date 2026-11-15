// stage3/src/stats.cpp —— Statistics 类实现（F-08-02；组合 Vector）
#include "stats.hpp"

namespace stage3 {

Statistics::Statistics() : samples_() {}

void Statistics::add(double value)
{
    samples_.push_back(value);
}

double Statistics::min() const
{
    const std::size_t n = samples_.size();
    if (n == 0) {
        return 0.0;
    }
    double m = samples_.at(0);
    for (std::size_t i = 1; i < n; ++i) {
        const double v = samples_.at(i);
        if (v < m) {
            m = v;
        }
    }
    return m;
}

double Statistics::max() const
{
    const std::size_t n = samples_.size();
    if (n == 0) {
        return 0.0;
    }
    double m = samples_.at(0);
    for (std::size_t i = 1; i < n; ++i) {
        const double v = samples_.at(i);
        if (v > m) {
            m = v;
        }
    }
    return m;
}

double Statistics::mean() const
{
    const std::size_t n = samples_.size();
    if (n == 0) {
        return 0.0;
    }
    double sum = 0.0;
    for (std::size_t i = 0; i < n; ++i) {
        sum += samples_.at(i);
    }
    return sum / static_cast<double>(n);
}

std::size_t Statistics::count() const
{
    return samples_.size();
}

} // namespace stage3
