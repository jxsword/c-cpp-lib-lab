// stage3_stl_across_crt.cpp —— 反例（期望失败/对照观察）：STL 跨 CRT（F-08-04）
//
// 反例 A（MSVC 专属复现）：含 std::string 成员的类整体 dllexport，
// 在另一 CRT 选项（/MD ↔ /MT、Debug ↔ Release 的 _ITERATOR_DEBUG_LEVEL 不同）的
// exe 中调用 → STL 堆分配跨 CRT → 崩溃或「Debug 崩溃 Release 正常」。
//
// 本文件为 MSVC 编译样本（供 windows runner 复现）：
//   cl /LD /EHsc /DCALC_API=__declspec(dllexport) stage3_stl_across_crt.cpp
//   cl /EHsc /MD consumer.cpp ...（用不同 CRT 链接）
// 在 Linux/其他 OS 上：run.sh 输出 SKIP 且 exit 0（A2）。
// 修复方式：F-08-03 门面（opaque handle + C 名导出，STL 不出边界）。

#include <string>
#include <vector>

#if defined(_MSC_VER) && defined(CALC_EXPORTING)
#define CALC_API __declspec(dllexport)
#else
#define CALC_API
#endif

class CALC_API BadGreeter {
public:
    explicit BadGreeter(const char *name) : name_(name) {} // std::string 成员随类导出
    const char *greet() const { return name_.c_str(); }    // 返回内部缓冲指针（跨 CRT 堆悬挂）
private:
    std::string name_;                       // STL 成员跨 CRT = 堆分配器不匹配
    std::vector<double> junk_{1.0, 2.0};     // 同上
};
