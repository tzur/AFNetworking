// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTClarityProcessor.h"

#import "LTBicubicResizeProcessor.h"
#import "LTBilateralFilterProcessor.h"
#import "LTGPUImageProcessor+Protected.h"
#import "LTGLKitExtensions.h"
#import "LTProgram.h"
#import "LTRectCopyProcessor.h"
#import "LTShaderStorage+LTClarityFsh.h"
#import "LTShaderStorage+LTPassthroughShaderVsh.h"
#import "LTTexture+Factory.h"

@interface LTGPUImageProcessor ()
@property (strong, nonatomic) NSDictionary *auxiliaryTextures;
@end

@interface LTClarityProcessor ()

/// The generation id of the input texture that was used to create the current smooth textures.
@property (nonatomic) id inputTextureGenerationID;

@end

@implementation LTClarityProcessor

- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output {
  if (self = [super initWithVertexSource:[LTPassthroughShaderVsh source]
                          fragmentSource:[LTClarityFsh source] input:input andOutput:output]) {
    [self resetInputModel];
  }
  return self;
}

- (void)updateSmoothTextureIfNecessary {
  if (![self.inputTextureGenerationID isEqual:self.inputTexture.generationID] ||
      !self.auxiliaryTextures[[LTClarityFsh downsampledTexture]] ||
      !self.auxiliaryTextures[[LTClarityFsh bilateralTexture]] ||
      !self.auxiliaryTextures[[LTClarityFsh smoothTexture]]) {
    self.inputTextureGenerationID = self.inputTexture.generationID;
    [self createImageDecomposition];
  }
}

- (void)createImageDecomposition {
  LTTexture *downsampledTexture = [self createDownsampledTexture:self.inputTexture];
  [self setAuxiliaryTexture:downsampledTexture withName:[LTClarityFsh downsampledTexture]];

  LTTexture *bilateralTexture = [self createBilateralTexture:downsampledTexture];
  [self setAuxiliaryTexture:bilateralTexture withName:[LTClarityFsh bilateralTexture]];

  LTTexture *smoothTexture = [self createSmoothTexture:bilateralTexture];
  [self setAuxiliaryTexture:smoothTexture withName:[LTClarityFsh smoothTexture]];
}

- (LTTexture *)createDownsampledTexture:(LTTexture *)texture {
  LTTexture *output =
      [LTTexture byteRGBATextureWithSize:std::ceil(texture.size / 2)];
  [[[LTBicubicResizeProcessor alloc] initWithInput:texture output:output] process];
  return output;
}

- (LTTexture *)createBilateralTexture:(LTTexture *)texture {
  LTTexture *output = [LTTexture byteRGBATextureWithSize:texture.size];
  LTBilateralFilterProcessor *processor =
      [[LTBilateralFilterProcessor alloc] initWithInput:texture outputs:@[output]];
  processor.rangeSigma = 0.05;
  processor.iterationsPerOutput = @[@10];
  [processor process];

  return output;
}

- (LTTexture *)createSmoothTexture:(LTTexture *)texture {
  CGSize size = CGSizeAspectFit(self.outputSize, CGSizeMakeUniform(64));
  LTTexture *output = [LTTexture byteRGBATextureWithSize:size];
  [[[LTRectCopyProcessor alloc] initWithInput:texture output:output] process];
  [output mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
    cv::GaussianBlur(*mapped, *mapped, cv::Size(25, 25), 5);
  }];

  return output;
}

#pragma mark -
#pragma mark Input model
#pragma mark -

+ (NSSet *)inputModelPropertyKeys {
  static NSSet *properties;
  
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    properties = [NSSet setWithArray:@[
      @instanceKeypath(LTClarityProcessor, sharpen),
      @instanceKeypath(LTClarityProcessor, fineContrast),
      @instanceKeypath(LTClarityProcessor, mediumContrast),
      @instanceKeypath(LTClarityProcessor, blackPointShift),
      @instanceKeypath(LTClarityProcessor, flatten),
      @instanceKeypath(LTClarityProcessor, gain),
      @instanceKeypath(LTClarityProcessor, saturation)
    ]];
  });
  
  return properties;
}

#pragma mark -
#pragma mark Processing
#pragma mark -

- (void)preprocess {
  [self updateSmoothTextureIfNecessary];
}

#pragma mark -
#pragma mark Properties
#pragma mark -

LTPropertyWithoutSetter(CGFloat, sharpen, Sharpen, -1, 1, 0);
- (void)setSharpen:(CGFloat)sharpen {
  [self _verifyAndSetSharpen:sharpen];
  self[[LTClarityFsh sharpen]] = @([self remap:sharpen withScale:2]);
}

LTPropertyWithoutSetter(CGFloat, fineContrast, FineContrast, -1, 1, 0);
- (void)setFineContrast:(CGFloat)fineContrast {
  [self _verifyAndSetFineContrast:fineContrast];
  self[[LTClarityFsh fineContrast]] = @([self remap:fineContrast withScale:1.5]);
}

LTPropertyWithoutSetter(CGFloat, mediumContrast, MediumContrast, -1, 1, 0);
- (void)setMediumContrast:(CGFloat)mediumContrast {
  [self _verifyAndSetMediumContrast:mediumContrast];
  self[[LTClarityFsh mediumContrast]] = @([self remap:mediumContrast withScale:1.5]);
}

static const CGFloat kFlattenSigmaScaling = 0.9;

LTPropertyWithoutSetter(CGFloat, flatten, Flatten, 0, 1, 0);
- (void)setFlatten:(CGFloat)flatten {
  [self _verifyAndSetFlatten:flatten];
  CGFloat flattenA = 1.0 - flatten * kFlattenSigmaScaling;
  CGFloat flattenBlend = [LTClarityProcessor smoothstepWithEdge0:0 edge1:0.1 value:flatten];
  self[[LTClarityFsh flattenA]] = @(flattenA);
  self[[LTClarityFsh flattenBlend]] = @(flattenBlend);
}

+ (CGFloat)smoothstepWithEdge0:(CGFloat)edge0 edge1:(CGFloat)edge1 value:(CGFloat)value {
  CGFloat x = std::clamp((value - edge0) / (edge1 - edge0), 0, 1);
  return x * x * (3 - 2 * x);
}

LTPropertyWithoutSetter(CGFloat, blackPointShift, BlackPointShift, -1, 1, 0);
- (void)setBlackPointShift:(CGFloat)blackPointShift {
  [self _verifyAndSetBlackPointShift:blackPointShift];
  self[[LTClarityFsh blackPoint]] = @(blackPointShift * 0.8);
}

LTPropertyWithoutSetter(CGFloat, gain, Gain, 0, 1, 0);
- (void)setGain:(CGFloat)gain {
  [self _verifyAndSetGain:gain];
  self[[LTClarityFsh gain]] = @(gain);
}

LTPropertyWithoutSetter(CGFloat, saturation, Saturation, -1, 1, 0);
- (void)setSaturation:(CGFloat)saturation {
  [self _verifyAndSetSaturation:saturation];
  self[[LTClarityFsh saturation]] = @([self remap:saturation withScale:1]);
}

- (CGFloat)remap:(CGFloat)input withScale:(CGFloat)scale {
  return input < 0 ? input + 1 : 1 + input * scale;
}

@end
