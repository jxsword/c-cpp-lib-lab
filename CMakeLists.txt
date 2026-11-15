# CMakeLists.txt —— ③ CMake 构建方式（F-03-01；PLAN 7.3 / 1.4）
# 一律 out-of-source：cmake -S . -B build/cmake/<tag>/<kind>
# kind 驱动：-DBUILD_SHARED_LIBS=ON|OFF → generator expression 注入
#   库侧 CALC_BUILD_DLL / CALC_STATIC；消费侧 CALC_USE_DLL（ELF 展开为空）/ CALC_STATIC
cmake_minimum_required(VERSION 3.16)
project(c_cpp_lib_lab C)

option(BUILD_SHARED_LIBS "Build vmath as a shared library" ON)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

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
        target_sources(vmath PRIVATE def/vmath.def)
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
