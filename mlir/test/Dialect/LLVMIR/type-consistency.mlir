// RUN: mlir-opt %s --pass-pipeline="builtin.module(llvm.func(llvm-type-consistency))" --split-input-file | FileCheck %s

// CHECK-LABEL: llvm.func @same_address
llvm.func @same_address(%arg: i32) {
  %0 = llvm.mlir.constant(1 : i32) : i32
  // CHECK: %[[ALLOCA:.*]] = llvm.alloca %{{.*}} x !llvm.struct<"foo", (i32, i32, i32)>
  %1 = llvm.alloca %0 x !llvm.struct<"foo", (i32, i32, i32)> : (i32) -> !llvm.ptr
  // CHECK: = llvm.getelementptr %[[ALLOCA]][0, 2] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<"foo", (i32, i32, i32)>
  %7 = llvm.getelementptr %1[8] : (!llvm.ptr) -> !llvm.ptr, i8
  llvm.store %arg, %7 : i32, !llvm.ptr
  llvm.return
}

// -----

// CHECK-LABEL: llvm.func @same_address_keep_inbounds
llvm.func @same_address_keep_inbounds(%arg: i32) {
  %0 = llvm.mlir.constant(1 : i32) : i32
  // CHECK: %[[ALLOCA:.*]] = llvm.alloca %{{.*}} x !llvm.struct<"foo", (i32, i32, i32)>
  %1 = llvm.alloca %0 x !llvm.struct<"foo", (i32, i32, i32)> : (i32) -> !llvm.ptr
  // CHECK: = llvm.getelementptr inbounds %[[ALLOCA]][0, 2] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<"foo", (i32, i32, i32)>
  %7 = llvm.getelementptr inbounds %1[8] : (!llvm.ptr) -> !llvm.ptr, i8
  llvm.store %arg, %7 : i32, !llvm.ptr
  llvm.return
}

// -----

// CHECK-LABEL: llvm.func @struct_store_instead_of_first_field
llvm.func @struct_store_instead_of_first_field(%arg: i32) {
  %0 = llvm.mlir.constant(1 : i32) : i32
  // CHECK: %[[ALLOCA:.*]] = llvm.alloca %{{.*}} x !llvm.struct<"foo", (i32, i32, i32)>
  %1 = llvm.alloca %0 x !llvm.struct<"foo", (i32, i32, i32)> : (i32) -> !llvm.ptr
  // CHECK: %[[GEP:.*]] = llvm.getelementptr %[[ALLOCA]][0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<"foo", (i32, i32, i32)>
  // CHECK: llvm.store %{{.*}}, %[[GEP]] : i32
  llvm.store %arg, %1 : i32, !llvm.ptr
  llvm.return
}

// -----

// CHECK-LABEL: llvm.func @struct_store_instead_of_first_field_same_size
// CHECK-SAME: (%[[ARG:.*]]: f32)
llvm.func @struct_store_instead_of_first_field_same_size(%arg: f32) {
  %0 = llvm.mlir.constant(1 : i32) : i32
  // CHECK-DAG: %[[ALLOCA:.*]] = llvm.alloca %{{.*}} x !llvm.struct<"foo", (i32, i32, i32)>
  %1 = llvm.alloca %0 x !llvm.struct<"foo", (i32, i32, i32)> : (i32) -> !llvm.ptr
  // CHECK-DAG: %[[GEP:.*]] = llvm.getelementptr %[[ALLOCA]][0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<"foo", (i32, i32, i32)>
  // CHECK-DAG: %[[BITCAST:.*]] = llvm.bitcast %[[ARG]] : f32 to i32
  // CHECK: llvm.store %[[BITCAST]], %[[GEP]] : i32
  llvm.store %arg, %1 : f32, !llvm.ptr
  llvm.return
}

// -----

