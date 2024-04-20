add_executable(${TARGET_RUN_TESTS} "main.cpp")
target_link_libraries(${TARGET_RUN_TESTS} PRIVATE "${LIBRARIES}" Catch2::Catch2)

include(CTest)
include(Catch)
catch_discover_tests(${TARGET_RUN_TESTS})
