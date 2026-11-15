# Makefile —— ② make 组·GNU make 方言（F-05-01；PLAN 7.2 / 1.4）
# 一律 out-of-source：
#   cd build/make/gnu/<tag>/<kind> && make -f <abs-src>/Makefile srcdir=<abs-src> [vars...]
# 覆盖 14 组合 × 双形态：Linux 4（gcc）+ macOS 2（arm64，用 gmake）+ msys2 8（四环境）。
# 变量全部 ?= 可由命令行覆盖；VIS 仅 shared；DEF_LIB/DEF_APP 按 KIND 分派（C9）。
# 不调用 GitHub CLI（9.4 J7）。

# ---- 可覆盖变量 ----
OS      ?= linux
TOOLSET ?= gcc
VARIANT ?= x64
CFG     ?= Release
KIND    ?= static
CC      ?= gcc
AR      ?= ar
srcdir  ?= .
outdir  ?= .

# ---- cfg 旗标 ----
ifeq ($(CFG),Debug)
CFG_FLAGS = -g -O0 -D_DEBUG
else
CFG_FLAGS = -O2 -DNDEBUG
endif

# ---- arch 旗标 ----
ifeq ($(OS),linux)
  ifeq ($(VARIANT),x86)
    ARCH_FLAGS = -m32
  else
    ARCH_FLAGS = -m64
  endif
endif
ifeq ($(OS),macos)
  ARCH_FLAGS = -arch arm64
  # macOS 显式要求 gmake（7.2）；此处仅记录约定，CC 由调用方传 clang
endif
# msys2：位数/CRT 由 msystem 决定，不加 arch 旗标

# ---- 形态旗标（C9：静态 .o 不得复用动态 .o） ----
ifeq ($(KIND),shared)
  VIS      = -fvisibility=hidden -fPIC
  DEF_LIB  = -DCALC_BUILD_DLL
  DEF_APP  = -DCALC_USE_DLL
  # 动态库名按 OS：ELF libvmath.so / Mach-O libvmath.dylib / PE vmath.dll
  ifeq ($(OS),linux)
    DYLIB = $(outdir)/libvmath.so
  else ifeq ($(OS),macos)
    DYLIB = $(outdir)/libvmath.dylib
  else
    DYLIB = $(outdir)/vmath.dll
  endif
else
  VIS      =
  DEF_LIB  = -DCALC_STATIC
  DEF_APP  = -DCALC_STATIC
endif

CFLAGS_ALL = $(CFG_FLAGS) $(ARCH_FLAGS) $(VIS)
INCLUDES   = -I$(srcdir)/include
LIBSRC     = $(srcdir)/src/vmath_core.c $(srcdir)/src/vmath_report.c

# ---- 目标 ----
all: lib app

lib:
	@mkdir -p $(outdir)
ifeq ($(KIND),shared)
	$(CC) $(CFLAGS_ALL) $(DEF_LIB) $(INCLUDES) -c $(srcdir)/src/vmath_core.c -o $(outdir)/vmath_core.o
	$(CC) $(CFLAGS_ALL) $(DEF_LIB) $(INCLUDES) -c $(srcdir)/src/vmath_report.c -o $(outdir)/vmath_report.o
	$(CC) $(ARCH_FLAGS) -shared $(VIS) -o $(DYLIB) $(outdir)/vmath_core.o $(outdir)/vmath_report.o
ifeq ($(OS),msys2)
	# PE 需要 import lib 供消费端链接（7.2：--out-implib）
	$(CC) $(ARCH_FLAGS) -shared $(VIS) -o $(DYLIB) $(outdir)/vmath_core.o $(outdir)/vmath_report.o -Wl,--out-implib,$(outdir)/libvmath.dll.a
endif
else
	$(CC) $(CFLAGS_ALL) $(DEF_LIB) $(INCLUDES) -c $(srcdir)/src/vmath_core.c -o $(outdir)/vmath_core.o
	$(CC) $(CFLAGS_ALL) $(DEF_LIB) $(INCLUDES) -c $(srcdir)/src/vmath_report.c -o $(outdir)/vmath_report.o
	$(AR) rcs $(outdir)/libvmath.a $(outdir)/vmath_core.o $(outdir)/vmath_report.o
endif

app:
	$(CC) $(CFG_FLAGS) $(ARCH_FLAGS) $(DEF_APP) $(INCLUDES) -c $(srcdir)/src/calctool.c -o $(outdir)/calctool.o
ifeq ($(KIND),shared)
ifeq ($(OS),macos)
	$(CC) $(ARCH_FLAGS) $(outdir)/calctool.o -L$(outdir) -lvmath -Wl,-rpath,@loader_path -o $(outdir)/calctool
else
	$(CC) $(ARCH_FLAGS) $(outdir)/calctool.o -L$(outdir) -lvmath -Wl,-rpath,'$$ORIGIN' -o $(outdir)/calctool
endif
else
	$(CC) $(ARCH_FLAGS) $(outdir)/calctool.o $(outdir)/libvmath.a -o $(outdir)/calctool
endif

selftest: all
	$(outdir)/calctool --self-test

analyze: selftest
ifeq ($(OS),macos)
	bash $(srcdir)/scripts/macos/analyze.sh macos_$(TOOLSET)_$(VARIANT)_$(CFG) $(KIND) make/gnu
else
	bash $(srcdir)/scripts/linux/analyze.sh $(OS)_$(TOOLSET)_$(VARIANT)_$(CFG) $(KIND) make/gnu
endif

clean:
	rm -f $(outdir)/vmath_core.o $(outdir)/vmath_report.o $(outdir)/calctool.o \
	      $(outdir)/libvmath.a $(outdir)/libvmath.dll $(outdir)/calctool

.PHONY: all lib app selftest analyze clean
