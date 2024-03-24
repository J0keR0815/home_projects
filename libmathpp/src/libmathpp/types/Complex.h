/**
 * @file Complex.h
 * @brief Provides the utilities to use complex numbers
 */

#ifndef COMPLEX_H
#define COMPLEX_H

// - - - - - - System includes - - - - - -

#include <cmath>

// - - - - - - External library includes - - - - - -

// - - - - - - Project includes - - - - - -

#include <types/Rational.h>

// - - - - - - Used namespaces or types - - - - - -

/**
 * @brief Specifies the namespace for the library libmathpp
 */
namespace mathpp {

  // - - - - - - Complex - - - - - -

  /**
   * @brief Specifies a class for complex numbers with
   *        c in {a + ib | a, b are real numbers,
   *              a is the real part, b is the imaginary part}
   * @note Alternatively the polar form can be used with:
   *       c in {r * exp(phi) | r, phi are real numbers}
   */
  template <typename T = double>
  class Complex {
    public:
      /**
       * @brief Writes string representation of the complex number into the
       *        output stream
       */
      template <typename NumType>
      friend std::ostream &operator<<(
        std::ostream &os, const Complex<NumType> &c
      );

      /**
       * @brief Returns the negative value of the complex number
       */
      template <typename NumType>
      friend Complex<NumType> operator-(const Complex<NumType> &c);

      /**
       * @brief Swaps the values of the complex numbers c1 and c2
       */
      template <typename NumType>
      friend void swap(Complex<NumType> &c1, Complex<NumType> &c2);

      /**
       * @brief Constructor for a complex number specifying only the real part
       *        and setting the imaginary part = 0
       */
      Complex(const T &re = 0);

      /**
       * @brief Constructor for a complex number specifying the real part and
       *        the imaginary part
       */
      explicit Complex(const T &re, const T &im);

      /**
       * @brief Constructor using the polar form.
       * @param polarCoords Specifies a pair containing the value r and
       *        the angle phi in radiant of the polar form
       */
      explicit Complex(std::pair<T, double> &&polarCoords);

      /**
       * @brief Copy assigns a numeric value to this complex number
       */
      Complex operator=(const T &val);

      /**
       * @brief Move assigns a numeric value to this complex number
       */
      Complex operator=(T &&val);

      /**
       * @brief Returns a string representation of this complex number
       */
      std::string str() const;

    private:
      /**
       * @brief Specifies the imaginary part
       */
      T _im;

      /**
       * @brief Specifies if the class was initialised with real and imaginary
       *        part (false) or in polar form (true)
       */
      bool _isPolar;

      /**
       * @brief Angle phiRad of the polar form
       */
      double _phiRad;

      /**
       * @brief Value r of the polar form
       */
      double _r;

      /**
       * @brief Specifies the real part
       */
      T _re;

      /**
       * @brief Normalises the specified angle to a value phi in [-PI : PI]
       */
      static double normAngle(double phi);
  };

  // - - - - - - Inline definitions - - - - - -
  template <typename NumType>
  inline std::ostream &operator<<(std::ostream &os, const Complex<NumType> &c) {
    return os << c.str();
  }

  template <typename NumType>
  inline Complex<NumType> operator-(const Complex<NumType> &c) {
    if (c._isPolar) {
      return Complex<NumType>(std::make_pair<>(-c._r, c._phiRad));
    }
    return Complex<NumType>(-c._re, -c._im);
  }

  template <typename NumType>
  inline void swap(Complex<NumType> &c1, Complex<NumType> &c2) {
    std::swap(c1._im, c2._im);
    std::swap(c1._isPolar, c2._isPolar);
    std::swap(c1._phiRad, c2._phiRad);
    std::swap(c1._r, c2._r);
    std::swap(c1._re, c2._re);
  }

  template <typename T>
  inline double Complex<T>::normAngle(double phi) {
    double nPhi {phi / M_PI};
    long nPhiInt {static_cast<long>(std::floor(nPhi))};
    if ((nPhiInt & 1) == 1) {
      // Uneven integer part of nPhi: Quadrant 3 or 4
      return (nPhi - nPhiInt) * M_PI - M_PI;
    } else {
      // Even integer part of nPhi: Quadrant 1 or 2
      return (nPhi - nPhiInt) * M_PI;
    }
  }

