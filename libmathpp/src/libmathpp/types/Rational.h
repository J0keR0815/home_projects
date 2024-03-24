/**
 * @file Rational.h
 * @brief Provides the utilities to use rational numbers
 */

#ifndef RATIONAL_H
#define RATIONAL_H

// - - - - - - System includes - - - - - -

#include <cmath>
#include <numeric>
#include <sstream>

// - - - - - - External library includes - - - - - -

// - - - - - - Project includes - - - - - -

// - - - - - - Used namespaces or types - - - - - -

/**
 * @brief Specifies the namespace for the library libmathpp
 */
namespace mathpp {

  // - - - - - - Rational - - - - - -

  /**
   * @brief Specifies a class for rational numbers with
   *        r in {a / b | a, b are integers and b != 0}
   */
  class Rational {
    public:
      /**
       * @brief Writes string representation of the rational number into the
       *        output stream
       */
      friend std::ostream &operator<<(std::ostream &os, const Rational &r);

      /**
       * @brief Addition of two rational numbers
       */
      friend Rational operator+(const Rational &r1, const Rational &r2);

      /**
       * @brief Returns the negativa value of the number
       */
      friend Rational operator-(const Rational &r);

      /**
       * @brief Substraction of two rational numbers
       */
      friend Rational operator-(const Rational &r1, const Rational &r2);

      /**
       * @brief Multiplication of two rational numbers
       */
      friend Rational operator*(const Rational &r1, const Rational &r2);

      /**
       * @brief Division of two rational numbers
       */
      friend Rational operator/(const Rational &r1, const Rational &r2);

      /**
       * @brief Checks if r1 equals r2
       */
      friend bool operator==(const Rational &r1, const Rational &r2);

      /**
       * @brief Checks if r1 not equals r2
       */
      friend bool operator!=(const Rational &r1, const Rational &r2);

      /**
       * @brief Checks if r1 > r2
       */
      friend bool operator>(const Rational &r1, const Rational &r2);

      /**
       * @brief Checks if r1 >= r2
       */
      friend bool operator>=(const Rational &r1, const Rational &r2);

      /**
       * @brief Checks if r1 < r2
       */
      friend bool operator<(const Rational &r1, const Rational &r2);

      /**
       * @brief Checks if r1 <= r2
       */
      friend bool operator<=(const Rational &r1, const Rational &r2);

      /**
       * @brief Swaps values of the rational numbers r1 and r2
       */
      friend void swap(Rational &r1, Rational &r2);

      /**
       * @brief Default constructor for the rational number = 0
       */
      Rational();

      /**
       * @brief Constructor for rational number with numerator and denominator
       * @throws std::invalid_argument if denominator = 0
       */
      Rational(long numerator, long denominator = 1L);

      /**
       * @brief Constructor for rational number using a double value
       * @param r Specifies the real number which should be converted into a
       *        rational number
       * @param prec The precision of the decimal places of r the conversion
       *        should be done with
       */
      explicit Rational(double r, std::size_t prec = 0);

      /**
       * @brief Assigns an integer value to this object
       */
      Rational &operator=(long intVal);

      /**
       * @brief Assigns a double value to this object with precision = 9 of the
       *        decimal places of r
       */
      Rational &operator=(double intVal);

      /**
       * @brief Adds rational number to this one
       */
      Rational &operator+=(const Rational &r);

      /**
       * @brief Substracts rational number from this one
       */
      Rational &operator-=(const Rational &r);

      /**
       * @brief Multiplies this number by the specified rational number
       */
      Rational &operator*=(const Rational &r);

      /**
       * @brief Divides this number by the specified rational number
       * @throws std::invalid_argument if r = 0
       */
      Rational &operator/=(const Rational &r);

      /**
       * @brief Returns the rational number as double value
       */
      operator double() const;

      /**
       * @brief Returns the recipro of this rational number
       * @throws std::logic_error instance if @ref _numerator = 0
       */
      Rational recipro() const;

      /**
       * @brief Returns a string represenation of this rational number
       */
      std::string str() const;

    private:
      /**
       * @brief Specifies the sign of this number (1: Positive number,
       *        -1: Negative number)
       */
      int _sign {1};

      /**
       * @brief Specifies the absolute value of the numerator (dividend)
       */
      long _numerator {0};

      /**
       * @brief Specifies the absolute value of the denominator (quotient) which
       *        cannot be 0
       */
      long _denominator {1};

      /**
       * @brief Reduces @ref _numerator and @ref _denominator by dividing with
       *        the std::gcd and returns this rational number
       */
      Rational &reduce();

      /**
       * @brief Calculates the correct sign for this number and returns this
       *        rational number
       */
      Rational &sign();
  };

  // - - - - - - Inline definitions - - - - - -

  // - - - - - - friends mathpp::Rational - - - - - -

  inline std::ostream &operator<<(std::ostream &os, const Rational &r) {
    return os << r.str();
  }

  inline Rational operator+(const Rational &r1, const Rational &r2) {
    return Rational(r1) += r2;
  }

  inline Rational operator-(const Rational &r) {
    if (r._numerator == 0) {
      return r;
    }

    Rational tmp(r);
    tmp._sign = -tmp._sign;
    return tmp;
  }

