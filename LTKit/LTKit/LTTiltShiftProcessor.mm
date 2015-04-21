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

/// \c YES if dual mask needs processing prior to executing this processor.
@property (nonatomic) BOOL needsDualMaskProcessing;

/// Internal dual mask processor.
@property (strong, nonatomic) LTDualMaskProcessor *dualMaskProcessor;

/// The generation id of the input texture that was used to create the current smooth textures.
@property (nonatomic) id smoothTextureGenerationID;

@end

@implementation LTTiltShiftProcessor

// Since dual mask is smooth, strong downsampling will have very little impact on the quality, while
// significantly reducing the memory requirements.
static const CGFloat kMaskScalingFactor = 4.0;

- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output {
  LTTexture *mask = [LTTexture byteRedTextureWithSize:CGSizeMakeUniform(1)];
  [mask clearWithColor:LTVector4(1)];
  return [self initWithInput:input mask:mask output:output];
}

- (instancetype)initWithInput:(LTTexture *)input mask:(LTTexture *)mask output:(LTTexture *)output {
  // Setup dual mask.
  LTTexture *dualMaskTexture = [self createDualMaskTextureWithOutput:output];
  self.dualMaskProcessor = [[LTDualMaskProcessor alloc] initWithOutput:dualMaskTexture];
  if (self = [super initWithVertexSource:[LTPassthroughShaderVsh source]
                          fragmentSource:[LTTiltShiftFsh source] sourceTexture:input
                       auxiliaryTextures:@{[LTTiltShiftFsh dualMaskTexture]: dualMaskTexture,
                                           [LTTiltShiftFsh userMaskTexture]: mask}
                               andOutput:output]) {
    [self resetInputModel];
  }
  return self;
}

- (LTTexture *)createDualMaskTextureWithOutput:(LTTexture *)output {
  CGSize maskSize = CGSizeMake(MAX(1, std::round(output.size.width / kMaskScalingFactor)),
                               MAX(1, std::round(output.size.height / kMaskScalingFactor)));
  return [LTTexture byteRedTextureWithSize:maskSize];
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

- (void)updateSmoothTexturesIfNecessary {
  if (![self.smoothTextureGenerationID isEqual:self.inputTexture.generationID] ||
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
#pragma mark Input model
#pragma mark -

+ (NSSet *)inputModelPropertyKeys {
  static NSSet *properties;
  
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    properties = [NSSet setWithArray:@[
      @instanceKeypath(LTTiltShiftProcessor, maskType),
      @instanceKeypath(LTTiltShiftProcessor, center),
      @instanceKeypath(LTTiltShiftProcessor, diameter),
      @instanceKeypath(LTTiltShiftProcessor, spread),
      @instanceKeypath(LTTiltShiftProcessor, angle),
      @instanceKeypath(LTTiltShiftProcessor, invertMask),
      @instanceKeypath(LTTiltShiftProcessor, intensity)
    ]];
  });
  
  return properties;
}

+ (BOOL)isPassthroughForDefaultInputModel {
  return NO;
}

- (LTDualMaskType)defaultMaskType {
  return LTDualMaskTypeRadial;
}

- (LTVector2)defaultCenter {
  return LTVector2Zero;
}

- (CGFloat)defaultDiameter {
  return 0;
}

- (CGFloat)defaultAngle {
  return 0;
}

#pragma mark -
#pragma mark Processing
#pragma mark -

- (void)preprocess {
  [super preprocess];

  [self updateSmoothTexturesIfNecessary];

  if (self.needsDualMaskProcessing) {
    [self.dualMaskProcessor process];
    self.needsDualMaskProcessing = NO;
  }
}

- (void)setNeedsDualMaskUpdate {
  self.needsDualMaskProcessing = YES;
}

#pragma mark -
#pragma mark Dual Mask
#pragma mark -

- (void)setMaskType:(LTDualMaskType)maskType {
  self.dualMaskProcessor.maskType = maskType;
  [self setNeedsDualMaskUpdate];
}

- (LTDualMaskType)maskType {
  return self.dualMaskProcessor.maskType;
}

- (void)setCenter:(LTVector2)center {
  // Scaling transforms from image coordinate system to mask coordinate system.
  self.dualMaskProcessor.center = center / kMaskScalingFactor;
  [self setNeedsDualMaskUpdate];
}

- (LTVector2)center {
  // Scaling transforms from mask coordinate system to image coordinate system.
  return self.dualMaskProcessor.center * kMaskScalingFactor;
}

- (void)setDiameter:(CGFloat)diameter {
  // Scaling transforms from image coordinate system to mask coordinate system.
  self.dualMaskProcessor.diameter = diameter / kMaskScalingFactor;
  [self setNeedsDualMaskUpdate];
}

- (CGFloat)diameter {
  // Scaling transforms from mask coordinate system to image coordinate system.
  return self.dualMaskProcessor.diameter * kMaskScalingFactor;
}

LTPropertyWithoutSetter(CGFloat, spread, Spread, -1, 1, 0);
- (void)setSpread:(CGFloat)spread {
  [self _verifyAndSetSpread:spread];
  self.dualMaskProcessor.spread = spread;
  [self setNeedsDualMaskUpdate];
}

- (void)setAngle:(CGFloat)angle {
  self.dualMaskProcessor.angle = angle;
  [self setNeedsDualMaskUpdate];
}

- (CGFloat)angle {
  return self.dualMaskProcessor.angle;
}

#pragma mark -
#pragma mark Blur
#pragma mark -

LTPropertyWithoutSetter(CGFloat, intensity, Intensity, 0, 1, 1);
- (void)setIntensity:(CGFloat)intensity {
  [self _verifyAndSetIntensity:intensity];
  self[[LTTiltShiftFsh intensity]] = @(intensity);
}

- (void)setInvertMask:(BOOL)invertMask {
  _invertMask = invertMask;
  self.dualMaskProcessor.invert = invertMask;
  [self setNeedsDualMaskUpdate];
}

@end
