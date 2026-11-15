# stage2 —— 阶段 2：C++ 调用 C 链接库（F-07-01）

本目录是 **C++ 消费端**实验：`main.cpp` 直接 `#include "vmath.h"` 并调用 C 库——`CALC_EXTERN_C_BEGIN/END` 包裹使 C++ 侧无需任何额外声明。

## 关键约定：复用产物、不重编库

**本阶段复用阶段 1 已构建的库产物，不重编库。** 构建前先跑对应组合的库构建（如 `scripts/linux/native.sh x64 Release shared`），然后只编译链接 `main.cpp`：

```bash
# Linux（shared）
g++ -Iinclude stage2/main.cpp -Lbuild/native/linux_gcc_x64_Release/shared \
    -lvmath -Wl,-rpath,'$ORIGIN' -o build/native/stage2/calcxx
build/native/stage2/calcxx

# macOS（shared；install_name 为 @rpath）
clang++ -Iinclude stage2/main.cpp -Lbuild/native/macos_clang_arm64_Release/shared \
    -lvmath -Wl,-rpath,@loader_path -o build/native/stage2/calcxx

# Windows（msvc，vcvarsall 内）
cl /nologo /EHsc /Iinclude stage2\main.cpp /link /LIBPATH:build\native\win_msvc_x64_MD_Release\shared vmath.lib /OUT:build\native\stage2\calcxx.exe
```

产物一律落在 `build/native/stage2/`（out-of-source）。

## 验证点（PLAN F-07-01 断言）

- **A1**：链接 C 库成功，`add` 输出正确值
- **A2**：`nm -C` 中对 `vmath_add` 的引用为**未修饰名**（`extern "C"` 的直接证据；C++ 修饰名是 `_Z*`/`?*` 形式）
- **A3**：三 OS 各 ≥1 组合通过（Linux 实测；mac/win 随 runner）
- **A4**：本 README 即「复用产物、不重编库」说明

## 相关反例

- F-07-02：去掉 `extern "C"` → `undefined reference`（C++ 修饰名找不到 C 符号）
- F-07-03：`std::vector` 跨边界用例（异常/STL 不跨 C 帧）
