# tests/CMakeLists.txt —— CTest 注册（F-06-02；三类用例：self-test / dynamic-load / probe·info）
# --self-test 为 CI 唯一功能判据；--dynamic 属 RV 通道（P5/C18：CTest 运行被测
# 程序即 RV step）；probe/info 为组合自证与依赖判定静态字段。

# ① self-test（全部形态）
add_test(NAME self-test COMMAND calctool --self-test)

# ② probe（全部形态）：类型表 + 内置依赖清单（依赖判定类）
add_test(NAME probe-deps COMMAND calctool probe)
set_tests_properties(probe-deps PROPERTIES PASS_REGULAR_EXPRESSION "type sizes")

# ③ info 字段判定（组合自证：bits= 必在）
add_test(NAME info-fields COMMAND calctool info)
set_tests_properties(info-fields PROPERTIES PASS_REGULAR_EXPRESSION "bits=")

# ④ 动态加载演示（仅 shared；RV 通道）
if(BUILD_SHARED_LIBS)
    add_test(NAME dynamic-load COMMAND calctool --dynamic $<TARGET_FILE:vmath> info)
endif()
