// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "MTBComputePipelineState.h"

#import <LTKitTestUtils/NSBundle+Test.h>

#import "MTBFunctionConstant.h"

DeviceSpecBegin(MTBComputeState)

__block id<MTLLibrary> library;

beforeEach(^{
  auto device = MTLCreateSystemDefaultDevice();
  auto bundle = [NSBundle lt_testBundle];
  auto libraryPath = [bundle pathForResource:@"default" ofType:@"metallib"];
  library = [device newLibraryWithFile:libraryPath error:nil];
});

afterEach(^{
  library = nil;
});

it(@"should create compute state for function without constants", ^{
  auto computeState = MTBCreateComputePipelineState(library, @"functionWithoutConstants");
  expect(computeState).toNot.beNil();
});

it(@"should create compute state for function with array of MTBFunctionConstant objects", ^{
  float coefficient = 0.5;
  auto coefficientData = [NSData dataWithBytes:&coefficient length:sizeof(float)];
  auto functionConstants = @[
    [MTBFunctionConstant constantWithValue:coefficientData type:MTLDataTypeFloat
                                      name:@"coefficient"],
    [MTBFunctionConstant constantWithValue:coefficientData type:MTLDataTypeFloat
                                      name:@"coefficient2"]
  ];

  auto computeState = MTBCreateComputePipelineState(library, @"functionWithConstants",
                                                    functionConstants);
  expect(computeState).toNot.beNil();
});

it(@"should create compute state for function with MTLFunctionConstantValues object", ^{
  float coefficient = 0.5;
  auto functionConstants = [[MTLFunctionConstantValues alloc] init];
  [functionConstants setConstantValue:&coefficient type:MTLDataTypeFloat withName:@"coefficient"];
  [functionConstants setConstantValue:&coefficient type:MTLDataTypeFloat withName:@"coefficient2"];

  auto computeState = MTBCreateComputePipelineState(library, @"functionWithConstants",
                                                    functionConstants);
  expect(computeState).toNot.beNil();
});

it(@"should raise when function is not found in the library", ^{
  expect(^{
    __unused auto computeState = MTBCreateComputePipelineState(library, @"foo");
  }).to.raise(NSInvalidArgumentException);
});

it(@"should raise when number of constants is less than that of the function", ^{
  float coefficient = 0.5;
  auto coefficientData = [NSData dataWithBytes:&coefficient length:sizeof(float)];
  auto functionConstants = @[
    [MTBFunctionConstant constantWithValue:coefficientData type:MTLDataTypeFloat
                                      name:@"coefficient"],
  ];

  expect(^{
    __unused auto computeState = MTBCreateComputePipelineState(library, @"functionWithConstants",
                                                               functionConstants);
  }).to.raise(NSInvalidArgumentException);
});

it(@"should not raise when number of constants is more than that of the function", ^{
  float coefficient = 0.5;
  auto coefficientData = [NSData dataWithBytes:&coefficient length:sizeof(float)];
  auto functionConstants = @[
    [MTBFunctionConstant constantWithValue:coefficientData type:MTLDataTypeFloat
                                      name:@"coefficient"],
    [MTBFunctionConstant constantWithValue:coefficientData type:MTLDataTypeFloat
                                      name:@"coefficient2"],
    [MTBFunctionConstant constantWithValue:coefficientData type:MTLDataTypeFloat
                                      name:@"coefficient3"],
  ];
  expect(^{
    __unused auto computeState = MTBCreateComputePipelineState(library, @"functionWithConstants",
                                                               functionConstants);
  }).notTo.raiseAny();
});

it(@"should raise when names of constants do not match that of the function", ^{
  float coefficient = 0.5;
  auto coefficientData = [NSData dataWithBytes:&coefficient length:sizeof(float)];
  auto functionConstants = @[
    [MTBFunctionConstant constantWithValue:coefficientData type:MTLDataTypeFloat name:@"foo"],
    [MTBFunctionConstant constantWithValue:coefficientData type:MTLDataTypeFloat
                                      name:@"coefficient2"]
  ];

  expect(^{
    __unused auto computeState = MTBCreateComputePipelineState(library, @"functionWithConstants",
                                                               functionConstants);
  }).to.raise(NSInvalidArgumentException);
});

it(@"should raise when types of constants does not match that of the function", ^{
  float coefficient = 0.5;
  auto coefficientData = [NSData dataWithBytes:&coefficient length:sizeof(float)];
  auto functionConstants = @[
    [MTBFunctionConstant constantWithValue:coefficientData type:MTLDataTypeInt name:@"coefficient"],
    [MTBFunctionConstant constantWithValue:coefficientData type:MTLDataTypeFloat
                                      name:@"coefficient2"]
  ];

  expect(^{
    __unused auto computeState = MTBCreateComputePipelineState(library, @"functionWithConstants",
                                                               functionConstants);
  }).to.raise(NSInvalidArgumentException);
});

DeviceSpecEnd
