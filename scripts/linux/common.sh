# scripts/linux/common.sh —— Linux 特有辅助（F-02-01；被 scripts/linux/ 下脚本 source）
# 不调用 GitHub CLI（9.4 J7）。

# ---- cfg → 编译旗标（PLAN F-02-01 要点：Debug -g -O0 -D_DEBUG，Release -O2 -DNDEBUG） ----
calc_linux_cfg_flags()
{
    case "$1" in
        Debug)   printf '%s' '-g -O0 -D_DEBUG' ;;
        Release) printf '%s' '-O2 -DNDEBUG' ;;
        *) return 1 ;;
    esac
}

# ---- arch → 位数旗标（x86 -m32；x64 默认） ----
calc_linux_arch_flags()
{
    case "$1" in
        x86) printf '%s' '-m32' ;;
        x64) printf '%s' '' ;;
        *) return 1 ;;
    esac
}

# ---- 三级符号链接：libvmath.so → libvmath.so.1 → libvmath.so.1.0.0 ----
calc_linux_soname_links()
{
    ln -sf libvmath.so.1.0.0 "$1/libvmath.so.1" &&
    ln -sf libvmath.so.1 "$1/libvmath.so"
}

# ---- ELF 类别（静态读取）：ELF32 / ELF64 ----
calc_linux_elf_class()
{
    readelf -h "$1" | awk '/^  Class:/ {print $3}'
}

# ---- 动态段 NEEDED 查询（静态读取） ----
calc_linux_needed()
{
    readelf -d "$1" 2>/dev/null | grep 'NEEDED' || true
}
