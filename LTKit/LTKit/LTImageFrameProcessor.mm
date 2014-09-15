// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Shabtay.

#import "LTImageFrameProcessor.h"

#import "LTGPUImageProcessor+Protected.h"
#import "LTProgram.h"
#import "LTShaderStorage+LTImageFrameFsh.h"
#import "LTShaderStorage+LTPassthroughShaderVsh.h"
#import "LTTexture+Factory.h"

@implementation LTImageFrameProcessor

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output {
  if (self = [super initWithVertexSource:[LTPassthroughShaderVsh source]
                          fragmentSource:[LTImageFrameFsh source] input:input andOutput:output]) {
    [self setDefaultValues];
    [self setAspectRatioUniforms];
    [self setFrameNone];
  }
  return self;
}

- (void)setDefaultValues {
  self.widthFactor = self.defaultWidthFactor;
  self.color = self.defaultColor;
  self.colorAlpha = self.defaultColorAlpha;
}

- (void)setAspectRatioUniforms {
  CGFloat aspectRatio = self.inputSize.width / self.inputSize.height;
  CGFloat aspectRatioLongerApect = aspectRatio > 1.0 ? aspectRatio : 1.0 / aspectRatio;
  CGFloat repetitionFactor = std::round((aspectRatioLongerApect - 2.0 / 3.0) * 3.0);
  self[[LTImageFrameFsh aspectRatio]] = @(aspectRatio);
  self[[LTImageFrameFsh repetitionFactor]] = @(repetitionFactor);
}

- (void)setFrameNone {
  cv::Mat4b originalFrame(1, 1, cv::Vec4b(0, 0, 0, 0));
  [self setFrame:[LTTexture textureWithImage:originalFrame] andType:LTFrameTypeStretch];
}

- (void)setFrame:(LTTexture *)frame andType:(LTFrameType)frameType {
  LTParameterAssert(frame);
  [self setAuxiliaryTexture:frame withName:[LTImageFrameFsh frameTexture]];
  self[[LTImageFrameFsh frameType]] = @(frameType);
}

#pragma mark -
#pragma mark Properties
#pragma mark -

LTPropertyWithoutSetter(CGFloat, widthFactor, WidthFactor, 0.75, 1.5, 1.0);
- (void)setWidthFactor:(CGFloat)widthFactor {
  [self _verifyAndSetWidthFactor:widthFactor];
  self[[LTImageFrameFsh frameWidthFactor]] = @(widthFactor);
}

LTPropertyWithoutSetter(LTVector3, color, Color, LTVector3Zero, LTVector3One, LTVector3Zero);
- (void)setColor:(LTVector3)color {
  [self _verifyAndSetColor:color];
  self[[LTImageFrameFsh frameColor]] = $(color);
}

LTPropertyWithoutSetter(CGFloat, colorAlpha, ColorAlpha, 0.0, 1.0, 0.0);
- (void)setColorAlpha:(CGFloat)colorAlpha {
  [self _verifyAndSetColorAlpha:colorAlpha];
  self[[LTImageFrameFsh frameColorAlpha]] = @(colorAlpha);
}

@end
