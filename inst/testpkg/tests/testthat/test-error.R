# This tests the error-generating machinery throughout the package.
# library(testthat); source("test-error.R")

expect_fixed_error <- function(...) { expect_error(..., fixed=TRUE) }

# Simple matrix doesn't need checking; correct dimensions is enforced,
# and can't even be changed by directly modifying the attributes.

a <- matrix(100, 10, 10)

test_that("Simple matrix errors thrown", {
    expect_fixed_error(attributes(a)$dim <- c(-1L, 10L))
    attributes(a)$dim <- c(10, 10)
    expect_type(attributes(a)$dim, "integer") # type does not change.
    expect_fixed_error(attributes(a)$dim <- c(5L, 5L))
})

# Dense matrix

library(Matrix)
A <- Matrix(1:50, 5, 10)

test_that("Dense matrix errors thrown", {
    wrong <- A
    expect_fixed_error(storage.mode(wrong@Dim) <- "double")
    wrong@Dim <- c(5L, 5L)
    expect_fixed_error(.Call(beachtest:::cxx_test_numeric_access, wrong, 1L, NULL), 
                       "length of 'x' in a dgeMatrix object is inconsistent with its dimensions")
})

# Csparse matrix

set.seed(234234)
A <- rsparsematrix(10, 20, 0.5)
    
test_that("Sparse matrix errors thrown", {
    wrong <- A
    expect_fixed_error(storage.mode(wrong@Dim) <- "double")
    wrong@Dim <- c(5L, 10L)
    expect_fixed_error(.Call(beachtest:::cxx_test_numeric_access, wrong, 1L, NULL), 
                       "length of 'p' slot in a dgCMatrix object should be equal to 'ncol+1'")
    
    wrong <- A
    expect_fixed_error(storage.mode(wrong@p) <- "double")
    wrong@p[1] <- -1L
    expect_fixed_error(.Call(beachtest:::cxx_test_numeric_access, wrong, 1L, NULL),
                       "first element of 'p' in a dgCMatrix object should be 0")
    wrong <- A
    wrong@p[ncol(A)+1] <- -1L
    expect_fixed_error(.Call(beachtest:::cxx_test_numeric_access, wrong, 1L, NULL), 
                       "last element of 'p' in a dgCMatrix object should be 'length(x)'")
    wrong <- A
    wrong@p[2] <- wrong@p[2]+100L
    expect_fixed_error(.Call(beachtest:::cxx_test_numeric_access, wrong, 1L, NULL), 
                       "'p' slot in a dgCMatrix object should be sorted")
    wrong <- A
    wrong@p <- wrong@p[1]
    expect_fixed_error(.Call(beachtest:::cxx_test_numeric_access, wrong, 1L, NULL), 
                       "length of 'p' slot in a dgCMatrix object should be equal to 'ncol+1'")
    
    wrong <- A
    expect_fixed_error(storage.mode(wrong@i) <- "double")
    wrong@i <- rev(wrong@i)
    expect_fixed_error(.Call(beachtest:::cxx_test_numeric_access, wrong, 1L, NULL), 
                       "'i' in each column of a dgCMatrix object should be sorted")
    wrong <- A
    wrong@i <- wrong@i[1]
    expect_fixed_error(.Call(beachtest:::cxx_test_numeric_access, wrong, 1L, NULL),
                       "'x' and 'i' slots in a dgCMatrix object should have the same length")
    wrong <- A
    wrong@i <- wrong@i*100L
    expect_fixed_error(.Call(beachtest:::cxx_test_numeric_access, wrong, 1L, NULL), 
                       "'i' slot in a dgCMatrix object should contain elements in [0, nrow)")
    
    wrong <- A
    wrong@x <- wrong@x[1]
    expect_fixed_error(.Call(beachtest:::cxx_test_numeric_access, wrong, 1L, NULL),  
                       "'x' and 'i' slots in a dgCMatrix object should have the same length")
    
    # Tsparse matrix
    
    A <- as(rsparsematrix(10, 20, 0.5), "dgTMatrix")
    expect_fixed_error(.Call(beachtest:::cxx_test_numeric_access, A, 1L, NULL), 
                       "dgTMatrix not supported, convert to dgCMatrix")
    
    B <- A!=0
    expect_fixed_error(.Call(beachtest:::cxx_test_logical_access, B, 1L, NULL), 
                       "lgTMatrix not supported, convert to lgCMatrix")
})
    
# Packed symmetric matrices.

A <- pack(forceSymmetric(matrix(1:10, 10, 10))) 

test_that("Sparse matrix errors thrown", {
    wrong <- A
    expect_fixed_error(storage.mode(wrong@Dim) <- "double")
    wrong@Dim <- c(5L, 5L)
    expect_fixed_error(.Call(beachtest:::cxx_test_numeric_access, wrong, 1L, NULL),
                       "length of 'x' in a dspMatrix object is inconsistent with its dimensions")
    wrong@Dim <- c(10L, 5L)
    expect_fixed_error(.Call(beachtest:::cxx_test_numeric_access, wrong, 1L, NULL),
                       "'nrow' and 'ncol' should be equal for a dspMatrix object")
    
    wrong <- A
    wrong@uplo <- "W"
    expect_fixed_error(.Call(beachtest:::cxx_test_numeric_access, wrong, 1L, NULL),
                       "'uplo' slot in a dspMatrix object should be either 'U' or 'L'")
    expect_fixed_error(wrong@uplo <- 1L, NULL)
    
    wrong <- A
    wrong@x <- wrong@x[1]
    expect_fixed_error(.Call(beachtest:::cxx_test_numeric_access, wrong, 1L, NULL), 
                       "length of 'x' in a dspMatrix object is inconsistent with its dimensions")
})

