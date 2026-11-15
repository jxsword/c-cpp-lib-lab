# tests/CMakeLists.txt —— CTest 注册（F-03-01；--self-test 为 CI 唯一功能判据）
add_test(NAME self-test COMMAND calctool --self-test)
