# stage3 —— 阶段 3：纯 C++ 面向对象（F-08-01/02）

`Vector`（STL 成员封装）+ `Statistics`（组合 Vector）——**声明与实现分离**，恰好 **3 源 / 2 头**：

```
stage3/include/vector.hpp   stage3/include/stats.hpp
stage3/src/vector.cpp  stage3/src/stats.cpp  stage3/src/main.cpp
```

## 设计要点（PLAN F.3 规则 6/7）

- **STL 容器不导出到库边界**：`std::vector` 是 `Vector` 的私有成员，公开接口只用基本类型与自定义类型——跨编译器（`_Z*` vs `?*`）与跨 CRT（/MD ↔ /MT 堆）边界安全。
- **组合而非继承**：`Statistics` 组合 `Vector`，STL 始终留在实现侧。
- `_ITERATOR_DEBUG_LEVEL` 差异：MSVC Debug/Release 的 STL 迭代器调试层不同（`_ITERATOR_DEBUG_LEVEL=2/0`）→ 跨 CRT 传 STL 对象即崩溃——本设计从源头避免（对 Linux 为文档性记录，实测在 Windows runner 对照）。

## 构建（out-of-source）

```bash
# Debug
g++ -std=c++17 -g -O0 -D_DEBUG -Istage3/include stage3/src/*.cpp -o build/native/stage3/calcpp_dbg
# Release
g++ -std=c++17 -O2 -DNDEBUG -Istage3/include stage3/src/*.cpp -o build/native/stage3/calcpp
# 自测
build/native/stage3/calcpp --self-test
```
