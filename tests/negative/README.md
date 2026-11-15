# tests/negative —— 反例（期望失败）目录

所有反例**不进任何主构建 / 主 CI 绿路径**；由 `run.sh` 以「期望失败」方式执行（链接失败 = 通过）。

| 样本 | 平台 | 期望失败 | 修复方式 |
|---|---|---|---|
| `stage2_no_extern_c.cpp`（F-07-02） | Linux/ELF（Itanium mangling `_Z9vmath_adddd`） | `undefined reference to '_Z9vmath_adddd'` | 恢复 `extern "C"` 守卫 = `#include "vmath.h"`（CALC_EXTERN_C_BEGIN/END） |
| `static-with-dllimport/consumer.c`（F-01-06） | ELF 模拟 PE | `__imp_vmath_add` 未解析 | 静态库消费侧不开 dllimport（用 `CALC_STATIC`/`CALC_NO_LIB`） |
| `pe-def-missing/consumer.c`（F-04-05） | PE（MSVC LNK2019 同型） | `__imp_vmath_add` 未解析 | 同上（Windows runner 实证） |

## 用法

```bash
./tests/negative/run.sh stage2_no_extern_c   # 返回 0 = 反例如期失败（通过）
```

日志与 mangling 特征串归档：`reports/v0.7.0/negative/<名>.log`。
