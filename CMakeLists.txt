# CMakeLists.txt —— ③ CMake 构建方式（F-03-01；PLAN 7.3 / 1.4）
# 一律 out-of-source：cmake -S . -B build/cmake/<tag>/<kind>
# kind 驱动：-DBUILD_SHARED_LIBS=ON|OFF → generator expression 注入
#   库侧 CALC_BUILD_DLL / CALC_STATIC；消费侧 CALC_USE_DLL（ELF 展开为空）/ CALC_STATIC
cmake_minimum_required(VERSION 3.16)
project(c_cpp_lib_lab C)

option(BUILD_SHARED_LIBS "Build vmath as a shared library" ON)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
# 构建树 RUNPATH 用 $ORIGIN 而非绝对构建路径（使 install 阶段 file(RPATH_CHANGE)
# 可靠改写为 INSTALL_RPATH；也使构建树 RUNPATH 与 native.sh 一致为恰 $ORIGIN）
set(CMAKE_BUILD_RPATH_USE_ORIGIN ON)
# MSVC CRT 抽象（CMP0091 NEW；A5：命令行 -DCMAKE_MSVC_RUNTIME_LIBRARY 按
# variant 的 _MD/_MT 注入 MultiThreadedDLL/MultiThreaded，Debug 自动 *d）
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")

add_library(vmath
    src/vmath_core.c
    src/vmath_report.c
)
target_include_directories(vmath PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include)
set_target_properties(vmath PROPERTIES
    POSITION_INDEPENDENT_CODE ON
    WINDOWS_EXPORT_ALL_SYMBOLS OFF   # 7.3 强制：导出走 .def/宏，不自动全导出
)
if(BUILD_SHARED_LIBS)
    set_target_properties(vmath PROPERTIES VERSION 1.0.0 SOVERSION 1)
    if(WIN32)
        # 导出契约（5.3/S9）：NONAME .def 只绑定 MSVC 前端（cl / clang-cl）。
        # MinGW 前端（msys2 四环境）按名全导出（SA-5 断言 6 API + vmath_errno）；
        # binutils ld 会自动消费 .def 输入（pe.em def_file_parse，2026-11-17 查证），
        # 若挂载会丢掉按名导出口径 → 仅 MSVC 前端挂载。
        if(CMAKE_C_COMPILER_ID STREQUAL "MSVC" OR CMAKE_C_COMPILER_FRONTEND_VARIANT STREQUAL "MSVC")
            target_sources(vmath PRIVATE def/vmath.def)
        endif()
    endif()
endif()
# 静态库不带隐藏可见性：不设置任何 visibility preset（默认导出）。
target_compile_definitions(vmath PRIVATE
    $<IF:$<BOOL:${BUILD_SHARED_LIBS}>,CALC_BUILD_DLL,CALC_STATIC>
)

add_executable(calctool src/calctool.c)
target_include_directories(calctool PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/include)
target_compile_definitions(calctool PRIVATE
    $<IF:$<BOOL:${BUILD_SHARED_LIBS}>,CALC_USE_DLL,CALC_STATIC>
)
target_link_libraries(calctool PRIVATE vmath ${CMAKE_DL_LIBS})
set_target_properties(calctool PROPERTIES
    BUILD_RPATH "$ORIGIN"            # 构建树内同目录找 libvmath.so.1
    INSTALL_RPATH "$ORIGIN/../lib"   # 安装树两阶段差异（7.3）
)

enable_testing()
add_subdirectory(tests)

install(TARGETS vmath calctool
    ARCHIVE DESTINATION lib
    LIBRARY DESTINATION lib
    RUNTIME DESTINATION bin
)
