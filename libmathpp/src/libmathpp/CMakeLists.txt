set(
    LIBMATHPP_SRCS

    algebra.h algebra.cpp
    num_theory.h num_theory.cpp

    # types
    types/Complex.h
    types/Rational.h

)

add_library(${TARGET_LIBMATHPP} STATIC)
target_sources(${TARGET_LIBMATHPP} PRIVATE "${LIBMATHPP_SRCS}")
target_include_directories(
    ${TARGET_LIBMATHPP} PUBLIC "${CMAKE_HOME_DIRECTORY}/src/libmathpp"
)