// CHECK-LABEL: llvm.func @struct_load_instead_of_first_field
llvm.func @struct_load_instead_of_first_field() -> i32 {
  %0 = llvm.mlir.constant(1 : i32) : i32
  // CHECK: %[[ALLOCA:.*]] = llvm.alloca %{{.*}} x !llvm.struct<"foo", (i32, i32, i32)>
  %1 = llvm.alloca %0 x !llvm.struct<"foo", (i32, i32, i32)> : (i32) -> !llvm.ptr
  // CHECK: %[[GEP:.*]] = llvm.getelementptr %[[ALLOCA]][0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<"foo", (i32, i32, i32)>
  // CHECK: %[[RES:.*]] = llvm.load %[[GEP]] : !llvm.ptr -> i32
  %2 = llvm.load %1 : !llvm.ptr -> i32
  // CHECK: llvm.return %[[RES]] : i32
  llvm.return %2 : i32
}

// -----

// CHECK-LABEL: llvm.func @struct_load_instead_of_first_field_same_size
llvm.func @struct_load_instead_of_first_field_same_size() -> f32 {
  %0 = llvm.mlir.constant(1 : i32) : i32
  // CHECK: %[[ALLOCA:.*]] = llvm.alloca %{{.*}} x !llvm.struct<"foo", (i32, i32, i32)>
  %1 = llvm.alloca %0 x !llvm.struct<"foo", (i32, i32, i32)> : (i32) -> !llvm.ptr
  // CHECK: %[[GEP:.*]] = llvm.getelementptr %[[ALLOCA]][0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<"foo", (i32, i32, i32)>
  // CHECK: %[[LOADED:.*]] = llvm.load %[[GEP]] : !llvm.ptr -> i32
  // CHECK: %[[RES:.*]] = llvm.bitcast %[[LOADED]] : i32 to f32
  %2 = llvm.load %1 : !llvm.ptr -> f32
  // CHECK: llvm.return %[[RES]] : f32
  llvm.return %2 : f32
}

// -----

// CHECK-LABEL: llvm.func @index_in_final_padding
llvm.func @index_in_final_padding(%arg: i32) {
  %0 = llvm.mlir.constant(1 : i32) : i32
  // CHECK: %[[ALLOCA:.*]] = llvm.alloca %{{.*}} x !llvm.struct<"foo", (i32, i8)>
  %1 = llvm.alloca %0 x !llvm.struct<"foo", (i32, i8)> : (i32) -> !llvm.ptr
  // CHECK: = llvm.getelementptr %[[ALLOCA]][7] : (!llvm.ptr) -> !llvm.ptr, i8
  %7 = llvm.getelementptr %1[7] : (!llvm.ptr) -> !llvm.ptr, i8
  llvm.store %arg, %7 : i32, !llvm.ptr
  llvm.return
}

// -----

// CHECK-LABEL: llvm.func @index_out_of_bounds
llvm.func @index_out_of_bounds(%arg: i32) {
  %0 = llvm.mlir.constant(1 : i32) : i32
  // CHECK: %[[ALLOCA:.*]] = llvm.alloca %{{.*}} x !llvm.struct<"foo", (i32, i32)>
  %1 = llvm.alloca %0 x !llvm.struct<"foo", (i32, i32)> : (i32) -> !llvm.ptr
  // CHECK: = llvm.getelementptr %[[ALLOCA]][9] : (!llvm.ptr) -> !llvm.ptr, i8
  %7 = llvm.getelementptr %1[9] : (!llvm.ptr) -> !llvm.ptr, i8
  llvm.store %arg, %7 : i32, !llvm.ptr
  llvm.return
}

// -----

// CHECK-LABEL: llvm.func @index_in_padding
llvm.func @index_in_padding(%arg: i16) {
  %0 = llvm.mlir.constant(1 : i32) : i32
  // CHECK: %[[ALLOCA:.*]] = llvm.alloca %{{.*}} x !llvm.struct<"foo", (i16, i32)>
  %1 = llvm.alloca %0 x !llvm.struct<"foo", (i16, i32)> : (i32) -> !llvm.ptr
  // CHECK: = llvm.getelementptr %[[ALLOCA]][2] : (!llvm.ptr) -> !llvm.ptr, i8
  %7 = llvm.getelementptr %1[2] : (!llvm.ptr) -> !llvm.ptr, i8
  llvm.store %arg, %7 : i16, !llvm.ptr
  llvm.return
}

// -----

