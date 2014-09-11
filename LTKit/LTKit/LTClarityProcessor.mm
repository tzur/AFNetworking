// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTClarityProcessor.h"

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

/// The generation id of the input texture that was used to create the current smooth texture.
@property (nonatomic) NSUInteger smoothTextureGenerationID;

@end

@implementation LTClarityProcessor

- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output {
  if (self = [super initWithVertexSource:[LTPassthroughShaderVsh source]
                          fragmentSource:[LTClarityFsh source] input:input andOutput:output]) {
    [self setDefaultValues];
  }
  return self;
}

- (LTTexture *)createSmoothTexture:(LTTexture *)input {
  LTTexture *output = [LTTexture textureWithSize:input.size precision:LTTexturePrecisionHalfFloat
                                          format:LTTextureFormatRG allocateMemory:YES];
  LTEAWProcessor *processor = [[LTEAWProcessor alloc] initWithInput:input output:output];
  processor.compressionFactor = LTVector4(0.8, 0.95, 0, 0);
  [processor process];
  
  return output;
}

- (void)setDefaultValues {
  self.gain = self.defaultGain;
  self.saturation = self.defaultSaturation;
}

- (void)updateSmoothTextureIfNecessary {
  if (self.smoothTextureGenerationID != self.inputTexture.generationID ||
      !self.auxiliaryTextures[[LTClarityFsh smoothTexture]]) {
    self.smoothTextureGenerationID = self.inputTexture.generationID;
    [self setAuxiliaryTexture:[self createSmoothTexture:self.inputTexture]
                     withName:[LTClarityFsh smoothTexture]];
  }
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

static const CGFloat kPunchExponent = 1.5;

LTPropertyWithoutSetter(CGFloat, punch, Punch, 0, 1, 0);
- (void)setPunch:(CGFloat)punch {
  [self _verifyAndSetPunch:punch];
  CGFloat remap = std::pow(punch, kPunchExponent);
  self[[LTClarityFsh punch]] = @(remap);
  self[[LTClarityFsh punchBlend]] = @([LTClarityProcessor smoothstepWithEdge0:0 edge1:1
                                                                        value:remap]);
  [self updateSaturation];
}

static const CGFloat kFlattenSigmaScaling = 0.9;

LTPropertyWithoutSetter(CGFloat, flatten, Flatten, 0, 1, 0);
- (void)setFlatten:(CGFloat)flatten {
  [self _verifyAndSetFlatten:flatten];
  CGFloat flattenA = 1.0 - flatten * kFlattenSigmaScaling;
  CGFloat flattenBlend = [LTClarityProcessor smoothstepWithEdge0:0 edge1:0.1 value:flatten];
  self[[LTClarityFsh flattenA]] = @(flattenA);
  self[[LTClarityFsh flattenBlend]] = @(flattenBlend);
  [self updateSaturation];
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

static const CGFloat kSaturationScaling = 1.0;
static const CGFloat kSaturationPunchScaling = 0.5;
static const CGFloat kSaturationFlattenScaling = 0.25;

LTPropertyWithoutSetter(CGFloat, saturation, Saturation, -1, 1, 0);
- (void)setSaturation:(CGFloat)saturation {
  [self _verifyAndSetSaturation:saturation];
  [self updateSaturation];
}

- (void)updateSaturation {
  // Remap [-1, 1] -> [0, 2.5].
  CGFloat remap = 1 + self.saturation * kSaturationScaling + self.punch * kSaturationPunchScaling -
      self.flatten * kSaturationFlattenScaling;
  remap = MAX(0, remap);
  self[[LTClarityFsh saturation]] = @(remap);
}

@end
