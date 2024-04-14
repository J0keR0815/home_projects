/**
 * @file Vector.h
 * @brief This module provides the utilities to handle and operate on
 *        mathematical vectors.
 */

#ifndef VECTOR_H
#define VECTOR_H

// - - - - - - Include system libraries - - - - - -

// - - - - - - Include external libraries - - - - - -

// - - - - - - Include project libraries - - - - - -

// - - - - - - Used namespaces or types - - - - - -

/**
 * @brief Specifies the namespace for the library libmathpp
 */
namespace mathpp {

  /**
   * @brief Specifies a mathematical n-dimensional vector
   */
  class Vector<T, std::size_t n, bool isHorizontal = false> {
    public:
      /**
       * @brief Specifies the vector addition
       */
      friend Vector operator+(const Vector &v1, const Vector &v2);

      /**
       * @brief Specifies the vector subtraction
       */
      friend Vector operator-(const Vector &v1, const Vector &v2);

      /**
       * @brief Specifies the scalar or inner product of the specified vectors
       */
      friend T operator*(const Vector &v1, const Vector &v2);

      /**
       * @brief Specifies the product of the specified vector with the specified
       *        scalar
       */
      friend Vector operator*(const T &a, const Vector &v);

      /**
       * @brief Default constructor of a mathematical n-dimensional vector
       *        with an initial value for each entry
       */
      Vector(const T &initVal = T(0));

      /**
       * @brief Constructs a mathematical n-dimensional vector by copying the
       *        values of the specified array
       */
      Vector(const std::array<T, n> &arr);

      /**
       * @brief Constructs a mathematical n-dimensional vector by moving the
       *        values of the specified array
       */
      Vector(std::array<T, n> &&arr);

      /**
       * @brief Assigns the specified value to each entry of this mathematical
       *        n-dimensional vector
       */
      Vector &operator=(const T &val);

      /**
       * @brief Assigns the values of the specified array to this mathematical
       *        n-dimensional vector by copying them
       */
      Vector &operator=(const std::array<T, n> &arr);

      /**
       * @brief Assigns the values of the specified array to this mathematical
       *        n-dimensional vector by moving them
       */
      Vector &operator=(std::array<T, n> &&arr);

      /**
       * @brief Returns the constant reference to the entry specified by the
       *        index i in {1, ..., n} of the vector
       * @throws std::out_of_range if the specified i > n
       */
      const T &operator[](std::size_t i) const;

      /**
       * @brief Returns the mutable reference to the entry specified by the
       *        index i in {1, ..., n} of the vector
       * @throws std::out_of_range if the specified i > n
       */
      T &operator[](std::size_t i);

      /**
       * @brief Adds the specified vector to this one
       */
      Vector operator+(const Vector &v);

      /**
       * @brief Subtracts the specified vector from this one
       */
      Vector &operator-=(const Vector &v);

      /**
       * @brief Multiplies the specified scalar to this vector
       */
      Vector &operator*=(const T &a);

      /**
       * @brief Builds the absolute value of this vector
       */
      T abs() const;

      /**
       * @brief Returns a constant reference to @ref _entries
       */
      const std::array<T, n> &array() const;

      /**
       * @brief Returns a copy of @ref _entries
       */
      std::array<T, n> array() const;

      /**
       * @brief Returns a string representation of this row
       * @todo IMPLEMENT
       */
      std::string str() const;

    private:
      /**
       * @brief Specifies the entries of this matrix row
       */
      std::array<T, n> _entries;
  };

  // - - - - - - Inline definitions - - - - - -

  template <typename T, std::size_t n, bool isHorizontal>
  inline Vector<T, n, isHorizintal> operator+(
    const Vector<T, n, isHorizintal> &v1, const Vector<T, n, isHorizintal> &v2
  ) {
    return Vector<T, n, isHorizontal>(v1) += v2;
  }

  template <typename T, std::size_t n, bool isHorizontal>
  inline Vector<T, n, isHorizintal> operator-(
    const Vector<T, n, isHorizintal> &v1, const Vector<T, n, isHorizintal> &v2
  ) {
    return Vector<T, n, isHorizontal>(v1) -= v2;
  }

