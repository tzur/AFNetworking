// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTArithmeticProcessor.h"

#import "LTGPUImageProcessor+Protected.h"
#import "LTProgram.h"
#import "LTShaderStorage+LTPassthroughShaderVsh.h"
#import "LTShaderStorage+LTArithmeticFsh.h"
#import "LTTexture.h"

NS_ASSUME_NONNULL_BEGIN

@implementation LTArithmeticProcessor

- (instancetype)initWithFirstOperand:(LTTexture *)first secondOperand:(LTTexture *)second
                              output:(LTTexture *)output {
  LTParameterAssert(first.size == second.size, @"Operand textures must be of the same size");

  NSDictionary *auxiliaryTextures = @{[LTArithmeticFsh secondTexture]: second};
  if (self = [super initWithVertexSource:[LTPassthroughShaderVsh source]
                          fragmentSource:[LTArithmeticFsh source]
                           sourceTexture:first auxiliaryTextures:auxiliaryTextures
                               andOutput:output]) {
    self[[LTArithmeticFsh firstInSituProcessing]] = @(first == output);
    self[[LTArithmeticFsh secondInSituProcessing]] = @(second == output);
  }
  return self;
}

- (void)setOperation:(LTArithmeticOperation)operation {
  _operation = operation;
  self[[LTArithmeticFsh operationType]] = @(operation);
}

@end

NS_ASSUME_NONNULL_END
