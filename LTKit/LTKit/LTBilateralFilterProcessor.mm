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
  return [super initWithProgram:[self createProgram] sourceTexture:input outputs:outputs];
}

- (LTProgram *)createProgram {
  return [[LTProgram alloc] initWithVertexSource:[LTShaderStorage LTBilateralFilterVsh]
                                  fragmentSource:[LTShaderStorage LTBilateralFilterFsh]];
}

- (void)setRangeSigma:(float)rangeSigma {
  self[@"rangeSigma"] = @(rangeSigma);
}

- (float)rangeSigma {
  return [self[@"rangeSigma"] floatValue];
}

@end
