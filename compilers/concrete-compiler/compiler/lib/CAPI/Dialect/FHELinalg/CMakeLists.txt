set(LLVM_OPTIONAL_SOURCES FHELinalg.cpp)

add_mlir_public_c_api_library(
  CONCRETELANGCAPIFHELINALG
  FHELinalg.cpp
  DEPENDS
  mlir-headers
  LINK_LIBS
  PUBLIC
  MLIRCAPIIR
  FHELinalgDialect)
