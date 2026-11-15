// stage3/facade.cpp —— C ABI 门面实现（F-08-03）
// 异常在 C++ 侧捕获转错误码（F.3 规则 5）；消费者只链接 C 名字（规则 7）。
#include "facade.h"

#include <new>

#include "include/stats.hpp"
#include "include/vector.hpp"

/* ---- ① opaque handle：stage3::Vector 的薄包装（全局类型，对应 facade.h 的前置声明） ---- */
struct stage3_vector_s {
    stage3::Vector impl;
};

namespace {

constexpr int STAGE3_OK = 0;
constexpr int STAGE3_E_NULL = 1;
constexpr int STAGE3_E_RANGE = 2;
constexpr int STAGE3_E_ALLOC = 3;

/* ---- ② 纯虚接口的 C++ 侧实现（vtable 挂静态实例） ---- */
class StatsImpl final : public stage3::Statistics {
};

void vtbl_add(stage3_istats *self, double value);
double vtbl_mean(const stage3_istats *self);
double vtbl_min(const stage3_istats *self);
double vtbl_max(const stage3_istats *self);
unsigned long vtbl_count(const stage3_istats *self);

const stage3_istats_vtbl kVtbl = {
    vtbl_add,
    vtbl_mean,
    vtbl_min,
    vtbl_max,
    vtbl_count,
};

inline stage3::Statistics *impl_of(stage3_istats *s)
{
    return reinterpret_cast<stage3::Statistics *>(s);
}

inline const stage3::Statistics *impl_of(const stage3_istats *s)
{
    return reinterpret_cast<const stage3::Statistics *>(s);
}

void vtbl_add(stage3_istats *self, double value)
{
    impl_of(self)->add(value);
}

double vtbl_mean(const stage3_istats *self)
{
    return impl_of(self)->mean();
}

double vtbl_min(const stage3_istats *self)
{
    return impl_of(self)->min();
}

double vtbl_max(const stage3_istats *self)
{
    return impl_of(self)->max();
}

unsigned long vtbl_count(const stage3_istats *self)
{
    return static_cast<unsigned long>(impl_of(self)->count());
}

} // namespace

/* ---- ① 门面导出（全部 C 未修饰名；A2） ---- */
extern "C" int stage3_vector_new(stage3_vector_t **out)
{
    if (out == nullptr) {
        return STAGE3_E_NULL;
    }
    try {
        *out = new stage3_vector_s();
        return STAGE3_OK;
    } catch (...) {
        return STAGE3_E_ALLOC; // 异常不出 C 边界（规则 5）
    }
}

extern "C" int stage3_vector_delete(stage3_vector_t *v)
{
    delete v; // nullptr 安全
    return STAGE3_OK;
}

extern "C" int stage3_vector_push(stage3_vector_t *v, double value)
{
    if (v == nullptr) {
        return STAGE3_E_NULL;
    }
    try {
        v->impl.push_back(value);
        return STAGE3_OK;
    } catch (...) {
        return STAGE3_E_ALLOC;
    }
}

extern "C" int stage3_vector_at(stage3_vector_t *v, unsigned long index, double *out)
{
    if (v == nullptr || out == nullptr) {
        return STAGE3_E_NULL;
    }
    try {
        *out = v->impl.at(static_cast<std::size_t>(index));
        return STAGE3_OK;
    } catch (...) {
        return STAGE3_E_RANGE; // std::out_of_range → 错误码
    }
}

extern "C" int stage3_vector_size(stage3_vector_t *v, unsigned long *out)
{
    if (v == nullptr || out == nullptr) {
        return STAGE3_E_NULL;
    }
    *out = static_cast<unsigned long>(v->impl.size());
    return STAGE3_OK;
}

/* ---- ② 纯虚接口：工厂 + release + vtable 访问器 ---- */
extern "C" int stage3_istats_create(stage3_istats **out)
{
    if (out == nullptr) {
        return STAGE3_E_NULL;
    }
    try {
        *out = reinterpret_cast<stage3_istats *>(new StatsImpl());
        return STAGE3_OK;
    } catch (...) {
        return STAGE3_E_ALLOC;
    }
}

extern "C" int stage3_istats_release(stage3_istats *s)
{
    delete impl_of(s); // 库侧释放（谁分配谁释放，规则 4）
    return STAGE3_OK;
}

extern "C" const stage3_istats_vtbl *stage3_istats_vtable(void)
{
    return &kVtbl;
}
