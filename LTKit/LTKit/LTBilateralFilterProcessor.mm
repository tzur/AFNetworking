// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTBilateralFilterProcessor.h"

#import "LTProgram.h"
#import "LTRectDrawer.h"
#import "LTShaderStorage+LTBilateralFilterFsh.h"
#import "LTShaderStorage+LTBilateralFilterVsh.h"
#import "LTTexture.h"

@interface LTBilateralFilterProcessor ()
@property (nonatomic) CGSize inputSize;
@property (nonatomic) CGSize outputSize;
@end

@implementation LTBilateralFilterProcessor

- (instancetype)initWithInput:(LTTexture *)input outputs:(NSArray *)outputs {
  return [super initWithProgram:[self createProgram] sourceTexture:input
              auxiliaryTextures:@{[LTBilateralFilterFsh originalTexture]: input}
                        outputs:outputs];
}

- (LTProgram *)createProgram {
  return [[LTProgram alloc] initWithVertexSource:[LTBilateralFilterVsh source]
                                  fragmentSource:[LTBilateralFilterFsh source]];
}

- (void)setRangeSigma:(float)rangeSigma {
  self[[LTBilateralFilterFsh rangeSigma]] = @(rangeSigma);
}

- (float)rangeSigma {
  return [self[[LTBilateralFilterFsh rangeSigma]] floatValue];
}

@end
