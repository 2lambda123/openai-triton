#ifndef TRITONGPU_PASSES
#define TRITONGPU_PASSES

include "mlir/Pass/PassBase.td"

def TritonGPUPipeline : Pass<"tritongpu-pipeline", "mlir::ModuleOp"> {
  let summary = "pipeline";

  let description = [{
    Unroll loops to hide global memory -> shared memory latency.
  }];

  let constructor = "mlir::createTritonGPUPipelinePass()";

  let dependentDialects = ["mlir::triton::gpu::TritonGPUDialect",
                           "mlir::scf::SCFDialect",
                           "mlir::arith::ArithmeticDialect"];

  let options = [
    Option<"numStages", "num-stages",
           "int32_t", /*default*/"2",
           "number of pipeline stages">
  ];
}

def TritonGPUPrefetch : Pass<"tritongpu-prefetch", "mlir::ModuleOp"> {
  let summary = "prefetch";

  let description = [{
    Prefetch operands (a and b) of tt.dot into shared memory to hide shared memory -> register latency.
  }];

  let constructor = "mlir::createTritonGPUPrefetchPass()";

  let dependentDialects = ["mlir::triton::gpu::TritonGPUDialect",
                           "mlir::scf::SCFDialect",
                           "mlir::arith::ArithmeticDialect"];
}

def TritonGPUCoalesce: Pass<"tritongpu-coalesce", "mlir::ModuleOp"> {
  let summary = "coalesce";

  let description = [{
    TODO
  }];

  let constructor = "mlir::createTritonGPUCoalescePass()";

  let dependentDialects = ["mlir::triton::gpu::TritonGPUDialect"];
}

def TritonGPUCombineOps : Pass<"tritongpu-combine", "mlir::ModuleOp"> {
  let summary = "combine triton gpu ops";

  let description = [{
    convert_layout(convert_layout(%src, #LAYOUT_0), #LAYOUT_1) =>
      convert_layout(%src, #LAYOUT_1)

    convert_layout(%src, #LAYOUT) => %src if %src.layout() == #LAYOUT
  }];

  let constructor = "mlir::createTritonGPUCombineOpsPass()";

  let dependentDialects = ["mlir::triton::gpu::TritonGPUDialect",
                           "mlir::triton::TritonDialect"];

  let options = [
    Option<"computeCapability", "compute-capability",
           "int32_t", /*default*/"80",
           "device compute capability">
  ];
}

def TritonGPUReorderInstructions: Pass<"tritongpu-reorder-instructions", "mlir::ModuleOp"> {
  let summary = "Reorder instructions";

  let description = "This pass reorder instructions so as to (1) decrease register pressure (e.g., by moving "
                    "conversions from shared memory before their first use) and (2) promote LLVM instruction "
                    "order more friendly to `ptxas`.";

  let constructor = "mlir::createTritonGPUReorderInstructionsPass()";

  let dependentDialects = ["mlir::triton::gpu::TritonGPUDialect",
                           "mlir::triton::TritonDialect"];
}

def TritonGPUDecomposeConversions: Pass<"tritongpu-decompose-conversions", "mlir::ModuleOp"> {
  let summary = "Decompose convert[distributed -> dotOperand] into convert[distributed -> shared -> dotOperand]";

  let description = "Decomposing conversions this way makes it possible to use CSE and re-use #shared tensors";

  let constructor = "mlir::createTritonGPUDecomposeConversionsPass()";

  let dependentDialects = ["mlir::triton::gpu::TritonGPUDialect",
                           "mlir::triton::TritonDialect"];
}

def TritonGPUCanonicalizeLoops: Pass<"tritongpu-canonicalize-loops", "mlir::ModuleOp"> {
  let summary = "canonicalize scf.ForOp ops";

  let description = [{
    This implements some optimizations that are missing in the standard scf.ForOp
    canonicalizer.
  }];

  let constructor = "mlir::createTritonGPUCanonicalizeLoopsPass()";

  let dependentDialects = ["mlir::triton::gpu::TritonGPUDialect"];
}

def UpdateMmaForVolta : Pass<"tritongpu-update-mma-for-volta", "mlir::ModuleOp"> {
  let summary = "Update mma encodings for Volta";

  let description = [{
    This helps to update the mma encodings for Volta.
  }];

  let constructor = "mlir::createTritonGPUUpdateMmaForVoltaPass()";

  let dependentDialects = ["mlir::triton::gpu::TritonGPUDialect"];
}

#endif
