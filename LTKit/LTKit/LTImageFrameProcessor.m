// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Shabtay.

#import "LTImageFrameProcessor.h"

#import "LTGPUImageProcessor+Protected.h"
#import "LTProgram.h"
#import "LTShaderStorage+LTImageFrameFsh.h"
#import "LTShaderStorage+LTPassthroughShaderVsh.h"

@implementation LTImageFrameProcessor

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output frame:(LTTexture *)frame
                    frameType:(LTFrameType)frameType {
  NSDictionary *auxiliaryTextures = @{[LTImageFrameFsh frameTexture]: frame};

  if (self = [super initWithVertexSource:[LTPassthroughShaderVsh source]
                          fragmentSource:[LTImageFrameFsh source] sourceTexture:input
                       auxiliaryTextures:auxiliaryTextures andOutput:output]) {
    [self setDefaultValues];
    [self setShaderUniforms:frameType];
  }
  return self;
}

- (void)setDefaultValues {
  self.widthFactor = self.defaultWidthFactor;
}

- (void)setShaderUniforms:(LTFrameType)frameType {
  CGFloat aspectRatio = self.inputSize.width / self.inputSize.height;
  CGFloat aspectRatioLongerApect = aspectRatio > 1.0 ? aspectRatio : 1.0 / aspectRatio;
  CGFloat repetitionFactor = roundf((aspectRatioLongerApect - 2.0 / 3.0) * 3.0);
  self[[LTImageFrameFsh aspectRatio]] = @(aspectRatio);
  self[[LTImageFrameFsh repetitionFactor]] = @(repetitionFactor);
  self[[LTImageFrameFsh frameType]] = @(frameType);
}

#pragma mark -
#pragma mark Properties
#pragma mark -

LTPropertyWithoutSetter(CGFloat, widthFactor, WidthFactor, 0.5, 1.5, 1.0);
- (void)setWidthFactor:(CGFloat)widthFactor {
  [self _verifyAndSetWidthFactor:widthFactor];
  self[[LTImageFrameFsh frameWidthFactor]] = @(widthFactor);
}

@end
