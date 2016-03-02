// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTBilateralFilterProcessor.h"

#import "LTGPUImageProcessor+Protected.h"
#import "LTProgram.h"
#import "LTRectDrawer.h"
#import "LTShaderStorage+LTBilateralFilterFsh.h"
#import "LTShaderStorage+LTBilateralFilterVsh.h"
#import "LTTexture.h"

@implementation LTBilateralFilterProcessor

- (instancetype)initWithInput:(LTTexture *)input outputs:(NSArray *)outputs {
  return [self initWithInput:input guide:input outputs:outputs];
}

- (instancetype)initWithInput:(LTTexture *)input guide:(LTTexture *)guide
                      outputs:(NSArray *)outputs {
  LTParameterAssert(input.size == guide.size, @"Input and guide textures should have the same size "
                    "(%@ vs. %@)", NSStringFromCGSize(input.size), NSStringFromCGSize(guide.size));
  
  return [super initWithVertexSource:[LTBilateralFilterVsh source]
                      fragmentSource:[LTBilateralFilterFsh source]
                       sourceTexture:input
                   auxiliaryTextures:@{[LTBilateralFilterFsh originalTexture]: guide}
                             outputs:outputs];
}
- (void)setRangeSigma:(float)rangeSigma {
  self[[LTBilateralFilterFsh rangeSigma]] = @(rangeSigma);
}

- (float)rangeSigma {
  return [self[[LTBilateralFilterFsh rangeSigma]] floatValue];
}

@end
