#ifndef CNCRT_POLYNOMIAL_MATH_H
#define CNCRT_POLYNOMIAL_MATH_H

#include "crypto/torus.cuh"
#include "parameters.cuh"
#include "polynomial.cuh"

template <typename FT, class params>
__device__ void sub_polynomial(FT *result, FT *first, FT *second) {
  int tid = threadIdx.x;
  for (int i = 0; i < params::opt; i++) {
    result[tid] = first[tid] - second[tid];
    tid += params::degree / params::opt;
  }
}

template <class params, typename T>
__device__ void polynomial_product_in_fourier_domain(T *result, T *first,
                                                     T *second) {
  int tid = threadIdx.x;
  for (int i = 0; i < params::opt / 2; i++) {
    result[tid] = first[tid] * second[tid];
    tid += params::degree / params::opt;
  }

  if (threadIdx.x == 0) {
    result[params::degree / 2] =
        first[params::degree / 2] * second[params::degree / 2];
  }
}

// Computes result += first * second
// If init_accumulator is set, assumes that result was not initialized and does
// that with the outcome of first * second
template <class params, typename T>
__device__ void
polynomial_product_accumulate_in_fourier_domain(T *result, T *first, T *second,
                                                bool init_accumulator = false) {
  int tid = threadIdx.x;
  for (int i = 0; i < params::opt / 2; i++) {
    if (init_accumulator)
      result[tid] = first[tid] * second[tid];
    else
      result[tid] += first[tid] * second[tid];
    tid += params::degree / params::opt;
  }
}

#endif // CNCRT_POLYNOMIAL_MATH_H
