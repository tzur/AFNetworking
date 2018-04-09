// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKTestComputeState.h"

NS_ASSUME_NONNULL_BEGIN

static id<MTLLibrary> PNKLoadMetalLibrary(id<MTLDevice> device) {
  static auto mapTable =
      [NSMapTable mapTableWithKeyOptions:NSMapTableWeakMemory | NSMapTableObjectPointerPersonality
                            valueOptions:NSMapTableStrongMemory];

  static auto lock = [[NSLock alloc] init];
  [lock lock];

  id<MTLLibrary> _Nullable library = [mapTable objectForKey:device];
  if (library) {
    [lock unlock];
    return library;
  }

  NSBundle * _Nullable bundle = [NSBundle lt_testBundle];
  auto _Nullable metalPath = [bundle pathForResource:@"default" ofType:@"metallib"];
  LTAssert(metalPath, @"Could not find metallib resource in PinkyDeviceTests bundle");

  NSError *error;
  library = [device newLibraryWithFile:metalPath error:&error];
  LTAssert(library, @"Could not create MTLLibrary from path %@. Error: %@", metalPath, error);
  [mapTable setObject:library forKey:device];
  [lock unlock];
  return library;
}

id<MTLComputePipelineState> PNKCreateTestComputeState(id<MTLDevice> device,
                                                      NSString *functionName) {
  auto library = PNKLoadMetalLibrary(device);

  NSError *error;
  auto function = [library newFunctionWithName:functionName];

  LTAssert(function, @"Can't create function with name %@. Got error %@", functionName, error);
  auto state = [device newComputePipelineStateWithFunction:function error:&error];
  LTAssert(state, @"Can't create compute pipeline state for function %@. Got error %@",
           functionName, error);
  return state;
}

NS_ASSUME_NONNULL_END
