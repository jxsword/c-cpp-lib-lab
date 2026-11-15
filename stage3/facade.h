// stage3/facade.h —— C ABI 门面 + 纯虚接口契约（F-08-03；PLAN F.3 规则 2/6/7）
//
// 目的：C++ 库跨编译器不可互链（MSVC `?*@@` vs Itanium `_Z*`）——标准解法：
//   ① opaque handle 门面：不完整类型 + C 命名函数（异常在 C++ 侧捕获转错误码）
//   ② C 工厂函数 + 纯虚接口 + 库侧 release()：消费者只链接 C 名字
// 本头文件必须能被**纯 C 编译器**通过（A1）：
//   禁 STL 类型、禁内联函数体、禁模板、禁默认参数。
#ifndef STAGE3_FACADE_H
#define STAGE3_FACADE_H

#ifdef __cplusplus
extern "C" {
#endif

/* ---- ① opaque handle 门面：stage3::Vector 的 C ABI 视图 ---- */
typedef struct stage3_vector_s stage3_vector_t;

/* 错误码：0 = OK；1 = 空指针；2 = 越界；3 = 内存不足（异常在 C++ 侧捕获转换） */
int stage3_vector_new(stage3_vector_t **out);
int stage3_vector_delete(stage3_vector_t *v);
int stage3_vector_push(stage3_vector_t *v, double value);
int stage3_vector_at(stage3_vector_t *v, unsigned long index, double *out);
int stage3_vector_size(stage3_vector_t *v, unsigned long *out);

/* ---- ② 纯虚接口契约：C 工厂 + 函数指针表 + 库侧 release ----
 * 接口头禁 STL / 内联函数体 / 模板 / 默认参数（A3 断言）；
 * 实现侧以 C++ 纯虚类承载 vtable（facade.cpp），消费者只见指针。 */
typedef struct stage3_istats stage3_istats;

typedef struct stage3_istats_vtbl {
    void (*add)(stage3_istats *self, double value);
    double (*mean)(const stage3_istats *self);
    double (*min)(const stage3_istats *self);
    double (*max)(const stage3_istats *self);
    unsigned long (*count)(const stage3_istats *self);
} stage3_istats_vtbl;

int stage3_istats_create(stage3_istats **out); /* 工厂：返回挂 vtable 的不完整类型指针 */
int stage3_istats_release(stage3_istats *s);   /* 库侧 release（谁分配谁释放，F.3 规则 4） */
const stage3_istats_vtbl *stage3_istats_vtable(void); /* 取 vtable（C 消费者按表调用） */

#ifdef __cplusplus
}
#endif

#endif /* STAGE3_FACADE_H */
