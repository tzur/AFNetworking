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

- (instancetype)initWithBaseTexture:(LTTexture *)baseTexture baseMask:(LTTexture *)baseMask
                          frameMask:(LTTexture *)frameMask frameType:(LTFrameType)frameType {
  return [self initWithBaseTexture:baseTexture baseMask:baseMask frameMask:frameMask
                         frameType:frameType mapBaseToFullImageSize:NO];
}

- (instancetype)initWithBaseTexture:(LTTexture *)baseTexture baseMask:(LTTexture *)baseMask
                          frameMask:(LTTexture *)frameMask frameType:(LTFrameType)frameType
         mapBaseToFullImageSize:(BOOL)mapBaseToFullImageSize {
  if (self = [super init]) {
    _baseTexture = baseTexture ?: [LTTexture textureWithImage:cv::Mat4b::zeros(1, 1)];
    _baseMask = baseMask ?: [LTTexture textureWithImage:cv::Mat1b::zeros(1, 1)];
    _frameMask = frameMask ?: [LTTexture textureWithImage:cv::Mat1b(1, 1, 255)];
    _frameType = frameType;
    _mapBaseToFullImageSize = mapBaseToFullImageSize;
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
  }
  return self;
}

- (instancetype)initWithImageFrameProcessor:(LTImageFrameProcessor *)other {
  if (self = [self initWithInput:other.inputTexture output:other.outputTexture]) {
    self.widthFactor = other.widthFactor;
    self.color = other.color;
    self.globalBaseMaskAlpha = other.globalBaseMaskAlpha;
    self.globalFrameMaskAlpha = other.globalFrameMaskAlpha;
  }
  return self;
}

- (void)setImageFrame:(LTImageFrame *)imageFrame {
  [self assertImageFrameCorrectness:imageFrame];
  _imageFrame = imageFrame;
  NSDictionary *auxiliaryTextures =
      @{[LTImageFrameFsh baseTexture]: imageFrame.baseTexture,
        [LTImageFrameFsh baseMaskTexture]: imageFrame.baseMask,
        [LTImageFrameFsh frameMaskTexture]: imageFrame.frameMask};
  [self setAuxiliaryTextures:auxiliaryTextures];
  self[[LTImageFrameFsh frameType]] = @(imageFrame.frameType);
  self[[LTImageFrameFsh mapBaseToFullImageSize]] = @(imageFrame.mapBaseToFullImageSize);
}

- (void)assertImageFrameCorrectness:(LTImageFrame *)imageFrame {
  LTParameterAssert((imageFrame.baseTexture.size.width == imageFrame.baseTexture.size.height) &&
                    (imageFrame.baseMask.size.width == imageFrame.baseMask.size.height));
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
#pragma mark Processing
#pragma mark -

- (void)process {
  self[[LTImageFrameFsh readColorFromOutput]] = @(self.inputTexture == self.outputTexture);
  [super process];
}

- (void)processToFramebufferWithSize:(CGSize)size outputRect:(CGRect)rect {
  // When processing to screen we do not want to read color from the framebuffer, but rather from
  // the input texture, since the framebuffer does not have the relevant data on it.
  self[[LTImageFrameFsh readColorFromOutput]] = @NO;
  [super processToFramebufferWithSize:size outputRect:rect];
}

#pragma mark -
#pragma mark Properties
#pragma mark -

LTPropertyWithoutSetter(CGFloat, widthFactor, WidthFactor, 0.85, 1.5, 1);
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
