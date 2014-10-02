// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Shabtay.

#import "LTImageFrameProcessor.h"

#import "LTGPUImageProcessor+Protected.h"
#import "LTMathUtils.h"
#import "LTProgram.h"
#import "LTShaderStorage+LTImageFrameFsh.h"
#import "LTShaderStorage+LTPassthroughShaderVsh.h"
#import "LTTexture+Factory.h"

#pragma mark -
#pragma mark LTImageFrame
#pragma mark -

@implementation LTImageFrame

- (instancetype)init {
  if (self = [super init]) {
    _baseTexture = [LTTexture textureWithImage:cv::Mat4b::zeros(1, 1)];
    _baseMask = [LTTexture textureWithImage:cv::Mat1b::zeros(1, 1)];
    _frameMask = [LTTexture textureWithImage:cv::Mat1b(1, 1, 255)];
    _frameType = LTFrameTypeStretch;
  }
  return self;
}

- (instancetype)initBaseTexture:(LTTexture *)baseTexture baseMask:(LTTexture *)baseMask
                      frameMask:(LTTexture *)frameMask frameType:(LTFrameType)frameType {
  if (self = [super init]) {
    _baseTexture = baseTexture ?: [LTTexture textureWithImage:cv::Mat4b::zeros(1, 1)];
    _baseMask = baseMask ?: [LTTexture textureWithImage:cv::Mat1b::zeros(1, 1)];
    _frameMask = frameMask ?: [LTTexture textureWithImage:cv::Mat1b(1, 1, 255)];
    _frameType = frameType;
  }
  return self;
}

@end

#pragma mark -
#pragma mark LTImageFrameProcessor
#pragma mark -

@implementation LTImageFrameProcessor

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output {
  if (self = [super initWithVertexSource:[LTPassthroughShaderVsh source]
                          fragmentSource:[LTImageFrameFsh source] input:input andOutput:output]) {
    [self resetInputModel];
    [self setImageFrame:[[LTImageFrame alloc] init]];
    [self setAspectRatioUniforms];
    self[[LTImageFrameFsh isTileable]] = @NO;
    self[[LTImageFrameFsh inputEqualsOutput]] = @(input == output);
  }
  return self;
}

- (void)setImageFrame:(LTImageFrame *)imageFrame {
  [self assertImageFrameCorrectness:imageFrame];
  NSDictionary *auxiliaryTextures =
      @{[LTImageFrameFsh baseTexture]: imageFrame.baseTexture,
        [LTImageFrameFsh baseMaskTexture]: imageFrame.baseMask,
        [LTImageFrameFsh frameMaskTexture]: imageFrame.frameMask};
  [self setAuxiliaryTextures:auxiliaryTextures];
  self[[LTImageFrameFsh frameType]] = @(imageFrame.frameType);
}

- (void)assertImageFrameCorrectness:(LTImageFrame *)imageFrame {
  LTParameterAssert((imageFrame.baseTexture.size.width == imageFrame.baseTexture.size.height) &&
                    (imageFrame.baseMask.size.width == imageFrame.baseMask.size.height) &&
                    (imageFrame.frameMask.size.width == imageFrame.frameMask.size.height));
}

#pragma mark -
#pragma mark Input model
#pragma mark -

+ (NSSet *)inputModelPropertyKeys {
  static NSSet *properties;
  
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    properties = [NSSet setWithArray:@[
      @instanceKeypath(LTImageFrameProcessor, widthFactor),
      @instanceKeypath(LTImageFrameProcessor, color),
      @instanceKeypath(LTImageFrameProcessor, globalBaseMaskAlpha),
      @instanceKeypath(LTImageFrameProcessor, globalFrameMaskAlpha)
    ]];
  });
  
  return properties;
}

#pragma mark -
#pragma mark Uniforms
#pragma mark -

- (void)setAspectRatioUniforms {
  CGFloat aspectRatio = self.inputSize.width / self.inputSize.height;
  CGFloat aspectRatioLongerApect = aspectRatio > 1.0 ? aspectRatio : 1.0 / aspectRatio;
  CGFloat repetitionFactor = std::round((aspectRatioLongerApect - 2.0 / 3.0) * 3.0);
  self[[LTImageFrameFsh aspectRatio]] = @(aspectRatio);
  self[[LTImageFrameFsh repetitionFactor]] = @(repetitionFactor);
}

#pragma mark -
#pragma mark Properties
#pragma mark -

LTPropertyWithoutSetter(CGFloat, widthFactor, WidthFactor, 0.75, 1.5, 1);
- (void)setWidthFactor:(CGFloat)widthFactor {
  [self _verifyAndSetWidthFactor:widthFactor];
  self[[LTImageFrameFsh frameWidthFactor]] = @(widthFactor);
}

LTPropertyWithoutSetter(LTVector3, color, Color, LTVector3Zero, LTVector3One, LTVector3Zero);
- (void)setColor:(LTVector3)color {
  [self _verifyAndSetColor:color];
  self[[LTImageFrameFsh frameColor]] = $(color);
}

LTPropertyWithoutSetter(CGFloat, globalBaseMaskAlpha, GlobalBaseMaskAlpha, 0, 1, 1);
- (void)setGlobalBaseMaskAlpha:(CGFloat)globalBaseMaskAlpha {
  [self _verifyAndSetGlobalBaseMaskAlpha:globalBaseMaskAlpha];
  self[[LTImageFrameFsh globalBaseMaskAlpha]] = @(globalBaseMaskAlpha);
}

LTPropertyWithoutSetter(CGFloat, globalFrameMaskAlpha, GlobalFrameMaskAlpha, 0, 1, 1);
- (void)setGlobalFrameMaskAlpha:(CGFloat)globalFrameMaskAlpha {
  [self _verifyAndSetGlobalFrameMaskAlpha:globalFrameMaskAlpha];
  self[[LTImageFrameFsh globalFrameMaskAlpha]] = @(globalFrameMaskAlpha);
}

@end
