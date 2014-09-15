// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTTiltShiftProcessor.h"

#import "LTBicubicResizeProcessor.h"
#import "LTCGExtensions.h"
#import "LTDualMaskProcessor.h"
#import "LTGPUImageProcessor+Protected.h"
#import "LTGLKitExtensions.h"
#import "LTProgram.h"
#import "LTShaderStorage+LTTiltShiftFsh.h"
#import "LTShaderStorage+LTPassthroughShaderVsh.h"
#import "LTSmoothPyramidProcessor.h"
#import "LTTexture+Factory.h"

@interface LTGPUImageProcessor ()
@property (strong, nonatomic) NSDictionary *auxiliaryTextures;
@end

@interface LTTiltShiftProcessor ()

@property (nonatomic) BOOL subProcessorInitialized;

@property (strong, nonatomic) LTDualMaskProcessor *dualMaskProcessor;

/// The generation id of the input texture that was used to create the current smooth textures.
@property (nonatomic) NSUInteger smoothTextureGenerationID;

@end

@implementation LTTiltShiftProcessor

// Since dual mask is smooth, strong downsampling will have very little impact on the quality, while
// significantly reducing the memory requirements.
static const CGFloat kMaskScalingFactor = 4.0;

- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output {
  // Setup dual mask.
  LTTexture *dualMaskTexture = [self createDualMaskTextureWithOutput:output];
  self.dualMaskProcessor = [[LTDualMaskProcessor alloc] initWithOutput:dualMaskTexture];
  if (self = [super initWithVertexSource:[LTPassthroughShaderVsh source]
                          fragmentSource:[LTTiltShiftFsh source] sourceTexture:input
                       auxiliaryTextures:@{[LTTiltShiftFsh dualMaskTexture]: dualMaskTexture}
                               andOutput:output]) {
    [self setDefaultValues];
  }
  return self;
}

- (LTTexture *)createDualMaskTextureWithOutput:(LTTexture *)output {
  CGSize maskSize = CGSizeMake(MAX(1, std::round(output.size.width / kMaskScalingFactor)),
                               MAX(1, std::round(output.size.height / kMaskScalingFactor)));
  return [LTTexture byteRedTextureWithSize:maskSize];
}

- (void)setDefaultValues {
  self.intensity = self.defaultIntensity;
}

- (NSArray *)createSmoothTextures:(LTTexture *)input {
  NSArray *pyramidLevels = [LTPyramidProcessor levelsForInput:input];
  
  // Pyramid processor bilinearly downsamples the signal.
  LTPyramidProcessor *pyramidProcessor =
      [[LTPyramidProcessor alloc] initWithInput:input outputs:pyramidLevels];
  [pyramidProcessor process];
  
  // Second to fifth levels upsampled back with smooth pyramid processor to half of the input image
  // resolution.
  static const NSUInteger kNumberOfLevels = 4;
  NSMutableArray *textures = [NSMutableArray arrayWithCapacity:kNumberOfLevels];
  for (NSUInteger i = 0; i < kNumberOfLevels; ++i) {
    @autoreleasepool {
      NSUInteger index = std::min(i + 1, pyramidLevels.count - 1);
      if (index) {
        [textures addObject:[self upsampleWithOutputs:pyramidLevels atIndex:index]];
      } else {
        // Highest level of the outputs (largest image) doesn't require upsampling.
        [textures addObject:pyramidLevels[0]];
      }
    }
  }
  return textures;
}

- (LTTexture *)upsampleWithOutputs:(NSArray *)outputs atIndex:(NSUInteger)index {
  NSArray *upOutputs = [self outputsForTextures:outputs index:index];
  LTSmoothPyramidProcessor *pyramidProcessor =
      [[LTSmoothPyramidProcessor alloc] initWithInput:outputs[index] outputs:upOutputs];
  [pyramidProcessor process];
  
  return [upOutputs lastObject];
}

