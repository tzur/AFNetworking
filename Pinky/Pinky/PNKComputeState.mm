// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "PNKComputeState.h"

#import <MetalToolbox/MTBComputePipelineState.h>
#import <MetalToolbox/MTBLibraryLoader.h>

#import "NSBundle+PinkyBundle.h"

NS_ASSUME_NONNULL_BEGIN

id<MTLLibrary> PNKLoadLibrary(id<MTLDevice> device) {
  NSBundle * _Nullable bundle = [NSBundle pnk_bundle];
  LTAssert(bundle, @"Could not find Pinky bundle in the main bundle of the app");
  auto _Nullable metalPath = [bundle pathForResource:@"default" ofType:@"metallib"];
  LTAssert(metalPath, @"Could not find metallib resource in Pinky bundle");
  return MTBLoadLibrary(device, metalPath);
}

id<MTLComputePipelineState> PNKCreateComputeState(id<MTLDevice> device,
    NSString * const functionName, NSArray<MTBFunctionConstant *> * _Nullable constants) {
  auto library = PNKLoadLibrary(device);
  return MTBCreateComputePipelineState(library, functionName, constants);
}

NS_ASSUME_NONNULL_END