  inline Rational operator-(const Rational &r1, const Rational &r2) {
    return Rational(r1) -= r2;
  }

  inline Rational operator*(const Rational &r1, const Rational &r2) {
    return Rational(r1) *= r2;
  }

  inline Rational operator/(const Rational &r1, const Rational &r2) {
    return Rational(r1) /= r2;
  }

  inline bool operator==(const Rational &r1, const Rational &r2) {
    return r1._sign == r2._sign && r1._numerator == r2._numerator
           && r1._denominator == r2._denominator;
  }

  inline bool operator!=(const Rational &r1, const Rational &r2) {
    return !(r1 == r2);
  }

  inline bool operator>(const Rational &r1, const Rational &r2) {
    long lcm {std::lcm(r1._denominator, r2._denominator)};
    return r1._sign * (lcm / r1._denominator) * r1._numerator
           > r2._sign * (lcm / r2._denominator) * r2._numerator;
  }

  inline bool operator>=(const Rational &r1, const Rational &r2) {
    return r1 == r2 || r1 > r2;
  }

  inline bool operator<(const Rational &r1, const Rational &r2) {
    return r2 > r1;
  }

  inline bool operator<=(const Rational &r1, const Rational &r2) {
    return r2 >= r1;
  }

  inline void swap(Rational &r1, Rational &r2) {
    std::swap(r1._sign, r2._sign);
    std::swap(r1._numerator, r2._numerator);
    std::swap(r1._denominator, r2._denominator);
  }

  // - - - - - - mathpp::Rational - - - - - -

  inline Rational::Rational() : Rational(0L) {}

  inline Rational::Rational(long numerator, long denominator) :
    _numerator {numerator},
    _denominator {denominator} {
    if (this->_denominator == 0) {
      throw std::invalid_argument("Denominator cannot be 0");
    }
    this->sign();
    this->reduce();
  }

  inline Rational::Rational(double r, std::size_t prec) {
    // If r = 0 => Use default constructor
    if (r == 0) {
      Rational tmp;
      swap(*this, tmp);
      return;
    }

    // If prec = 0 => Handle r as an integer
    if (prec == 0) {
      Rational tmp {static_cast<long>(r)};
      swap(*this, tmp);
      return;
    }

    // Split integer and decimal part
    this->_sign = r < 0 ? -1 : 1;
    double abs {std::abs(r)};
    long absIntVal {static_cast<long>(std::floor(abs))};
    long denominator {static_cast<long>(std::pow(10, prec))};
    long absDecVal {
      static_cast<long>((absIntVal == 0 ? abs : abs - absIntVal) * denominator)
    };
    Rational tmp {Rational(absIntVal) + Rational(absDecVal, denominator)};
    swap(*this, tmp);
  }

  inline Rational &Rational::operator=(long intVal) {
    Rational tmp(intVal);
    swap(*this, tmp);
    return *this;
  }

  inline Rational &Rational::operator=(double r) {
    Rational tmp(r, 9);
    swap(*this, tmp);
    return *this;
  }

  inline Rational &Rational::operator+=(const Rational &r) {
    long lcm {std::lcm(this->_denominator, r._denominator)};
    this->_numerator =
      this->_sign * (lcm / this->_denominator) * this->_numerator
      + r._sign * (lcm / r._denominator) * r._numerator;
    this->_denominator = lcm;
    this->sign();
    return this->reduce();
  }

  inline Rational &Rational::operator-=(const Rational &r) {
    return this->operator+=(-r);
  }

  inline Rational &Rational::operator*=(const Rational &r) {
    this->_numerator *= this->_sign * r._sign * r._numerator;
    this->_denominator *= r._denominator;
    this->sign();
    return this->reduce();
  }

  inline Rational &Rational::operator/=(const Rational &r) {
    return this->operator*=(r.recipro());
  }

  inline Rational::operator double() const {
    return this->_sign * static_cast<double>(this->_numerator)
           / this->_denominator;
  }

  inline Rational Rational::recipro() const {
    return Rational(this->_sign * this->_denominator, this->_numerator);
  }

  inline std::string Rational::str() const {
    std::ostringstream oss;
    oss << (this->_sign < 0 ? "-" : "") << this->_numerator;
    if (this->_denominator != 1) {
      oss << " / " << this->_denominator;
    }
    return oss.str();
  }

  inline Rational &Rational::reduce() {
    // Check if 0
    if (this->_numerator == 0) {
      this->_denominator = 1;
      return *this;
    }

    // Divide by greatest common divisor
    long gcd {std::gcd(this->_numerator, this->_denominator)};
    if (gcd > 1) {
      this->_numerator /= gcd;
      this->_denominator /= gcd;
    }
    return *this;
  }

  inline Rational &Rational::sign() {
    this->_sign = 1;

    if (this->_numerator < 0) {
      this->_sign = -this->_sign;
      this->_numerator = -this->_numerator;
    }

    if (this->_denominator < 0) {
      this->_sign = -this->_sign;
      this->_denominator = -this->_denominator;
    }

    return *this;
  }

}  // namespace mathpp

#endif