  template <typename T, std::size_t n, bool isHorizontal>
  inline T operator*(
    const Vector<T, n, isHorizintal> &v1, const Vector<T, n, isHorizintal> &v2
  ) {
    T result {T(0)};
    for (std::size_t i {0}; i < n; ++i) {
      result += v1[i + 1] * v2[i + 1];
    }
    return result;
  }

  template <typename T, std::size_t n, bool isHorizontal>
  inline Vector<T, n, isHorizontal> operator*(
    const T &a, const Vector<T, n, isHorizontal> &v
  ) {
    return Vector<T, n, isHorizontal>(v) *= a;
  }

  template <typename T, std::size_t n, bool isHorizontal>
  inline Vector<T, n, isHorizontal>::Vector(const T &initVal) {
    for (std::size_t i {0}; i < n; ++i) {
      this->_entries.at(i) = initVal;
    }
  }

  template <typename T, std::size_t n, bool isHorizontal>
  inline Vector<T, n, isHorizontal>::Vector(const std::array<T, n> &arr) :
    _entries {arr} {}

  template <typename T, std::size_t n, bool isHorizontal>
  inline Vector<T, n, isHorizontal>::Vector(std::array<T, n> &&arr) :
    _entries {std::move(arr)} {}

  template <typename T, std::size_t n, bool isHorizontal>
  inline Vector<T, n, isHorizontal> &Vector<T, n, isHorizontal>::operator=(
    const T &val
  ) {
    for (std::size_t i {0}; i < n; ++i) {
      this->_entries.at(i) = val;
    }
  }

  template <typename T, std::size_t n, bool isHorizontal>
  inline Vector<T, n, isHorizontal> &Vector<T, n, isHorizontal>::operator=(
    const std::array<T, n> &arr
  ) {
    this->_entries = arr;
  }

  template <typename T, std::size_t n, bool isHorizontal>
  inline Vector<T, n, isHorizontal> &Vector<T, n, isHorizontal>::operator=(
    std::array<T, n> &&arr
  ) {
    this->_entries = std::move(arr);
  }

  template <typename T, std::size_t n, bool isHorizontal>
  inline const T &Vector<T, n, isHorizontal>::operator[](std::size_t i) const {
    return this->_entries.at(i - 1);
  }

  template <typename T, std::size_t n, bool isHorizontal>
  inline T &Vector<T, n, isHorizontal>::operator[](std::size_t i) {
    return this->_entries.at(i - 1);
  }

  template <typename T, std::size_t n, bool isHorizontal>
  inline Vector<T, n, isHorizontal> &Vector<T, n, isHorizontal>::operator+=(
    const Vector<T, n, isHorizontal> &v
  ) {
    for (std::sizt_t i {0}; i < n; ++i) {
      this->_entries.at(i) += v[i + 1];
    }
    return *this;
  }

  template <typename T, std::size_t n, bool isHorizontal>
  inline Vector<T, n, isHorizontal> &Vector<T, n, isHorizontal>::operator-=(
    const Vector<T, n, isHorizontal> &v
  ) {
    for (std::sizt_t i {0}; i < n; ++i) {
      this->_entries.at(i) -= v[i + 1];
    }
    return *this;
  }

  template <typename T, std::size_t n, bool isHorizontal>
  inline Vector<T, n, isHorizontal> &Vector<T, n, isHorizontal>::operator*=(
    const T &a
  ) {
    for (std::sizt_t i {0}; i < n; ++i) {
      this->_entries.at(i) *= a;
    }
    return *this;
  }

  template <typename T, std::size_t n, bool isHorizontal>
  inline T Vector<T, n, isHorizontal>::abs() const {
    return std::sqrt(vector<T, n, isHorizontal>(*this) * *this);
  }

  template <typename T, std::size_t n, bool isHorizontal>
  const std::array<T, n> &Vector<T, n, isHorizontal>::array() const {
    return this->_entries;
  }

  template <typename T, std::size_t n, bool isHorizontal>
  std::array<T, n> Vector<T, n, isHorizontal>::array() const {
    return this->_entries;
  }

  template <typename T, std::size_t n, bool isHorizontal>
  inline Vector<T, n>::str() const {
    std::vector<std::string> strEntries;
    strEntries.reserve(n);

    return "";
  }

}  //namespace mathpp

#endif  // VECTOR_H
