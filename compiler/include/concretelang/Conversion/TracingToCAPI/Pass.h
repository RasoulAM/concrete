// Part of the Concrete Compiler Project, under the BSD3 License with Zama
// Exceptions. See
// https://github.com/zama-ai/concrete-compiler-internal/blob/main/LICENSE.txt
// for license information.

#ifndef ZAMALANG_CONVERSION_TRACINGTOCAPI_PASS_H_
#define ZAMALANG_CONVERSION_TRACINGTOCAPI_PASS_H_

#include "mlir/Pass/Pass.h"

namespace mlir {
namespace concretelang {
/// Create a pass to convert `Tracing` dialect to CAPI calls.
std::unique_ptr<OperationPass<ModuleOp>> createConvertTracingToCAPIPass();
} // namespace concretelang
} // namespace mlir

#endif