// CHECK-LABEL: llvm.func @index_not_in_padding_because_packed
llvm.func @index_not_in_padding_because_packed(%arg: i16) {
  %0 = llvm.mlir.constant(1 : i32) : i32
  // CHECK: %[[ALLOCA:.*]] = llvm.alloca %{{.*}} x !llvm.struct<"foo", packed (i16, i32)>
  %1 = llvm.alloca %0 x !llvm.struct<"foo", packed (i16, i32)> : (i32) -> !llvm.ptr
  // CHECK: = llvm.getelementptr %[[ALLOCA]][0, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<"foo", packed (i16, i32)>
  %7 = llvm.getelementptr %1[2] : (!llvm.ptr) -> !llvm.ptr, i8
  llvm.store %arg, %7 : i16, !llvm.ptr
  llvm.return
}

// -----

// CHECK-LABEL: llvm.func @index_to_struct
// CHECK-SAME: (%[[ARG:.*]]: i32)
llvm.func @index_to_struct(%arg: i32) {
  %0 = llvm.mlir.constant(1 : i32) : i32
  // CHECK: %[[ALLOCA:.*]] = llvm.alloca %{{.*}} x !llvm.struct<"foo", (i32, struct<"bar", (i32, i32)>)>
  %1 = llvm.alloca %0 x !llvm.struct<"foo", (i32, struct<"bar", (i32, i32)>)> : (i32) -> !llvm.ptr
  // CHECK: %[[GEP0:.*]] = llvm.getelementptr %[[ALLOCA]][0, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<"foo", (i32, struct<"bar", (i32, i32)>)>
  // CHECK: %[[GEP1:.*]] = llvm.getelementptr %[[GEP0]][0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<"bar", (i32, i32)>
  %7 = llvm.getelementptr %1[4] : (!llvm.ptr) -> !llvm.ptr, i8
  // CHECK: llvm.store %[[ARG]], %[[GEP1]]
  llvm.store %arg, %7 : i32, !llvm.ptr
  llvm.return
}

// -----

// CHECK-LABEL: llvm.func @coalesced_store_ints
// CHECK-SAME: %[[ARG:.*]]: i64
llvm.func @coalesced_store_ints(%arg: i64) {
  // CHECK: %[[CST0:.*]] = llvm.mlir.constant(0 : i64) : i64
  // CHECK: %[[CST32:.*]] = llvm.mlir.constant(32 : i64) : i64

  %0 = llvm.mlir.constant(1 : i32) : i32
  // CHECK: %[[ALLOCA:.*]] = llvm.alloca %{{.*}} x !llvm.struct<"foo", (i32, i32)>
  %1 = llvm.alloca %0 x !llvm.struct<"foo", (i32, i32)> : (i32) -> !llvm.ptr

  // CHECK: %[[GEP:.*]] = llvm.getelementptr %[[ALLOCA]][0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<"foo", (i32, i32)>
  // CHECK: %[[SHR:.*]] = llvm.lshr %[[ARG]], %[[CST0]]
  // CHECK: %[[TRUNC:.*]] = llvm.trunc %[[SHR]] : i64 to i32
  // CHECK: llvm.store %[[TRUNC]], %[[GEP]]
  // CHECK: %[[SHR:.*]] = llvm.lshr %[[ARG]], %[[CST32]] : i64
  // CHECK: %[[TRUNC:.*]] = llvm.trunc %[[SHR]] : i64 to i32
  // CHECK: %[[GEP:.*]] = llvm.getelementptr %[[ALLOCA]][0, 1] : (!llvm.ptr)  -> !llvm.ptr, !llvm.struct<"foo", (i32, i32)>
  // CHECK: llvm.store %[[TRUNC]], %[[GEP]]
  llvm.store %arg, %1 : i64, !llvm.ptr
  // CHECK-NOT: llvm.store %[[ARG]], %[[ALLOCA]]
  llvm.return
}

// -----

