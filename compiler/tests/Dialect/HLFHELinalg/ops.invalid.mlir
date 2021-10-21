// RUN: zamacompiler --split-input-file --verify-diagnostics --entry-dialect=hlfhe --action=roundtrip %s

/////////////////////////////////////////////////
// HLFHELinalg.add_eint_int
/////////////////////////////////////////////////

// Incompatible dimension of operands
func @main(%a0: tensor<2x2x3x4x!HLFHE.eint<2>>, %a1: tensor<2x2x2x4xi3>) -> tensor<2x2x3x4x!HLFHE.eint<2>> {
  // expected-error @+1 {{'HLFHELinalg.add_eint_int' op has the dimension #2 of the operand #1 incompatible with other operands, got 2 expect 1 or 3}}
  %1 = "HLFHELinalg.add_eint_int"(%a0, %a1) : (tensor<2x2x3x4x!HLFHE.eint<2>>, tensor<2x2x2x4xi3>) -> tensor<2x2x3x4x!HLFHE.eint<2>>
  return %1 : tensor<2x2x3x4x!HLFHE.eint<2>>
}

// -----

// Incompatible dimension of result
func @main(%a0: tensor<2x2x3x4x!HLFHE.eint<2>>, %a1: tensor<2x2x2x4xi3>) -> tensor<2x10x3x4x!HLFHE.eint<2>> {
  // expected-error @+1 {{'HLFHELinalg.add_eint_int' op has the dimension #3 of the result incompatible with operands dimension, got 10 expect 2}}
  %1 = "HLFHELinalg.add_eint_int"(%a0, %a1) : (tensor<2x2x3x4x!HLFHE.eint<2>>, tensor<2x2x2x4xi3>) -> tensor<2x10x3x4x!HLFHE.eint<2>>
  return %1 : tensor<2x10x3x4x!HLFHE.eint<2>>
}

// -----

// Incompatible number of dimension between operands and result
func @main(%a0: tensor<2x2x3x4x!HLFHE.eint<2>>, %a1: tensor<2x2x2x4xi3>) -> tensor<2x3x4x!HLFHE.eint<2>> {
  // expected-error @+1 {{'HLFHELinalg.add_eint_int' op should have the number of dimensions of the result equal to the highest number of dimensions of operands, got 3 expect 4}}
  %1 = "HLFHELinalg.add_eint_int"(%a0, %a1) : (tensor<2x2x3x4x!HLFHE.eint<2>>, tensor<2x2x2x4xi3>) -> tensor<2x3x4x!HLFHE.eint<2>>
  return %1 : tensor<2x3x4x!HLFHE.eint<2>>
}

// -----

// Incompatible width between clear and encrypted witdh
func @main(%a0: tensor<2x3x4x!HLFHE.eint<2>>, %a1: tensor<2x3x4xi4>) -> tensor<2x3x4x!HLFHE.eint<2>> {
  // expected-error @+1 {{'HLFHELinalg.add_eint_int' op should have the width of integer values less or equals than the width of encrypted values + 1}}
  %1 = "HLFHELinalg.add_eint_int"(%a0, %a1) : (tensor<2x3x4x!HLFHE.eint<2>>, tensor<2x3x4xi4>) -> tensor<2x3x4x!HLFHE.eint<2>>
  return %1 : tensor<2x3x4x!HLFHE.eint<2>>
}

// -----

/////////////////////////////////////////////////
// HLFHELinalg.add_eint
/////////////////////////////////////////////////

// Incompatible dimension of operands
func @main(%a0: tensor<2x2x3x4x!HLFHE.eint<2>>, %a1: tensor<2x2x2x4x!HLFHE.eint<2>>) -> tensor<2x2x3x4x!HLFHE.eint<2>> {
  // expected-error @+1 {{'HLFHELinalg.add_eint' op has the dimension #2 of the operand #1 incompatible with other operands, got 2 expect 1 or 3}}
  %1 = "HLFHELinalg.add_eint"(%a0, %a1) : (tensor<2x2x3x4x!HLFHE.eint<2>>, tensor<2x2x2x4x!HLFHE.eint<2>>) -> tensor<2x2x3x4x!HLFHE.eint<2>>
  return %1 : tensor<2x2x3x4x!HLFHE.eint<2>>
}

// -----

// Incompatible dimension of result
func @main(%a0: tensor<2x2x3x4x!HLFHE.eint<2>>, %a1: tensor<2x2x2x4x!HLFHE.eint<2>>) -> tensor<2x10x3x4x!HLFHE.eint<2>> {
  // expected-error @+1 {{'HLFHELinalg.add_eint' op has the dimension #3 of the result incompatible with operands dimension, got 10 expect 2}}
  %1 = "HLFHELinalg.add_eint"(%a0, %a1) : (tensor<2x2x3x4x!HLFHE.eint<2>>, tensor<2x2x2x4x!HLFHE.eint<2>>) -> tensor<2x10x3x4x!HLFHE.eint<2>>
  return %1 : tensor<2x10x3x4x!HLFHE.eint<2>>
}

