/**
 * @file num_theory.h
 * @brief Provides utilities for calculations in numbers theory
 */

#ifndef NUM_THEORY_H
#define NUM_THEORY_H

// - - - - - - System includes - - - - - -

// - - - - - - External library includes - - - - - -

// - - - - - - Project includes - - - - - -

#include "types/Rational.h"

// - - - - - - Used namespaces or types - - - - - -

/**
 * @brief Specifies the namespace for the library libmathpp
 */
namespace mathpp {

  /**
   * @brief Specifies the namespace for numbers theory of the library libmathpp
   */
  namespace num_th {

    /**
     * @brief Calculates |x| = x, x >= 0 and |x| = -x, x < 0
     */
    template <typename T>
    T abs(const T& x);

    // - - - - - - Inline definitions - - - - - -

    template <typename T>
    inline T abs(const T& x) {
      return std::abs(x);
    }

    template <>
    inline Rational abs(const Rational& r) {
      return r >= Rational(0L) ? r : -r;
    }

  }  // namespace num_th

}  // namespace mathpp

#endif
