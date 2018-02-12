// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "PNKComputeState.h"

#import "PNKLibraryLoader.h"

NS_ASSUME_NONNULL_BEGIN

/// MTLFunctionConstantValues is not supported in simulator for Xcode 8. Solved in Xcode 9.
#if PNK_USE_MPS

static id<MTLComputePipelineState> PNKCreateComputeStateWithParameters(id<MTLDevice> device,
    NSString *functionName, MTLFunctionConstantValues * _Nullable constants)
    API_AVAILABLE(ios(10.0)) {
  auto library = PNKLoadLibrary(device);
  NSError *error;
  id<MTLFunction> function;
  if (constants) {
    function = [library newFunctionWithName:functionName constantValues:constants error:&error];
  } else {
    function = [library newFunctionWithName:functionName];
  }
  LTAssert(function, @"Can't create function with name %@. Got error %@", functionName, error);
  auto state = [device newComputePipelineStateWithFunction:function error:&error];
  LTAssert(state, @"Can't create compute pipeline state for function %@. Got error %@",
           function.name, error);
  return state;
}

id<MTLComputePipelineState> PNKCreateComputeState(id<MTLDevice> device, NSString *functionName) {
  return PNKCreateComputeStateWithParameters(device, functionName, nil);
}

id<MTLComputePipelineState> PNKCreateComputeStateWithConstants(id<MTLDevice> device,
    NSString *functionName, MTLFunctionConstantValues *constants) {
  return PNKCreateComputeStateWithParameters(device, functionName, constants);
}

#endif // PNK_USE_MPS

NS_ASSUME_NONNULL_END
