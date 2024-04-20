set(
    MATHPP_HEADERS
    
    algebra.h
    num_theory.h

    # types
    types/Complex.h
    types/Matrix.h
    types/Rational.h
    types/Vector.h
)

set(
    MATHPP_SRCS

    algebra.cpp
    num_theory.cpp
)

if (NOT BUILD_SHARED_LIBS)
    # Build mathpp statically
    add_library(${TARGET_LIB_MATHPP} STATIC)
else ()
    # Build mathpp dynamically
    add_library(${TARGET_LIB_MATHPP} SHARED)
endif()

target_sources(
    ${TARGET_LIB_MATHPP} PRIVATE "${MATHPP_SRCS}"
)
target_include_directories(
    ${TARGET_LIB_MATHPP} PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}"
)

if (BUILD_SHARED_LIBS)
    set_target_properties(
        ${TARGET_LIB_MATHPP} PROPERTIES VERSION ${PROJECT_VERSION}
    )
    set_target_properties(
        ${TARGET_LIB_MATHPP} PROPERTIES SOVERSION ${PROJECT_VERSION_MAJOR}
    )
    set_target_properties(
        ${TARGET_LIB_MATHPP} PROPERTIES PUBLIC_HEADER "${MATHPP_HEADERS}"
    )
endif()

set(PATH_MATHPP "${CMAKE_HOME_DIRECTORY}/lib/mathpp/Debug")
if (${CMAKE_BUILD_TYPE} MATCHES "Release")
    set(PATH_MATHPP "${CMAKE_HOME_DIRECTORY}/lib/mathpp/Release")
endif ()
install(
    TARGETS ${TARGET_LIB_MATHPP}
    LIBRARY DESTINATION "${PATH_MATHPP}/lib"
    PUBLIC_HEADER DESTINATION "${PATH_MATHPP}/include"
)
