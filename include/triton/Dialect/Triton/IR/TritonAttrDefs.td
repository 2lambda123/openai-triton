#ifndef TRITON_ATTR_DEFS
#define TRITON_ATTR_DEFS

include "mlir/IR/EnumAttr.td"

// Attrs for LoadOp
def TT_CacheModifierAttr : I32EnumAttr<
    "CacheModifier", "",
    [
        I32EnumAttrCase<"NONE", 1, "none">,
        I32EnumAttrCase<"CA", 2, "ca">,
        I32EnumAttrCase<"CG", 3, "cg">,
    ]> {
    let cppNamespace = "::mlir::triton";
}
def TT_EvictionPolicyAttr : I32EnumAttr<
    "EvictionPolicy", "",
    [
        I32EnumAttrCase<"NORMAL", 1, "normal">,
        I32EnumAttrCase<"EVICT_FIRST", 2, "evict_first">,
        I32EnumAttrCase<"EVICT_LAST", 3, "evict_last">
    ]> {
    let cppNamespace = "::mlir::triton";
}

// reduction
def TT_RedOpAttr : I32EnumAttr<
    /*name*/"RedOp", /*summary*/"",
    /*case*/
    [
        I32EnumAttrCase</*sym*/"ADD", 1, /*str*/"add">,
        I32EnumAttrCase<"MAX", 2, "max">,
        I32EnumAttrCase<"MIN", 3, "min">,
        I32EnumAttrCase<"FADD", 4, "fadd">,
        I32EnumAttrCase<"FMAX", 5, "fmax">,
        I32EnumAttrCase<"FMIN", 6, "fmin">,
        I32EnumAttrCase<"XOR", 7, "xor">
    ]> {
    let cppNamespace = "::mlir::triton";
}

// atomic
def TT_AtomicRMWAttr : I32EnumAttr<
    "RMWOp", "",
    [
        I32EnumAttrCase<"AND", 1, "and">,
        I32EnumAttrCase<"OR", 2, "or">,
        I32EnumAttrCase<"XOR", 3, "xor">,
        I32EnumAttrCase<"ADD", 4, "add">,
        I32EnumAttrCase<"FADD", 5, "fadd">,
        I32EnumAttrCase<"MAX", 6, "max">,
        I32EnumAttrCase<"MIN", 7, "min">,
        I32EnumAttrCase<"UMAX", 8, "umax">,
        I32EnumAttrCase<"UMIN", 9, "umin">
    ]> {
    let cppNamespace = "::mlir::triton";
}

#endif