add_subdirectory("mathpp")

set(
    LIBRARIES
    "${LIBRARIES}"
    "${TARGET_LIB_MATHPP}"
)

add_executable(${TARGET_RUN_EXAMPLE} "main.cpp")
target_link_libraries(${TARGET_RUN_EXAMPLE} PRIVATE "${LIBRARIES}")
