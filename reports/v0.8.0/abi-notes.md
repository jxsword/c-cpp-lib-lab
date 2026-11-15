# reports/v0.8.0/abi-notes.md —— ABI 面与 STL 跨 CRT 对照记录（F-08-04）

## 反例 A：STL 跨 CRT（MSVC 专属）

样本 `tests/negative/stage3_stl_across_crt.cpp`：`std::string`/`std::vector` 成员的类整体 `dllexport`，另一 CRT 选项的 exe 调用：

| 现象 | 机理 |
|---|---|
| 崩溃 / heap corruption | STL 元素经 `operator new`（CRT A 堆）分配，另一 CRT B 的 `operator delete` 释放 → 堆不匹配 |
| 「Debug 崩溃 Release 正常」 | `_ITERATOR_DEBUG_LEVEL`：Debug=2（迭代器带调试结构）、Release=0 → 布局不同，Debug 对象被 Release 代码解析即错位 |
| MSVC LNK 余波 | CRT 静态/动态混链时链接器警告 `LNK4098` |

复现命令（windows runner）：见 `tests/negative/run.bat`；其他 OS：`run.sh` 输出 `SKIP: MSVC-specific` + exit 0（A2）。

**修复结论 = F-08-03 门面**：opaque handle + C 名导出（`stage3_vector_*`）+ 库侧 `release()`——STL 容器永不出边界，任何 CRT 组合的消费者只面对 C ABI。

## 反例 B：整体导出类导致 ABI 面膨胀

本机实测（Linux/gcc 15.2.0，-O2 -DNDEBUG）：

| 导出策略 | 全局 T 符号数 | 形式 |
|---|---|---|
| 类整体导出（Vector + Statistics 直出） | **16** | `_ZN6stage3...`（mangled，消费者绑死 ABI） |
| F-08-03 门面（opaque + C 名） | **8** | `stage3_vector_new` 等未修饰（稳定 C ABI） |

结论：门面使导出面**减半且语义稳定**（8 个 C 名覆盖 2 个类的公开能力），mangled 符号随编译器版本/STL 实现漂移的风险被隔离在库侧实现内。

## 符号对照（摘录）

| 门面 C 名（8） | 对应 C++ 能力 |
|---|---|
| stage3_vector_new / delete / push / at / size | Vector 的构造/析构/尾插/下标/长度 |
| stage3_istats_create / release / vtable | Statistics 的工厂/释放/能力表（add/mean/min/max/count） |
