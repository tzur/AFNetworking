// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTClarityProcessor.h"

#import "LTBicubicResizeProcessor.h"
#import "LTBilateralFilterProcessor.h"
#import "LTCGExtensions.h"
#import "LTEAWProcessor.h"
#import "LTGPUImageProcessor+Protected.h"
#import "LTGLKitExtensions.h"
#import "LTProgram.h"
#import "LTShaderStorage+LTClarityFsh.h"
#import "LTShaderStorage+LTPassthroughShaderVsh.h"
#import "LTTexture+Factory.h"

@interface LTGPUImageProcessor ()
@property (strong, nonatomic) NSDictionary *auxiliaryTextures;
@end

@interface LTClarityProcessor ()

/// The generation id of the input texture that was used to create the current smooth textures.
@property (nonatomic) NSUInteger inputTextureGenerationID;

@end

@implementation LTClarityProcessor

- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output {
  if (self = [super initWithVertexSource:[LTPassthroughShaderVsh source]
                          fragmentSource:[LTClarityFsh source] input:input andOutput:output]) {
    [self setDefaultValues];
  }
  return self;
}

- (void)setDefaultValues {
  self.sharpen = self.defaultSharpen;
  self.fineContrast = self.defaultFineContrast;
  self.mediumContrast = self.defaultMediumContrast;
  self.flatten = self.defaultFlatten;
  self.gain = self.defaultGain;
  self.saturation = self.defaultSaturation;
}

- (void)updateSmoothTextureIfNecessary {
  if (self.inputTextureGenerationID != self.inputTexture.generationID ||
      !self.auxiliaryTextures[[LTClarityFsh downsampledTexture]] ||
      !self.auxiliaryTextures[[LTClarityFsh bilateralTexture]] ||
      !self.auxiliaryTextures[[LTClarityFsh eawTexture]]) {
    self.inputTextureGenerationID = self.inputTexture.generationID;
    [self createImageDecomposition];
  }
}

- (void)createImageDecomposition {
  LTTexture *downsampledTexture = [self createDownsampledTexture:self.inputTexture];
  [self setAuxiliaryTexture:downsampledTexture withName:[LTClarityFsh downsampledTexture]];

  LTTexture *bilateralTexture = [self createBilateralTexture:downsampledTexture];
  [self setAuxiliaryTexture:bilateralTexture withName:[LTClarityFsh bilateralTexture]];

  LTTexture *eawTexture = [self createEAWTexture:bilateralTexture];
  [self setAuxiliaryTexture:eawTexture withName:[LTClarityFsh eawTexture]];
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
  processor.iterationsPerOutput = @[@8];
  [processor process];

  return output;
}

- (LTTexture *)createEAWTexture:(LTTexture *)input {
  LTTexture *output = [LTTexture textureWithSize:input.size precision:LTTexturePrecisionHalfFloat
                                          format:LTTextureFormatRed allocateMemory:YES];
  LTEAWProcessor *processor = [[LTEAWProcessor alloc] initWithInput:input output:output];
  processor.compressionFactor = LTVector4(0.8, 0, 0, 0);
  [processor process];

  return output;
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
