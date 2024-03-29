set(LLVM_TARGET_DEFINITIONS Combine.td)
mlir_tablegen(TritonGPUCombine.inc -gen-rewriters)
add_public_tablegen_target(TritonGPUCombineIncGen)

add_mlir_dialect_library(TritonGPUTransforms
  Coalesce.cpp
  CanonicalizeLoops.cpp
  Combine.cpp
  Pipeline.cpp
  Prefetch.cpp
  ReorderInstructions.cpp
  DecomposeConversions.cpp
  TritonGPUConversion.cpp
  UpdateMmaForVolta.cpp
  Utility.cpp

  DEPENDS
  TritonGPUTransformsIncGen
  TritonGPUCombineIncGen

  LINK_LIBS PUBLIC
  TritonIR
  TritonGPUIR
  MLIRTransformUtils
)
