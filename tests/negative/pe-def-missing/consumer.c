/* 反例（期望失败）：PE 侧静态库消费误用 dllimport 语义（F-04-05）。
 *
 * MSVC 下经 __declspec(dllimport)（CALC_USE_DLL）调用静态库的函数，编译器生成
 * 对 __imp_<name> 间接寻址符号的引用；静态库不含 __imp_ 前缀符号 → LNK2019
 * 「无法解析的外部符号 __imp_vmath_add」——与 ELF 反例（static-with-dllimport）
 * 同型。本文件不进任何主构建，仅作 CI Windows runner 的期望失败样本。
 */
extern double (*volatile __imp_vmath_add)(double, double);

int main(void)
{
    return (int)(__imp_vmath_add == 0);
}