  template <typename T>
  inline Complex<T>::Complex(const T &re) : Complex<T>(re, 0) {}

  template <typename T>
  inline Complex<T>::Complex(const T &re, const T &im) :
    _isPolar {false},
    _im {im},
    _re {re} {
    T typeVal0 {0L};

    // Calculate values depending on the specified values
    if (this->_re == typeVal0 && this->_im == typeVal0) {
      // c = 0 + i0 = r * exp(i*phi) => set r = 0 and phi = 0
      this->_r = 0;
      this->_phiRad = 0;
    } else if (this->_re == typeVal0) {
      /*
       * c = i*im = r * exp(i*phi) => set r = |im| and
       * phi = PI / 2, im > 0 or phi = PI / 2, im < 0
       */
      this->_r = this->_im < typeVal0 ? -this->_im : this->_im;
      this->_phiRad = this->_im < typeVal0 ? -0.5 * M_PI : 0.5 * M_PI;
    } else if (this->_im == typeVal0) {
      /*
       * c = re = r * exp(i*phi) => set r = |re| and
       * phi = 0, re > 0 or phi = PI, re < 0
       */
      this->_r = this->_re < typeVal0 ? -this->_re : this->_re;
      this->_phiRad = this->_re < typeVal0 ? M_PI : 0;
    } else {
      // Non-trivial case: c = re + i*im => Calculate r and phi
      this->_r = std::sqrt(this->_re * this->_re + this->_im * this->_im);
      this->_phiRad = std::atan2(this->_im, this->_re);
    }
  }

  template <typename T>
  inline Complex<T>::Complex(std::pair<T, double> &&polarCoords) :
    _isPolar {true} {
    T r {std::move(polarCoords.first)};
    double phiRad {std::move(polarCoords.second)};
    T typeVal0 {0L};

    // r = 0 <=> c = 0 + i0
    if (r == typeVal0) {
      Complex<T> tmp;
      swap(*this, tmp);
      return;
    }

    // If r < 0 get the absolute value and add PI to the angle
    if (r < typeVal0) {
      r = -r;
      phiRad = M_PI + phiRad;
    }

    // Get x = phi / PI (Normalising phi by PI with phi = x * PI)
    double x {phiRad / M_PI};
    if (x - std::floor(x) == 0) {
      // phi is a multiple of PI (x is an integer)
      T re {std::move(r)};
      if ((static_cast<long>(x) & 1) == 1) {
        re = -re;
      }
      Complex<T> tmp {re};
      swap(*this, tmp);
      return;
    } else if (x - std::floor(x) == 0.5) {
      // phi is a multiple of PI / 2 (real part = 0)
      T im {std::move(r)};
      if ((static_cast<long>(x - 0.5) & 1) == 1) {
        im = -im;
      }
      Complex<T> tmp {0, im};
      swap(*this, tmp);
      return;
    }

    // phi has real and imagninary part
    this->_phiRad = Complex<T>::normAngle(phiRad);
    this->_r = r;
    this->_im = this->_r * cos(this->_phiRad);
    this->_re = this->_r * sin(this->_phiRad);
  }

  template <typename T>
  inline Complex<T> Complex<T>::operator=(const T &val) {
    Complex<T> tmp {val};
    swap(*this, tmp);
    return *this;
  }

  template <typename T>
  inline Complex<T> Complex<T>::operator=(T &&val) {
    Complex<T> tmp {std::move(val)};
    swap(*this, tmp);
    return *this;
  }

  template <typename T>
  inline std::string Complex<T>::str() const {
    std::ostringstream oss;
    oss << this->_re << " + i * " << this->_im << " = " << this->_r
        << " * exp(i * " << this->_phiRad << " = i * " << (this->_phiRad / M_PI)
        << " * PI)";
    return oss.str();
  }
}  // namespace mathpp

#endif