- (NSArray *)outputsForTextures:(NSArray *)textures index:(NSUInteger)index {
  NSMutableArray *levels = [NSMutableArray array];
  
  for (NSUInteger i = 0; i < index; ++i) {
    LTTexture *texture = [LTTexture textureWithPropertiesOf:textures[i]];
    [levels insertObject:texture atIndex:0];
  }
  return levels;
}

#pragma mark -
#pragma mark LTImageProcessor
#pragma mark -

- (void)initializeSubProcessor {
  [self.dualMaskProcessor process];
  self.subProcessorInitialized = YES;
}

- (void)process {
  if (!self.subProcessorInitialized) {
    [self initializeSubProcessor];
  }
  return [super process];
}

- (void)preprocess {
  [self updateSmoothTexturesIfNecessary];
}

- (void)updateSmoothTexturesIfNecessary {
  if (self.smoothTextureGenerationID != self.inputTexture.generationID ||
      !self.auxiliaryTextures[[LTTiltShiftFsh fineTexture]] ||
      !self.auxiliaryTextures[[LTTiltShiftFsh mediumTexture]] ||
      !self.auxiliaryTextures[[LTTiltShiftFsh coarseTexture]] ||
      !self.auxiliaryTextures[[LTTiltShiftFsh veryCoarseTexture]]) {
    self.smoothTextureGenerationID = self.inputTexture.generationID;
    
    NSArray *smoothTextures = [self createSmoothTextures:self.inputTexture];
    [self setAuxiliaryTexture:smoothTextures[0] withName:[LTTiltShiftFsh fineTexture]];
    [self setAuxiliaryTexture:smoothTextures[1] withName:[LTTiltShiftFsh mediumTexture]];
    [self setAuxiliaryTexture:smoothTextures[2] withName:[LTTiltShiftFsh coarseTexture]];
    [self setAuxiliaryTexture:smoothTextures[3] withName:[LTTiltShiftFsh veryCoarseTexture]];
  }
}

#pragma mark -
#pragma mark Dual Mask
#pragma mark -

- (void)setMaskType:(LTDualMaskType)maskType {
  self.dualMaskProcessor.maskType = maskType;
  [self.dualMaskProcessor process];
}

- (LTDualMaskType)maskType {
  return self.dualMaskProcessor.maskType;
}

- (void)setCenter:(LTVector2)center {
  // Scaling transforms from image coordinate system to mask coordinate system.
  self.dualMaskProcessor.center = center / kMaskScalingFactor;
  [self.dualMaskProcessor process];
}

- (LTVector2)center {
  // Scaling transforms from mask coordinate system to image coordinate system.
  return self.dualMaskProcessor.center * kMaskScalingFactor;
}

- (void)setDiameter:(CGFloat)diameter {
  // Scaling transforms from image coordinate system to mask coordinate system.
  self.dualMaskProcessor.diameter = diameter / kMaskScalingFactor;
  [self.dualMaskProcessor process];
}

- (CGFloat)diameter {
  // Scaling transforms from mask coordinate system to image coordinate system.
  return self.dualMaskProcessor.diameter * kMaskScalingFactor;
}

LTPropertyWithoutSetter(CGFloat, spread, Spread, -1, 1, 0);
- (void)setSpread:(CGFloat)spread {
  [self _verifyAndSetSpread:spread];
  self.dualMaskProcessor.spread = spread;
  [self.dualMaskProcessor process];
}

- (void)setAngle:(CGFloat)angle {
  self.dualMaskProcessor.angle = angle;
  [self.dualMaskProcessor process];
}

- (CGFloat)angle {
  return self.dualMaskProcessor.angle;
}

#pragma mark -
#pragma mark Blue
#pragma mark -

LTPropertyWithoutSetter(CGFloat, intensity, Intensity, 0, 1, 1);
- (void)setIntensity:(CGFloat)intensity {
  [self _verifyAndSetIntensity:intensity];
  self[[LTTiltShiftFsh intensity]] = @(intensity);
}

@end
