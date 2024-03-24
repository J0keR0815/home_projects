add_subdirectory("libmathpp")

set(
    LIBRARIES
    "${LIBRARIES}"
    "${TARGET_LIBMATHPP}"
)

add_executable(${TARGET_RUN_EXAMPLE} "main.cpp")
target_link_libraries(${TARGET_RUN_EXAMPLE} PRIVATE "${LIBRARIES}")