# HDF5 matrices.

library(HDF5Array)
test.mat <- matrix(150, 15, 10)
A <- as(test.mat, "HDF5Array")

test_that("HDF5 matrix errors thrown", {
    wrong <- A
    wrong@seed <- Matrix(1)
    expect_fixed_error(.Call(beachtest:::cxx_test_numeric_access, wrong, 1L, NULL), 
                       "'seed' slot in a HDF5Matrix object should be a HDF5ArraySeed object")
    
    wrong <- A
    expect_fixed_error(storage.mode(wrong@seed@dim) <- "double")
    wrong@seed@dim <- c(10L, 5L)
    expect_fixed_error(.Call(beachtest:::cxx_test_numeric_access, wrong, 1L, NULL), 
                       "dimensions in HDF5 file do not equal dimensions in the HDF5Matrix object")
    
    wrong <- A
    expect_fixed_error(wrong@seed@filepath <- 1)
    wrong@seed@filepath <- c("YAY", "YAY")
    expect_fixed_error(.Call(beachtest:::cxx_test_numeric_access, wrong, 1L, NULL), 
                       "'filepath' slot in a HDF5ArraySeed object should be a string")

    wrong <- A
    expect_fixed_error(wrong@seed@name <- 1)
    wrong@seed@name <- c("YAY", "YAY")
    expect_fixed_error(.Call(beachtest:::cxx_test_numeric_access, wrong, 1L, NULL), 
                       "'name' slot in a HDF5ArraySeed object should be a string")
})

# Numeric checks

test_that("Numeric errors thrown", {
    b <- matrix(100L, 10, 10)
    expect_fixed_error(.Call(beachtest:::cxx_test_numeric_access, b, 1L, NULL), "matrix should be double")
    
    B <- Matrix(1:50, 5, 10)
    storage.mode(B@x) <- "integer"
    expect_fixed_error(.Call(beachtest:::cxx_test_numeric_access, B, 1L, NULL), 
                       "'x' slot in a dgeMatrix object should be double")
    
    set.seed(234234)
    B <- rsparsematrix(10, 20, 0.5)
    storage.mode(B@x) <- "integer"
    expect_fixed_error(.Call(beachtest:::cxx_test_numeric_access, B, 1L, NULL), 
                       "'x' slot in a dgCMatrix object should be double")
    
    B <- pack(forceSymmetric(matrix(1:10, 10, 10)))
    storage.mode(B@x) <- "integer"
    expect_fixed_error(.Call(beachtest:::cxx_test_numeric_access, B, 1L, NULL), 
                       "'x' slot in a dspMatrix object should be double")
    
    test.mat <- matrix(150L, 15, 10)
    B <- as(test.mat, "HDF5Array")
    expect_fixed_error(.Call(beachtest:::cxx_test_numeric_access, B, 1L, NULL), 
                       "'first_val' slot in a HDF5ArraySeed object should be double")
    storage.mode(B@seed@first_val) <- "double"
    expect_fixed_error(.Call(beachtest:::cxx_test_numeric_access, B, 1L, NULL), 
                       "data type in HDF5 file is not double")
})

# Logical checks

test_that("Logical errors thrown", {
    b <- matrix(100L, 10, 10)
    expect_fixed_error(.Call(beachtest:::cxx_test_logical_access, b, 1L, NULL), "matrix should be logical")
    
    B <- Matrix(c(TRUE, FALSE), 5, 10)
    expect_fixed_error(storage.mode(B@x) <- "integer")
    
    set.seed(234234)
    B <- rsparsematrix(10, 20, 0.5)!=0
    expect_fixed_error(storage.mode(B@x) <- "integer")
    
    B <- as(rsparsematrix(10, 20, 0.5)!=0, "lgTMatrix")
    expect_fixed_error(storage.mode(B@x) <- "integer")
    
    B <- pack(forceSymmetric(matrix(c(TRUE, FALSE), 10, 10)))
    expect_fixed_error(storage.mode(B@x) <- "integer")
    
    test.mat <- matrix(150, 15, 10)
    B <- as(test.mat, "HDF5Array")
    expect_fixed_error(.Call(beachtest:::cxx_test_logical_access, B, 1L, NULL), 
                       "'first_val' slot in a HDF5ArraySeed object should be logical")
    storage.mode(B@seed@first_val) <- "logical"
    expect_fixed_error(.Call(beachtest:::cxx_test_logical_access, B, 1L, NULL), 
                       "data type in HDF5 file is not logical")
})

# Integer checks

test_that("Integer errors thrown", {
    b <- matrix(1, 10, 10)
    expect_fixed_error(.Call(beachtest:::cxx_test_integer_access, b, 1L, NULL), "matrix should be integer")

    test.mat <- matrix(150, 15, 10)
    B <- as(test.mat, "HDF5Array")
    expect_fixed_error(.Call(beachtest:::cxx_test_integer_access, B, 1L, NULL), 
                       "'first_val' slot in a HDF5ArraySeed object should be integer")
    storage.mode(B@seed@first_val) <- "integer"
    expect_fixed_error(.Call(beachtest:::cxx_test_integer_access, B, 1L, NULL), 
                       "data type in HDF5 file is not integer")
})