// CHECK-LABEL: llvm.func @coalesced_store_ints_offset
// CHECK-SAME: %[[ARG:.*]]: i64
llvm.func @coalesced_store_ints_offset(%arg: i64) {
  // CHECK: %[[CST0:.*]] = llvm.mlir.constant(0 : i64) : i64
  // CHECK: %[[CST32:.*]] = llvm.mlir.constant(32 : i64) : i64
  %0 = llvm.mlir.constant(1 : i32) : i32
  // CHECK: %[[ALLOCA:.*]] = llvm.alloca %{{.*}} x !llvm.struct<"foo", (i64, i32, i32)>
  %1 = llvm.alloca %0 x !llvm.struct<"foo", (i64, i32, i32)> : (i32) -> !llvm.ptr
  %3 = llvm.getelementptr %1[0, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<"foo", (i64, i32, i32)>

  // CHECK: %[[SHR:.*]] = llvm.lshr %[[ARG]], %[[CST0]]
  // CHECK: %[[TRUNC:.*]] = llvm.trunc %[[SHR]] : i64 to i32
  // CHECK: %[[GEP:.*]] = llvm.getelementptr %[[ALLOCA]][0, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<"foo", (i64, i32, i32)>
  // CHECK: llvm.store %[[TRUNC]], %[[GEP]]
  // CHECK: %[[SHR:.*]] = llvm.lshr %[[ARG]], %[[CST32]] : i64
  // CHECK: %[[TRUNC:.*]] = llvm.trunc %[[SHR]] : i64 to i32
  // CHECK: %[[GEP:.*]] = llvm.getelementptr %[[ALLOCA]][0, 2] : (!llvm.ptr)  -> !llvm.ptr, !llvm.struct<"foo", (i64, i32, i32)>
  // CHECK: llvm.store %[[TRUNC]], %[[GEP]]
  llvm.store %arg, %3 : i64, !llvm.ptr
  // CHECK-NOT: llvm.store %[[ARG]], %[[ALLOCA]]
  llvm.return
}

// -----

// CHECK-LABEL: llvm.func @coalesced_store_floats
// CHECK-SAME: %[[ARG:.*]]: i64
llvm.func @coalesced_store_floats(%arg: i64) {
  // CHECK: %[[CST0:.*]] = llvm.mlir.constant(0 : i64) : i64
  // CHECK: %[[CST32:.*]] = llvm.mlir.constant(32 : i64) : i64
  %0 = llvm.mlir.constant(1 : i32) : i32

  // CHECK: %[[ALLOCA:.*]] = llvm.alloca %{{.*}} x !llvm.struct<"foo", (f32, f32)>
  %1 = llvm.alloca %0 x !llvm.struct<"foo", (f32, f32)> : (i32) -> !llvm.ptr

  // CHECK: %[[GEP:.*]] = llvm.getelementptr %[[ALLOCA]][0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<"foo", (f32, f32)>
  // CHECK: %[[SHR:.*]] = llvm.lshr %[[ARG]], %[[CST0]]
  // CHECK: %[[TRUNC:.*]] = llvm.trunc %[[SHR]] : i64 to i32
  // CHECK: %[[BIT_CAST:.*]] = llvm.bitcast %[[TRUNC]] : i32 to f32
  // CHECK: llvm.store %[[BIT_CAST]], %[[GEP]]
  // CHECK: %[[SHR:.*]] = llvm.lshr %[[ARG]], %[[CST32]] : i64
  // CHECK: %[[TRUNC:.*]] = llvm.trunc %[[SHR]] : i64 to i32
  // CHECK: %[[BIT_CAST:.*]] = llvm.bitcast %[[TRUNC]] : i32 to f32
  // CHECK: %[[GEP:.*]] = llvm.getelementptr %[[ALLOCA]][0, 1] : (!llvm.ptr)  -> !llvm.ptr, !llvm.struct<"foo", (f32, f32)>
  // CHECK: llvm.store %[[BIT_CAST]], %[[GEP]]
  llvm.store %arg, %1 : i64, !llvm.ptr
  // CHECK-NOT: llvm.store %[[ARG]], %[[ALLOCA]]
  llvm.return
}

// -----

// Padding test purposefully not modified.

// CHECK-LABEL: llvm.func @coalesced_store_padding_inbetween
// CHECK-SAME: %[[ARG:.*]]: i64
llvm.func @coalesced_store_padding_inbetween(%arg: i64) {
  %0 = llvm.mlir.constant(1 : i32) : i32

  // CHECK: %[[ALLOCA:.*]] = llvm.alloca %{{.*}} x !llvm.struct<"foo", (i16, i32)>
  %1 = llvm.alloca %0 x !llvm.struct<"foo", (i16, i32)> : (i32) -> !llvm.ptr
  // CHECK: llvm.store %[[ARG]], %[[ALLOCA]]
  llvm.store %arg, %1 : i64, !llvm.ptr
  llvm.return
}

// -----

// Padding test purposefully not modified.

// CHECK-LABEL: llvm.func @coalesced_store_padding_end
// CHECK-SAME: %[[ARG:.*]]: i64
llvm.func @coalesced_store_padding_end(%arg: i64) {
  %0 = llvm.mlir.constant(1 : i32) : i32

  // CHECK: %[[ALLOCA:.*]] = llvm.alloca %{{.*}} x !llvm.struct<"foo", (i32, i16)>
  %1 = llvm.alloca %0 x !llvm.struct<"foo", (i32, i16)> : (i32) -> !llvm.ptr
  // CHECK: llvm.store %[[ARG]], %[[ALLOCA]]
  llvm.store %arg, %1 : i64, !llvm.ptr
  llvm.return
}

// -----

// CHECK-LABEL: llvm.func @coalesced_store_past_end
// CHECK-SAME: %[[ARG:.*]]: i64
llvm.func @coalesced_store_past_end(%arg: i64) {
  %0 = llvm.mlir.constant(1 : i32) : i32

  // CHECK: %[[ALLOCA:.*]] = llvm.alloca %{{.*}} x !llvm.struct<"foo", (i32)>
  %1 = llvm.alloca %0 x !llvm.struct<"foo", (i32)> : (i32) -> !llvm.ptr
  // CHECK: llvm.store %[[ARG]], %[[ALLOCA]]
  llvm.store %arg, %1 : i64, !llvm.ptr
  llvm.return
}

// -----

// CHECK-LABEL: llvm.func @coalesced_store_packed_struct
// CHECK-SAME: %[[ARG:.*]]: i64
llvm.func @coalesced_store_packed_struct(%arg: i64) {
  %0 = llvm.mlir.constant(1 : i32) : i32
  // CHECK: %[[CST0:.*]] = llvm.mlir.constant(0 : i64) : i64
  // CHECK: %[[CST16:.*]] = llvm.mlir.constant(16 : i64) : i64
  // CHECK: %[[CST48:.*]] = llvm.mlir.constant(48 : i64) : i64

  // CHECK: %[[ALLOCA:.*]] = llvm.alloca %{{.*}} x !llvm.struct<"foo", packed (i16, i32, i16)>
  %1 = llvm.alloca %0 x !llvm.struct<"foo", packed (i16, i32, i16)> : (i32) -> !llvm.ptr
  // CHECK: %[[GEP:.*]] = llvm.getelementptr %[[ALLOCA]][0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<"foo", packed (i16, i32, i16)>
  // CHECK: %[[SHR:.*]] = llvm.lshr %[[ARG]], %[[CST0]]
  // CHECK: %[[TRUNC:.*]] = llvm.trunc %[[SHR]] : i64 to i16
  // CHECK: llvm.store %[[TRUNC]], %[[GEP]]
  // CHECK: %[[SHR:.*]] = llvm.lshr %[[ARG]], %[[CST16]]
  // CHECK: %[[TRUNC:.*]] = llvm.trunc %[[SHR]] : i64 to i32
  // CHECK: %[[GEP:.*]] = llvm.getelementptr %[[ALLOCA]][0, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<"foo", packed (i16, i32, i16)>
  // CHECK: llvm.store %[[TRUNC]], %[[GEP]]
  // CHECK: %[[SHR:.*]] = llvm.lshr %[[ARG]], %[[CST48]]
  // CHECK: %[[TRUNC:.*]] = llvm.trunc %[[SHR]] : i64 to i16
  // CHECK: %[[GEP:.*]] = llvm.getelementptr %[[ALLOCA]][0, 2] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<"foo", packed (i16, i32, i16)>
  // CHECK: llvm.store %[[TRUNC]], %[[GEP]]
  llvm.store %arg, %1 : i64, !llvm.ptr
  // CHECK-NOT: llvm.store %[[ARG]], %[[ALLOCA]]
  llvm.return
}
