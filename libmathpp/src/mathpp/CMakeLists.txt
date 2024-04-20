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
    add_library(${TARGET_MATHPP} STATIC)
else ()
    # Build mathpp dynamically
    add_library(${TARGET_MATHPP} SHARED)
endif()

target_sources(
    ${TARGET_MATHPP} PRIVATE "${MATHPP_SRCS}"
)
target_include_directories(
    ${TARGET_MATHPP} PUBLIC "${CMAKE_HOME_DIRECTORY}/src/mathpp"
)

# add_custom_command(
#     OUTPUT "${CMAKE_HOME_DIRECTORY}/lib/mathpp/install/libmathpp.a"
#     COMMAND cp "${CMAKE_HOME_DIRECTORY}/build/mathpp/Debug/src/mathpp/libmathpp.a" "${CMAKE_HOME_DIRECTORY}/build/mathpp/install/libmathpp.a"
#     VERBATIM
# )

if (BUILD_SHARED_LIBS)
    set_target_properties(
        ${TARGET_MATHPP} PROPERTIES VERSION ${PROJECT_VERSION}
    )
    set_target_properties(
        ${TARGET_MATHPP} PROPERTIES SOVERSION ${PROJECT_VERSION_MAJOR}
    )
    set_target_properties(
        ${TARGET_MATHPP} PROPERTIES PUBLIC_HEADER "${MATHPP_HEADERS}"
    )
endif()

# install(
#     TARGETS ${TARGET_MATHPP}
#     LIBRARY DESTINATION "${CMAKE_HOME_DIRECTORY}/lib/mathpp/install"
#     PUBLIC_HEADER DESTINATION "${CMAKE_HOME_DIRECTORY}/lib/mathpp/include"
# )
