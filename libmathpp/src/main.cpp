/**
 * @file main.cpp
 * @brief Runs the example program using the libmathpp
 */

// - - - - - - System includes - - - - - -

#include <iostream>

// - - - - - - External library includes - - - - - -

// - - - - - - Project includes - - - - - -

#include "mathpp/num_theory.h"
#include "mathpp/types/Complex.h"

// - - - - - - Global definitions - - - - - -

int main() {
  std::cout << "# 1. Rational numbers #\n";

  mathpp::Rational r1 {0L};
  mathpp::Rational r2 {0L};
  std::cout << "\n## Construct r1 = " << r1 << " and r2 = " << r2 << " ##\n\n";
  std::cout << "-r1 = " << -r1 << '\n';
  std::cout << "|-r1| = " << mathpp::num_th::abs<mathpp::Rational>(-r1) << '\n';
  std::cout << "-r2 = " << -r2 << '\n';
  std::cout << "|-r2| = " << mathpp::num_th::abs<mathpp::Rational>(-r2) << '\n';

  std::cout << "\n## Logic operations with r1 = " << r1 << " and r2 = " << r2
            << " ##\n\n";
  std::cout << r1 << " == " << r2 << ' ' << (r1 == r2 ? "TRUE" : "FALSE")
            << '\n';
  std::cout << r1 << " != " << r2 << ' ' << (r1 != r2 ? "TRUE" : "FALSE")
            << '\n';
  std::cout << r1 << " > " << r2 << ' ' << (r1 > r2 ? "TRUE" : "FALSE") << '\n';
  std::cout << r1 << " >= " << r2 << ' ' << (r1 >= r2 ? "TRUE" : "FALSE")
            << '\n';
  std::cout << r1 << " < " << r2 << ' ' << (r1 < r2 ? "TRUE" : "FALSE") << '\n';
  std::cout << r1 << " <= " << r2 << ' ' << (r1 <= r2 ? "TRUE" : "FALSE")
            << '\n';

  r1 = 1L;
  std::cout << "\n## Assign r1 = " << r1 << " ##\n\n";
  std::cout << "-r1 = " << -r1 << '\n';
  std::cout << "|-r1| = " << mathpp::num_th::abs<mathpp::Rational>(-r1) << '\n';

  std::cout << "\n## Logic operations with r1 = " << r1 << " and r2 = " << r2
            << " ##\n\n";
  std::cout << r1 << " == " << r2 << ' ' << (r1 == r2 ? "TRUE" : "FALSE")
            << '\n';
  std::cout << r1 << " != " << r2 << ' ' << (r1 != r2 ? "TRUE" : "FALSE")
            << '\n';
  std::cout << r1 << " > " << r2 << ' ' << (r1 > r2 ? "TRUE" : "FALSE") << '\n';
  std::cout << r1 << " >= " << r2 << ' ' << (r1 >= r2 ? "TRUE" : "FALSE")
            << '\n';
  std::cout << r1 << " < " << r2 << ' ' << (r1 < r2 ? "TRUE" : "FALSE") << '\n';
  std::cout << r1 << " <= " << r2 << ' ' << (r1 <= r2 ? "TRUE" : "FALSE")
            << '\n';

  r1 = {2L, 6L};
  std::cout << "\n## Assign r1 = " << r1 << " ##\n\n";
  std::cout << "-r1 = " << -r1 << '\n';
  std::cout << "|-r1| = " << mathpp::num_th::abs<mathpp::Rational>(-r1) << '\n';

  std::cout << "\n## Arithmetic operations with r1 = " << r1
            << " and r2 = " << r2 << " ##\n\n";
  std::cout << r1 << " + " << r2 << " = " << (r1 + r2) << '\n';
  std::cout << r1 << " - " << r2 << " = " << (r1 - r2) << '\n';
  std::cout << r1 << " * " << r2 << " = " << (r1 * r2) << '\n';
  try {
    std::cout << r1 << " : " << r2 << " = " << (r1 / r2) << '\n';
  } catch (std::exception &e) {
    std::cerr << e.what() << '\n';
  }

  std::cout << "\n## Logic operations with r1 = " << r1 << " and r2 = " << r2
            << " ##\n\n";
  std::cout << r1 << " == " << r2 << ' ' << (r1 == r2 ? "TRUE" : "FALSE")
            << '\n';
  std::cout << r1 << " != " << r2 << ' ' << (r1 != r2 ? "TRUE" : "FALSE")
            << '\n';
  std::cout << r1 << " > " << r2 << ' ' << (r1 > r2 ? "TRUE" : "FALSE") << '\n';
  std::cout << r1 << " >= " << r2 << ' ' << (r1 >= r2 ? "TRUE" : "FALSE")
            << '\n';
  std::cout << r1 << " < " << r2 << ' ' << (r1 < r2 ? "TRUE" : "FALSE") << '\n';
  std::cout << r1 << " <= " << r2 << ' ' << (r1 <= r2 ? "TRUE" : "FALSE")
            << '\n';

  r2 = 1L;
  std::cout << "\n## Assign r2 = " << r2 << " ##\n\n";
  std::cout << "-r2 = " << -r2 << '\n';
  std::cout << "|-r2| = " << mathpp::num_th::abs<mathpp::Rational>(-r2) << '\n';

  std::cout << "\n## Arithmetic operations with r1 = " << r1
            << " and r2 = " << r2 << " ##\n\n";
  std::cout << r1 << " + " << r2 << " = " << (r1 + r2) << '\n';
  std::cout << r1 << " - " << r2 << " = " << (r1 - r2) << '\n';
  std::cout << r1 << " * " << r2 << " = " << (r1 * r2) << '\n';
  std::cout << r1 << " : " << r2 << " = " << (r1 / r2) << '\n';

  std::cout << "\n## Logic operations with r1 = " << r1 << " and r2 = " << r2
            << " ##\n\n";
  std::cout << r1 << " == " << r2 << ' ' << (r1 == r2 ? "TRUE" : "FALSE")
            << '\n';
  std::cout << r1 << " != " << r2 << ' ' << (r1 != r2 ? "TRUE" : "FALSE")
            << '\n';
  std::cout << r1 << " > " << r2 << ' ' << (r1 > r2 ? "TRUE" : "FALSE") << '\n';
  std::cout << r1 << " >= " << r2 << ' ' << (r1 >= r2 ? "TRUE" : "FALSE")
            << '\n';
  std::cout << r1 << " < " << r2 << ' ' << (r1 < r2 ? "TRUE" : "FALSE") << '\n';
  std::cout << r1 << " <= " << r2 << ' ' << (r1 <= r2 ? "TRUE" : "FALSE")
            << '\n';

  r2 = {1L, 3L};
  std::cout << "\n## Assign r2 = " << r2 << " ##\n\n";
  std::cout << "-r2 = " << -r2 << '\n';
  std::cout << "|-r2| = " << mathpp::num_th::abs<mathpp::Rational>(-r2) << '\n';

  std::cout << "\n## Arithmetic operations with r1 = " << r1
            << " and r2 = " << r2 << " ##\n\n";
  std::cout << r1 << " + " << r2 << " = " << (r1 + r2) << '\n';
  std::cout << r1 << " - " << r2 << " = " << (r1 - r2) << '\n';
  std::cout << r1 << " * " << r2 << " = " << (r1 * r2) << '\n';
  std::cout << r1 << " : " << r2 << " = " << (r1 / r2) << '\n';

  std::cout << "\n## Logic operations with r1 = " << r1 << " and r2 = " << r2
            << " ##\n\n";
  std::cout << r1 << " == " << r2 << ' ' << (r1 == r2 ? "TRUE" : "FALSE")
            << '\n';
  std::cout << r1 << " != " << r2 << ' ' << (r1 != r2 ? "TRUE" : "FALSE")
            << '\n';
  std::cout << r1 << " > " << r2 << ' ' << (r1 > r2 ? "TRUE" : "FALSE") << '\n';
  std::cout << r1 << " >= " << r2 << ' ' << (r1 >= r2 ? "TRUE" : "FALSE")
            << '\n';
  std::cout << r1 << " < " << r2 << ' ' << (r1 < r2 ? "TRUE" : "FALSE") << '\n';
  std::cout << r1 << " <= " << r2 << ' ' << (r1 <= r2 ? "TRUE" : "FALSE")
            << '\n';

  r2 = {-2L, 5L};
  std::cout << "\n## Assign r2 = " << r2 << " ##\n\n";
  std::cout << "-r2 = " << -r2 << '\n';
  std::cout << "|-r2| = " << mathpp::num_th::abs<mathpp::Rational>(-r2) << '\n';

  std::cout << "\n## Arithmetic operations with r1 = " << r1
            << " and r2 = " << r2 << " ##\n\n";
  std::cout << r1 << " + " << r2 << " = " << (r1 + r2) << '\n';
  std::cout << r1 << " - " << r2 << " = " << (r1 - r2) << '\n';
  std::cout << r1 << " * " << r2 << " = " << (r1 * r2) << '\n';
  std::cout << r1 << " : " << r2 << " = " << (r1 / r2) << '\n';

  std::cout << "\n## Logic operations with r1 = " << r1 << " and r2 = " << r2
            << " ##\n\n";
  std::cout << r1 << " == " << r2 << ' ' << (r1 == r2 ? "TRUE" : "FALSE")
            << '\n';
  std::cout << r1 << " != " << r2 << ' ' << (r1 != r2 ? "TRUE" : "FALSE")
            << '\n';
  std::cout << r1 << " > " << r2 << ' ' << (r1 > r2 ? "TRUE" : "FALSE") << '\n';
  std::cout << r1 << " >= " << r2 << ' ' << (r1 >= r2 ? "TRUE" : "FALSE")
            << '\n';
  std::cout << r1 << " < " << r2 << ' ' << (r1 < r2 ? "TRUE" : "FALSE") << '\n';
  std::cout << r1 << " <= " << r2 << ' ' << (r1 <= r2 ? "TRUE" : "FALSE")
            << '\n';

  double r {0.45};
  r1 = r;
  std::cout << "\n## Assign real number r = " << r << " to r1 = " << r1
            << " ##\n\n";
  std::cout << "-r1 = " << -r1 << '\n';
  std::cout << "|-r1| = " << mathpp::num_th::abs<mathpp::Rational>(-r1) << '\n';

  std::cout << "\n## Arithmetic operations with r1 = " << r1
            << " and r2 = " << r2 << " ##\n\n";
  std::cout << r1 << " + " << r2 << " = " << (r1 + r2) << '\n';
  std::cout << r1 << " - " << r2 << " = " << (r1 - r2) << '\n';
  std::cout << r1 << " * " << r2 << " = " << (r1 * r2) << '\n';
  std::cout << r1 << " : " << r2 << " = " << (r1 / r2) << '\n';

  std::cout << "\n## Logic operations with r1 = " << r1 << " and r2 = " << r2
            << " ##\n\n";
  std::cout << r1 << " == " << r2 << ' ' << (r1 == r2 ? "TRUE" : "FALSE")
            << '\n';
  std::cout << r1 << " != " << r2 << ' ' << (r1 != r2 ? "TRUE" : "FALSE")
            << '\n';
  std::cout << r1 << " > " << r2 << ' ' << (r1 > r2 ? "TRUE" : "FALSE") << '\n';
  std::cout << r1 << " >= " << r2 << ' ' << (r1 >= r2 ? "TRUE" : "FALSE")
            << '\n';
  std::cout << r1 << " < " << r2 << ' ' << (r1 < r2 ? "TRUE" : "FALSE") << '\n';
  std::cout << r1 << " <= " << r2 << ' ' << (r1 <= r2 ? "TRUE" : "FALSE")
            << '\n';

  r = -0.33;
  r2 = r;
  std::cout << "\n## Assign real number r = " << r << " to r2 = " << r2
            << " ##\n\n";
  std::cout << "-r2 = " << -r2 << '\n';
  std::cout << "|-r2| = " << mathpp::num_th::abs<mathpp::Rational>(-r2) << '\n';

  std::cout << "\n## Arithmetic operations with r1 = " << r1
            << " and r2 = " << r2 << " ##\n\n";
  std::cout << r1 << " + " << r2 << " = " << (r1 + r2) << '\n';
  std::cout << r1 << " - " << r2 << " = " << (r1 - r2) << '\n';
  std::cout << r1 << " * " << r2 << " = " << (r1 * r2) << '\n';
  std::cout << r1 << " : " << r2 << " = " << (r1 / r2) << '\n';

  std::cout << "\n## Logic operations with r1 = " << r1 << " and r2 = " << r2
            << " ##\n\n";
  std::cout << r1 << " == " << r2 << ' ' << (r1 == r2 ? "TRUE" : "FALSE")
            << '\n';
  std::cout << r1 << " != " << r2 << ' ' << (r1 != r2 ? "TRUE" : "FALSE")
            << '\n';
  std::cout << r1 << " > " << r2 << ' ' << (r1 > r2 ? "TRUE" : "FALSE") << '\n';
  std::cout << r1 << " >= " << r2 << ' ' << (r1 >= r2 ? "TRUE" : "FALSE")
            << '\n';
  std::cout << r1 << " < " << r2 << ' ' << (r1 < r2 ? "TRUE" : "FALSE") << '\n';
  std::cout << r1 << " <= " << r2 << ' ' << (r1 <= r2 ? "TRUE" : "FALSE")
            << '\n';

  std::cout << "\n# 2. Complex numbers #\n";

  mathpp::Complex<long> c1 {0};
  mathpp::Complex<double> c2 {0};
  mathpp::Complex<mathpp::Rational> c3 {0};
  std::cout << "\n## Construct c1 = " << c1 << ", c2 = " << c2
            << " and c3 = " << c3 << " ##\n\n";
  std::cout << "-c1 = " << -c1 << '\n';
  std::cout << "-c2 = " << -c2 << '\n';
  std::cout << "-c3 = " << -c3 << '\n';

  c1 = 1;
  c2 = 1;
  c3 = 1;
  std::cout << "\n## Assign c1 = " << c1 << ", c2 = " << c2
            << " and c3 = " << c3 << " ##\n\n";
  std::cout << "-c1 = " << -c1 << '\n';
  std::cout << "-c2 = " << -c2 << '\n';
  std::cout << "-c3 = " << -c3 << '\n';

  c1 = mathpp::Complex<long>(0, 1);
  c2 = mathpp::Complex<double>(0, 1);
  c3 = mathpp::Complex<mathpp::Rational>(0L, 1L);
  std::cout << "\n## Assign c1 = " << c1 << ", c2 = " << c2
            << " and c3 = " << c3 << " ##\n\n";
  std::cout << "-c1 = " << -c1 << '\n';
  std::cout << "-c2 = " << -c2 << '\n';
  std::cout << "-c3 = " << -c3 << '\n';

  c1 = mathpp::Complex<long>(2, 2);
  c2 = mathpp::Complex<double>(2, 2);
  c3 = mathpp::Complex<mathpp::Rational>(2L, 2L);
  std::cout << "\n## Assign c1 = " << c1 << ", c2 = " << c2
            << " and c3 = " << c3 << " ##\n\n";
  std::cout << "-c1 = " << -c1 << '\n';
  std::cout << "-c2 = " << -c2 << '\n';
  std::cout << "-c3 = " << -c3 << '\n';

  c1 = mathpp::Complex<long>(2, -2);
  c2 = mathpp::Complex<double>(-2, 2);
  c3 = mathpp::Complex<mathpp::Rational>({2L, 3L}, {3L, 4L});
  std::cout << "\n## Assign c1 = " << c1 << ", c2 = " << c2
            << " and c3 = " << c3 << " ##\n\n";
  std::cout << "-c1 = " << -c1 << '\n';
  std::cout << "-c2 = " << -c2 << '\n';
  std::cout << "-c3 = " << -c3 << '\n';
}
