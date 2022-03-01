// RUN: concretecompiler --split-input-file --passes concrete-to-bconcrete --action=dump-bconcrete %s 2>&1| FileCheck %s

// CHECK: func @tensor_collapse_shape(%arg0: tensor<2x3x4x5x6x1025xi64>) -> tensor<720x1025xi64> {
// CHECK-NEXT: %0 = memref.buffer_cast %arg0 : memref<2x3x4x5x6x1025xi64>
// CHECK-NEXT: %1 = memref.collapse_shape %0 [[_:\[\[0, 1, 2, 3, 4\], \[5\]\]]] : memref<2x3x4x5x6x1025xi64> into memref<720x1025xi64>
// CHECK-NEXT: %2 = memref.tensor_load %1 : memref<720x1025xi64>
// CHECK-NEXT: return %2 : tensor<720x1025xi64>
func @tensor_collapse_shape(%arg0: tensor<2x3x4x5x6x!Concrete.lwe_ciphertext<1024,4>>) -> tensor<720x!Concrete.lwe_ciphertext<1024,4>> {
    %0 = linalg.tensor_collapse_shape %arg0 [[0, 1, 2, 3, 4]]  {MANP = 1 : ui1}: tensor<2x3x4x5x6x!Concrete.lwe_ciphertext<1024,4>> into tensor<720x!Concrete.lwe_ciphertext<1024,4>>
    return %0 : tensor<720x!Concrete.lwe_ciphertext<1024,4>>
}


// -----

// CHECK: func @tensor_collatenspse_shape(%arg0: tensor<2x3x5x1025xi64>) -> tensor<5x6x1025xi64> {
// CHECK-NEXT:     %0 = memref.buffer_cast %arg0 : memref<2x3x5x1025xi64>
// CHECK-NEXT:     %1 = memref.collapse_shape %0 [[_:\[\[0, 1, 2\], \[3\]\]]] : memref<2x3x5x1025xi64> into memref<30x1025xi64>
// CHECK-NEXT:     %2 = memref.expand_shape %1 [[_:\[\[0, 1\], \[2\]\]]] : memref<30x1025xi64> into memref<5x6x1025xi64>
// CHECK-NEXT:     %3 = memref.tensor_load %2 : memref<5x6x1025xi64>
// CHECK-NEXT:     return %3 : tensor<5x6x1025xi64>
func @tensor_collatenspse_shape(%arg0: tensor<2x3x5x!Concrete.lwe_ciphertext<1024,4>>) -> tensor<5x6x!Concrete.lwe_ciphertext<1024,4>> {
    %0 = linalg.tensor_collapse_shape %arg0 [[0, 1, 2]]  {MANP = 1 : ui1}: tensor<2x3x5x!Concrete.lwe_ciphertext<1024,4>> into tensor<30x!Concrete.lwe_ciphertext<1024,4>>
    %1 = linalg.tensor_expand_shape %0 [[0, 1]]  {MANP = 1 : ui1}: tensor<30x!Concrete.lwe_ciphertext<1024,4>> into tensor<5x6x!Concrete.lwe_ciphertext<1024,4>>
    return %1 : tensor<5x6x!Concrete.lwe_ciphertext<1024,4>>
}


// -----

// CHECK: func @tensor_collatenspse_shape(%arg0: tensor<2x3x2x3x4x1025xi64>) -> tensor<6x2x12x1025xi64> {
// CHECK-NEXT:     %0 = memref.buffer_cast %arg0 : memref<2x3x2x3x4x1025xi64>
// CHECK-NEXT:     %1 = memref.collapse_shape %0 [[_:\[\[0, 1\], \[2\], \[3, 4\], \[5\]\]]] : memref<2x3x2x3x4x1025xi64> into memref<6x2x12x1025xi64>
// CHECK-NEXT:     %2 = memref.tensor_load %1 : memref<6x2x12x1025xi64>
// CHECK-NEXT:     return %2 : tensor<6x2x12x1025xi64>
func @tensor_collatenspse_shape(%arg0: tensor<2x3x2x3x4x!Concrete.lwe_ciphertext<1024,4>>) -> tensor<6x2x12x!Concrete.lwe_ciphertext<1024,4>> {
    %0 = linalg.tensor_collapse_shape %arg0 [[0, 1], [2], [3, 4]]  {MANP = 1 : ui1}: tensor<2x3x2x3x4x!Concrete.lwe_ciphertext<1024,4>> into tensor<6x2x12x!Concrete.lwe_ciphertext<1024,4>>
    return %0 : tensor<6x2x12x!Concrete.lwe_ciphertext<1024,4>>
}