// -----

// Incompatible number of dimension between operands and result
func @main(%a0: tensor<2x2x3x4x!HLFHE.eint<2>>, %a1: tensor<2x2x2x4x!HLFHE.eint<2>>) -> tensor<2x3x4x!HLFHE.eint<2>> {
  // expected-error @+1 {{'HLFHELinalg.add_eint' op should have the number of dimensions of the result equal to the highest number of dimensions of operands, got 3 expect 4}}
  %1 = "HLFHELinalg.add_eint"(%a0, %a1) : (tensor<2x2x3x4x!HLFHE.eint<2>>, tensor<2x2x2x4x!HLFHE.eint<2>>) -> tensor<2x3x4x!HLFHE.eint<2>>
  return %1 : tensor<2x3x4x!HLFHE.eint<2>>
}

// -----

// Incompatible width between clear and encrypted witdh
func @main(%a0: tensor<2x3x4x!HLFHE.eint<2>>, %a1: tensor<2x3x4x!HLFHE.eint<3>>) -> tensor<2x3x4x!HLFHE.eint<2>> {
  // expected-error @+1 {{'HLFHELinalg.add_eint' op should have the width of encrypted equals, got 3 expect 2}}
  %1 = "HLFHELinalg.add_eint"(%a0, %a1) : (tensor<2x3x4x!HLFHE.eint<2>>, tensor<2x3x4x!HLFHE.eint<3>>) -> tensor<2x3x4x!HLFHE.eint<2>>
  return %1 : tensor<2x3x4x!HLFHE.eint<2>>
}

// -----

/////////////////////////////////////////////////
// HLFHELinalg.mul_eint_int
/////////////////////////////////////////////////

// Incompatible dimension of operands
func @main(%a0: tensor<2x2x3x4x!HLFHE.eint<2>>, %a1: tensor<2x2x2x4xi3>) -> tensor<2x2x3x4x!HLFHE.eint<2>> {
  // expected-error @+1 {{'HLFHELinalg.mul_eint_int' op has the dimension #2 of the operand #1 incompatible with other operands, got 2 expect 1 or 3}}
  %1 = "HLFHELinalg.mul_eint_int"(%a0, %a1) : (tensor<2x2x3x4x!HLFHE.eint<2>>, tensor<2x2x2x4xi3>) -> tensor<2x2x3x4x!HLFHE.eint<2>>
  return %1 : tensor<2x2x3x4x!HLFHE.eint<2>>
}

// -----

// Incompatible dimension of result
func @main(%a0: tensor<2x2x3x4x!HLFHE.eint<2>>, %a1: tensor<2x2x2x4xi3>) -> tensor<2x10x3x4x!HLFHE.eint<2>> {
  // expected-error @+1 {{'HLFHELinalg.mul_eint_int' op has the dimension #3 of the result incompatible with operands dimension, got 10 expect 2}}
  %1 = "HLFHELinalg.mul_eint_int"(%a0, %a1) : (tensor<2x2x3x4x!HLFHE.eint<2>>, tensor<2x2x2x4xi3>) -> tensor<2x10x3x4x!HLFHE.eint<2>>
  return %1 : tensor<2x10x3x4x!HLFHE.eint<2>>
}

// -----

// Incompatible number of dimension between operands and result
func @main(%a0: tensor<2x2x3x4x!HLFHE.eint<2>>, %a1: tensor<2x2x2x4xi3>) -> tensor<2x3x4x!HLFHE.eint<2>> {
  // expected-error @+1 {{'HLFHELinalg.mul_eint_int' op should have the number of dimensions of the result equal to the highest number of dimensions of operands, got 3 expect 4}}
  %1 = "HLFHELinalg.mul_eint_int"(%a0, %a1) : (tensor<2x2x3x4x!HLFHE.eint<2>>, tensor<2x2x2x4xi3>) -> tensor<2x3x4x!HLFHE.eint<2>>
  return %1 : tensor<2x3x4x!HLFHE.eint<2>>
}

// -----

// Incompatible width between clear and encrypted witdh
func @main(%a0: tensor<2x3x4x!HLFHE.eint<2>>, %a1: tensor<2x3x4xi4>) -> tensor<2x3x4x!HLFHE.eint<2>> {
  // expected-error @+1 {{'HLFHELinalg.mul_eint_int' op should have the width of integer values less or equals than the width of encrypted values + 1}}
  %1 = "HLFHELinalg.mul_eint_int"(%a0, %a1) : (tensor<2x3x4x!HLFHE.eint<2>>, tensor<2x3x4xi4>) -> tensor<2x3x4x!HLFHE.eint<2>>
  return %1 : tensor<2x3x4x!HLFHE.eint<2>>
}

// -----