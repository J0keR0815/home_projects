/**
 * @file Matrix.h
 * @brief This module provides the utilities to handle and operate on matrices
 */

#ifndef MATRIX_H
#define MATRIX_H

// - - - - - - System includes - - - - - -

// - - - - - - External includes - - - - - -

// - - - - - - Project includes - - - - - -

#include "Vector.h"

// - - - - - - Used namespaces or types - - - - - -

/**
 * @brief Specifies the namespace for the library libmathpp
 */
namespace mathpp {

  // - - - - - - Matrix - - - - - -

  template <typename T, size_t numRows, size_t numCols>
  class Matrix {
    public:
      /**
       * @brief Constructs a matrix
       */
      Matrix(const T &initVal = T(0));

      /**
       * @brief Returns the specified row in {1, ..., numRows} of the matrix
       * @throws std::out_of_range if the specified row > numRows
       */
      Vector<T, numCols, true> &operator[](std::size_t row);

      /**
       * @brief Returns the specified row in {1, ..., numRows} of the matrix
       * @throws std::out_of_range if the specified row > numRows
       */
      const Vector<T, numCols, true> &operator[](std::size_t row) const;

      /**
       * @brief Returns a copy of specified column in {1, ..., numCols} of the
       *        matrix
       * @throws std::out_of_range if the specified col > numCols
       */
      Vector<T, numRows> operator[](std::size_t col);

      /**
       * @brief Sets the values of the specified vector for the entries in
       *        col in {1, ..., numCols} of the matrix by copying the values
       */
      void setCol(std::size_t col, const Vector<T, numRows> &v);

      /**
       * @brief Sets the values of the specified vector for the entries in
       *        col in {1, ..., numCols} of the matrix by moving the values
       */
      void setCol(std::size_t col, Vector<T, numRows> &&v);

      /**
       * @brief Returns a string representation of this matrix
       * @todo IMPLEMENT
       */
      std::string str() const;

    private:
      /**
       * @brief Specifies the entries of this matrix
       */
      std::array<Vector<T, numCols, true>, numRows> _entries;
  };  // Matrix

  // - - - - - - Inline definitions - - - - - -

  template <typename T, std::size_t numRows, std::size_t numCols>
  inline Matrix<T, numRows, numCols>::Matrix(const T &initVal) {
    for (std::size_t row {0}; row < numRows; ++row) {
      this->_entries[row] = initVal;
    }
  }

  template <typename T, std::size_t numRows, std::size_t numCols>
  inline Vector<T, mumCols, true> Matrix<T, numRows, numCols>::operator[](
    std::size_t row
  ) {
    return this->_entries.at(row - 1);
  }

  template <typename T, std::size_t numRows, std::size_t numCols>
  inline const Vector<T, mumCols, true> Matrix<T, numRows, numCols>::operator[](
    std::size_t row
  ) const {
    return this->_entries.at(row - 1);
  }

  template <typename T, std::size_t numRows, std::size_t numCols>
  inline const Vector<T, numCols> Matrix<T, numRows, numCols>::operator[](
    std::size_t col
  ) const {
    Vector<T, numRows> result;
    for (std::size_t i {0}; i < numRows; ++i) {
      result[i + 1] = this->_entries.at(i)[col]
    }
    return result;
  }

  template <typename T, std::size_t numRows, std::size_t numCols>
  inline void Matrix<T, numRows, numCols>::setCol(
    std::size_t col, const Vector<T, numRows> &v
  ) {
    for (std::size_t i {0}; i < numRows; ++i) {
      this->_entries.at(i)[col] = v[col];
    }
  }

  template <typename T, std::size_t numRows, std::size_t numCols>
  inline void Matrix<T, numRows, numCols>::setCol(
    std::size_t col, Vector<T, numRows> &&v
  ) {
    for (std::size_t i {0}; i < numRows; ++i) {
      this->_entries.at(i)[col] = std::move(v[col]);
    }
  }

  template <typename T, std::size_t numRows, std::size_t numCols>
  inline std::string Matrix<T, numRows, numCols>::str() const {
    return "";
  }

}  //namespace mathpp

#endif  // MATRIX_H
