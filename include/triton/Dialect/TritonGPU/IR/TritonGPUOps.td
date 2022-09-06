#ifndef TRITONGPU_OPS
#define TRITONGPU_OPS

include "triton/Dialect/TritonGPU/IR/TritonGPUDialect.td"
include "triton/Dialect/TritonGPU/IR/TritonGPUAttrDefs.td"
include "mlir/Dialect/Arithmetic/IR/ArithmeticBase.td"
include "triton/Dialect/Triton/IR/TritonTypes.td"
include "triton/Dialect/Triton/IR/TritonAttrDefs.td"
include "mlir/IR/OpBase.td"
include "mlir/Interfaces/SideEffectInterfaces.td" // NoSideEffect
include "mlir/Interfaces/InferTypeOpInterface.td" // SameOperandsAndResultType

def TT_BoolTensor : TensorOf<[I1]>;

def TT_BoolLike : AnyTypeOf<[I1, TT_BoolTensor]>;
def TT_IntegerLike : AnyTypeOf<[TT_Int, TT_IntegerTensor]>;
def TT_FloatLike : AnyTypeOf<[TT_Float, TT_FloatTensor]>;

class TTG_Op<string mnemonic, list<Trait> traits = []> :
    Op<TritonGPU_Dialect, mnemonic, traits>;

def TTG_ConvertLayoutOp : TTG_Op<"convert_layout",
                                 [NoSideEffect]> {
  let summary = "convert layout";

  let arguments = (ins TT_Tensor:$src);

  let results = (outs TT_Tensor:$result);

  let assemblyFormat = "$src attr-dict `:` functional-type(operands, results)";
}

def TTG_AsyncWaitOp : TTG_Op<"async_wait"> {
  let summary = "async wait";

  let arguments = (ins I32Attr:$num);

  let assemblyFormat = "attr-dict";
}

def TTG_CopyAsyncOp : TTG_Op<"copy_async",
                             [MemoryEffects<[MemRead, MemWrite]>,
                              SameVariadicOperandSize,
                              TypesMatchWith<"infer mask type from ptr type",
                                             "ptr", "mask", "getI1SameShape($_self)",
                                             "($_op.getOperands().size() <= 1) || std::equal_to<>()">,
                              TypesMatchWith<"infer other type from ptr type",
                                             "ptr", "other", "getPointeeType($_self)",
                                             "($_op.getOperands().size() <= 2) || std::equal_to<>()">]> {
  let summary = "copy async";

  let arguments = (ins TT_PtrTensor:$ptr, Optional<I1Tensor>:$mask, Optional<TT_Type>:$other,
                       TT_CacheModifierAttr:$cache, TT_EvictionPolicyAttr:$evict,
                       BoolAttr:$isVolatile);

  let builders = [
      OpBuilder<(ins "Value":$ptr, "triton::CacheModifier":$cache,
                     "triton::EvictionPolicy":$evict, "bool":$isVolatile)>,
  ];

  let results = (outs TT_Tensor:$result);

  // let assemblyFormat = "operands attr-dict `:` type($ptr) `->` type($result)";
  let parser = [{ return parseCopyAsyncOp(parser, result); }];

  let printer = [{ return printCopyAsyncOp(p, *this); }];

  // result needs to be of shared layout
  let verifier = [{ return ::verify(*this); }];
}

// Port Arith_CmpIOp & Arith_CmpFOp to TritonGPU.
// This is needed because Arith's Cmp ops don't
// handle encodings
// https://github.com/llvm/llvm-project/blob/main/mlir/include/mlir/Dialect/Arithmetic/IR/ArithmeticOps.td#L111
def TTG_CmpIOp : TTG_Op<"cmpi", [NoSideEffect]> {
  let summary = "integer comparison operation";

  let description = [{}];

  let arguments = (ins Arith_CmpIPredicateAttr:$predicate,
                       TT_IntegerLike:$lhs,
                       TT_IntegerLike:$rhs);

  let results = (outs TT_BoolLike:$result);
}

def TTG_CmpFOp : TTG_Op<"cmpf"> {
  let summary = "floating-point comparison operation";

  let description = [{}];

  let arguments = (ins Arith_CmpFPredicateAttr:$predicate,
                       TT_FloatLike:$lhs,
                       TT_FloatLike:$rhs);

  let results = (outs TT_BoolLike:$result);
}

