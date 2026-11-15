/* 反例（期望失败）：静态库使用侧误开 dllimport 语义。
 *
 * 背景：MSVC 下经 __declspec(dllimport) 声明（即 CALC_USE_DLL 模式）调用的函数，
 * 编译器生成对 __imp_<name> 间接寻址符号的引用；静态库的导出表中不存在
 * __imp_ 前缀符号，链接期必然报「未解析外部符号」。
 *
 * 本文件在 ELF 目标上以同名符号引用模拟该失败模式：静态库（libvmath.a）
 * 同样不含 __imp_vmath_add，链接必然失败——与 PE 目标上的真实失败一一对应。
 * 本文件不进入任何主构建，仅由 scripts/linux/smoke_four_modes.sh 以
 * 「期望失败」方式链接执行断言。
 */
extern double (*volatile __imp_vmath_add)(double, double);

int main(void)
{
    return (int)(__imp_vmath_add == 0);
}
