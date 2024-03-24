# README #

* This library is used as sample code and to support refreshing my mathematics knowledge by repeating some course work of a Bachelor's level mathematics university course.
* Furthermore I use this project to train the coding in `C/C++` and building, debugging and testing with the tools `gcc`, `cmake`, `gdb` and `catch2` within `VSCode` used as a lightweight IDE.
* Because I have used `qtcreator` for developing in `C/C++` so far, but `VSCode` for other development projects, I'd like to merge to one IDE which is preferably `VSCode`.
* The reason why I use own types and methods in some cases, even though there are already most likely better implemented solutions in `cmath`, `linalg (C++26)`, `numeric` is to:
  1. Handle [rational numbers](src/libmathpp/types/Rational.h) with more precision than double values by avoiding error propagation through rounding errors.
  2. Use [complex numbers](src/libmathpp/types/Complex.h) with rational numbers
  3. Learn mathematical algorithms and train algorithmic programming

## To do next ##

1. **TEST:** [Rational numbers](src/libmathpp/types/Rational.h)
2. **TEST:** [Numbers theory functions](src/libmathpp/num_theory.h)
3. **TEST:** [Complex numbers](src/libmathpp/types/Complex.h)
4. **IMPLEMENT:** Logical and arithmetic operators [Complex numbers](src/libmathpp/types/Complex.h)
