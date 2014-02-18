// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTMaskedArithmeticProcessor.h"

#import "LTCGExtensions.h"
#import "LTProgram.h"
#import "LTShaderStorage+LTMaskedArithmeticFsh.h"
#import "LTShaderStorage+LTPassthroughShaderVsh.h"
#import "LTTexture.h"

@implementation LTMaskedArithmeticProcessor

- (instancetype)initWithFirstOperand:(LTTexture *)first secondOperand:(LTTexture *)second
                                mask:(LTTexture *)mask output:(LTTexture *)output {
  LTParameterAssert(first.size == second.size && second.size == mask.size,
                    @"Operands and mask textures must be of the same size");

  LTProgram *program = [[LTProgram alloc] initWithVertexSource:[LTPassthroughShaderVsh source]
                                                fragmentSource:[LTMaskedArithmeticFsh source]];
  NSDictionary *auxiliaryTextures = @{[LTMaskedArithmeticFsh firstTexture]: first,
                                      [LTMaskedArithmeticFsh secondTexture]: second};
  return [super initWithProgram:program sourceTexture:mask auxiliaryTextures:auxiliaryTextures
                      andOutput:output];
}

@end
