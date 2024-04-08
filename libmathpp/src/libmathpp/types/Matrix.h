/**
 * @file Matrix.h
 * @brief This module provides the utilities to handle and operate on matrices
 */

#ifndef MATRIX_H
#define MATRIX_H

// - - - - - - System includes - - - - - -

// - - - - - - External includes - - - - - -

// - - - - - - Project includes - - - - - -

// - - - - - - Matrix - - - - - -

template <typename T, size_t numRows, size_t numCols>
class Matrix {
  public:
    /**
     * @brief Constructs a matrix
     */
    Matrix(const T &initVal = T(0));

    /**
     * @brief Returns a string representation of this matrix
     */
    std::string str() const;

    /**
     * @brief Returns
     */
    std::vector<T> operator[](int indexRow);

    /**
     * @brief Specifies the entries of this matrix
     */
    std::vector<T> _entries;
};  // Matrix

// - - - - - - Inline definitions - - - - - -

template <typename T, std::size_t numRows, std::size_t numCols>
inline Matrix<T, numRows, numCols>::Matrix(const T &initVal) {
  std::size_t numEntries {numCols * numRows};
  this->_entries.reserve(numEntries);
  for (std::size_t i {0}; i < numEntries; ++i) {
    this->_entries = initVal;
  }
}

template <typename T, std::size_t numRows, std::size_t numCols>
inline std::string Matrix<T, numRows, numCols>::str() const {
  std::ostringstream ossResult;

  std::ostringstream ossRow;
  for (std::size_t indexRow {1}; indexRow <= numRows; ++indexRow) {
    ossRow << "| ";
    for (std::size_t col {1}; col <= numCols; ++col) {}
  }
}

#endif  // MATRIX_H