def TTG_InsertSliceAsyncOp : TTG_Op<"insert_slice_async", 
                                    [SameVariadicOperandSize,
                                     MemoryEffects<[MemRead, MemWrite]>,
                                     TypesMatchWith<"infer mask type from src type",
                                                    "src", "mask", "getI1SameShape($_self)",
                                                    "($_op.getOperands().size() <= 3) || std::equal_to<>()">,
                                     TypesMatchWith<"infer other type from src type",
                                                    "src", "other", "getPointeeType($_self)",
                                                    "($_op.getOperands().size() <= 4) || std::equal_to<>()">]> {
  let summary = "insert slice async";

  let description = [{
      This operation inserts a tensor `$src` into another tensor `$dst` as specified by the operation’s
      `$offset` argument and `$axis` attribute.

      It returns a copy of `$dst` with the proper slice updated asynchronously with the value of `$src`.
      This operation is non-blocking, and `$results` will have the updated value after the corresponding async_wait.

      The insert_slice_async operation supports the following arguments:

      * src: the tensor that is inserted.
      * dst: the tensor into which the `$src` tensor is inserted.
      * offset: the offset of the `$src` tensor at the given `$axis` from which the `$dst` tensor is inserted into
      * mask: optional tensor-rank number of boolean masks which specify which
              elements of the `$src` tensor are inserted into the `$dst` tensor.
      * other: optional tensor-rank number of other tensors which specify what
              values are inserted into the `$dst` tensor if the corresponding
              element of the `$mask` tensor is false.
      
      In the future, we may decompose this operation into a sequence of:

      * `async` operation to specify a sequence of asynchronous operations
      * `load` operation to load a tensor from global memory
      * `insert_slice` operations to insert the `$src` tensor into the `$dst` tensor

      Example:

      ```
      %1 = triton_gpu.alloc_tensor : tensor<2x32xf32>
      %2 = triton_gpu.insert_slice_async %0, %1, %offset { axis = 0 } : tensor<32x!tt.ptr<f32>, #AL> -> tensor<2x32xf32, #A>
      triiton_gpu.async_wait { num = 0 : i32 }
      ```
  }];

  let arguments = (ins TT_PtrTensor:$src, TT_Tensor:$dst, I32:$offset,
                       Optional<I1Tensor>:$mask, Optional<TT_Type>:$other,
                       TT_CacheModifierAttr:$cache, TT_EvictionPolicyAttr:$evict,
                       BoolAttr:$isVolatile, I32Attr:$axis);

  let builders = [
      OpBuilder<(ins "Value":$src, "Value":$dst, "Value":$offset,
                     "triton::CacheModifier":$cache,
                     "triton::EvictionPolicy":$evict, "bool":$isVolatile, "int":$axis)>,
      OpBuilder<(ins "Value":$src, "Value":$dst, "Value":$offset, "Value":$mask,
                     "triton::CacheModifier":$cache,
                     "triton::EvictionPolicy":$evict, "bool":$isVolatile, "int":$axis)>,
      OpBuilder<(ins "Value":$src, "Value":$dst, "Value":$offset,
                     "Value":$mask, "Value":$other,
                     "triton::CacheModifier":$cache,
                     "triton::EvictionPolicy":$evict, "bool":$isVolatile, "int":$axis)>,
  ];

  let results = (outs TT_Tensor:$result);

  //let assemblyFormat = [{
  //  $src `,` $dst ``
  //  $offset, $mask, $other
  //  attr-dict `:` type($src) `->` type($dst)
  //}];

  // The custom parser could be replaced with oilist in LLVM-16
  let parser = [{ return parseInsertSliceAsyncOp(parser, result); }];

  let printer = [{ return printInsertSliceAsyncOp(p, *this); }];

  // result needs to be of shared layout
  let verifier = [{ return ::verify(*this); }];
}

def TTG_ExtractSliceOp : TTG_Op<"extract_slice", [NoSideEffect, InferTypeOpInterface]> {
  let summary = "extract slice";
  let description = [{
    The "extract_slice" operation extracts a `$result` tensor from a `$src` tensor as
    specified by the operation's `$offset` and `$axis` arguments.

    The extract_slice operation supports the following arguments:

    * src: the tensor that is extracted from.
    * offset: the offset at the given `$axis` from which the `$src` tensor is extracted

    Example:

    ```
    // Rank-reducing extract_slice.
    %1 = tensor.extract_slice %0, %offset {axis = 0} : tensor<8x16x4xf32> -> tensor<1x16x4xf32>
    ```
  }];

  let arguments = (ins TT_Tensor:$src, I32:$offset, I32Attr:$axis);

  let results = (outs TT_Tensor:$result);

  let assemblyFormat = [{$src `,` $offset attr-dict `:` type($src) `->` type($result)}];

  let extraClassDeclaration = [{
    static ::mlir::LogicalResult inferReturnTypes(::mlir::MLIRContext *context,
          ::llvm::Optional<::mlir::Location> location, ::mlir::ValueRange operands,
          ::mlir::DictionaryAttr attributes, ::mlir::RegionRange regions,
          ::llvm::SmallVectorImpl<::mlir::Type> &inferredReturnTypes);
  }];

  // result needs to be of shared layout
  let verifier = [{ return ::verify(*this); }];
}

def TTG_AllocTensorOp : TTG_Op<"alloc_tensor", [NoSideEffect]> {
  let summary = "allocate tensor";

  let description = [{
    This operation defines a tensor of a particular shape.
    The contents of the tensor are supposed to be in shared memory.

    Note: This op can be repalced to a `bufferization.alloc_tensor` in LLVM 16.
  }];

  let assemblyFormat = [{attr-dict `:` type($result)}]; 

  let results = (outs TT_Tensor:$result);

  // result needs to be of shared layout
  let verifier = [{ return ::verify(*this); }];
}

#endif