// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "MTBComputePipelineState.h"

#import <LTKit/NSArray+Functional.h>

#import "MTBFunctionConstant.h"

NS_ASSUME_NONNULL_BEGIN

static void MTBValidateConstants(id<MTLFunction> function,
                                 NSArray<MTBFunctionConstant *> * _Nullable userConstants) {
  NSMutableDictionary<NSString *, MTLFunctionConstant *> *functionConstants =
      [function.functionConstantsDictionary mutableCopy];
  LTParameterAssert(userConstants.count >= functionConstants.count, @"Function constants array is "
                    "expected to have at least %lu members, got %lu",
                    (unsigned long)functionConstants.count, (unsigned long)userConstants.count);

  for (MTBFunctionConstant *userConstant in userConstants) {
    auto _Nullable functionConstant = functionConstants[userConstant.name];
    if (functionConstant) {
      LTParameterAssert(userConstant.type == functionConstant.type, @"Function constant %@ is "
                        "expected to have MTLDataType of %lu, got %lu", userConstant.name,
                        (unsigned long)functionConstant.type, (unsigned long)userConstant.type);
      [functionConstants removeObjectForKey:userConstant.name];
    }
  }

  LTParameterAssert(functionConstants.count == 0, @"Functions constant(s) with name(s) '%@' were "
                    "not provided by user", functionConstants.allKeys);
}

static id<MTLFunction> MTBFunction(id<MTLLibrary> library, NSString *functionName,
                                   MTLFunctionConstantValues * _Nullable constants = nil) {
  NSError *error;
  auto _Nullable function = constants ?
      [library newFunctionWithName:functionName constantValues:nn(constants) error:&error] :
      [library newFunctionWithName:functionName];
  LTParameterAssert(function, @"Can't create function with name %@. Got error %@", functionName,
                    error);
  return nn(function);
}

static id<MTLFunction> MTBFunction(id<MTLLibrary> library, NSString *functionName,
                                   NSArray<MTBFunctionConstant *> * _Nullable constants) {
  MTLFunctionConstantValues * _Nullable functionConstants;

  if (constants) {
    functionConstants = [[MTLFunctionConstantValues alloc] init];
    for (MTBFunctionConstant *constant in constants) {
      [functionConstants setConstantValue:constant.value.bytes type:constant.type
                                 withName:constant.name];
    }
  }

  return MTBFunction(library, functionName, functionConstants);
}

static id<MTLComputePipelineState> MTBComputePipelineStateFromFunction(id<MTLFunction> function) {
  NSError *error;
  auto _Nullable state = [function.device newComputePipelineStateWithFunction:function
                                                                        error:&error];
  LTParameterAssert(state, @"Can't create compute pipeline state for function %@. Got error %@",
                    function.name, error);
  return nn(state);
}

id<MTLComputePipelineState> MTBCreateComputePipelineState(id<MTLLibrary> library,
    NSString *functionName, NSArray<MTBFunctionConstant *> * _Nullable constants) {
#if defined(DEBUG) && DEBUG
  auto function = MTBFunction(library, functionName);
  MTBValidateConstants(function, constants);
  if (constants) {
    function = MTBFunction(library, functionName, constants);
  }
#else
  auto function = MTBFunction(library, functionName, constants);
#endif
  return MTBComputePipelineStateFromFunction(function);
}

id<MTLComputePipelineState> MTBCreateComputePipelineState(id<MTLLibrary> library,
    NSString *functionName, MTLFunctionConstantValues *constants) {
  auto function = MTBFunction(library, functionName, constants);
  return MTBComputePipelineStateFromFunction(function);
}

NS_ASSUME_NONNULL_END
