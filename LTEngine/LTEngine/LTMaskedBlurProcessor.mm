// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Michael Kupchick.

#import "LTMaskedBlurProcessor.h"

#import "LTGPUImageProcessor+Protected.h"
#import "LTShaderStorage+LTPassthroughShaderVsh.h"
#import "LTShaderStorage+LTTiltShiftFsh.h"
#import "LTSmoothPyramidProcessor.h"
#import "LTTexture+Factory.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTMaskedBlurProcessor()

/// The generation id of the input texture that was used to create the current smooth textures.
@property (strong, nonatomic) NSString *smoothTextureGenerationID;

@end

@implementation LTMaskedBlurProcessor

- (instancetype)initWithInput:(LTTexture *)input blurMask:(nullable LTTexture *)blurMask
                       output:(LTTexture *)output {
  LTTexture *mask = [LTTexture byteRedTextureWithSize:CGSizeMakeUniform(1)];
  [mask clearColor:LTVector4::ones()];

  return [self initWithInput:input mask:mask blurMask:blurMask output:output];
}

- (instancetype)initWithInput:(LTTexture *)input mask:(LTTexture *)userMask
                     blurMask:(nullable LTTexture *)blurMask output:(LTTexture *)output {
  if (self = [super initWithVertexSource:[LTPassthroughShaderVsh source]
                          fragmentSource:[LTTiltShiftFsh source] input:input
                               andOutput:output]) {
    [self setAuxiliaryTexture:blurMask ?: [self emptyBlurMask]
                     withName:[LTTiltShiftFsh dualMaskTexture]];
    [self setAuxiliaryTexture:userMask withName:[LTTiltShiftFsh userMaskTexture]];

    [self resetInputModel];
  }
  return self;
}

- (LTTexture *)emptyBlurMask {
  LTTexture *texture = [LTTexture byteRedTextureWithSize:CGSizeMakeUniform(1)];
  [texture clearColor:LTVector4::ones()];
  return texture;
}

+ (NSSet *)inputModelPropertyKeys {
  static NSSet *properties;

  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    properties = [NSSet setWithArray:@[
      @instanceKeypath(LTMaskedBlurProcessor, intensity)
    ]];
  });

  return properties;
}

- (NSArray<LTTexture *> *)createSmoothTextures:(LTTexture *)input {
  NSArray<LTTexture *> *pyramidLevels = [LTPyramidProcessor levelsForInput:input];

  // Pyramid processor bilinearly downsamples the signal.
  LTPyramidProcessor *pyramidProcessor =
      [[LTPyramidProcessor alloc] initWithInput:input outputs:pyramidLevels];
  [pyramidProcessor process];

  // Second to fifth levels upsampled back with smooth pyramid processor to half of the input image
  // resolution.
  static const NSUInteger kNumberOfLevels = 4;
  NSMutableArray<LTTexture *> *textures = [NSMutableArray arrayWithCapacity:kNumberOfLevels];
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
  NSArray<LTTexture *> *upOutputs = [self outputsForTextures:outputs index:index];
  LTSmoothPyramidProcessor *pyramidProcessor =
      [[LTSmoothPyramidProcessor alloc] initWithInput:outputs[index] outputs:upOutputs];
  [pyramidProcessor process];

  return [upOutputs lastObject];
}

- (NSArray<LTTexture *> *)outputsForTextures:(NSArray *)textures index:(NSUInteger)index {
  NSMutableArray<LTTexture *> *levels = [NSMutableArray array];

  for (NSUInteger i = 0; i < index; ++i) {
    LTTexture *texture = [LTTexture textureWithPropertiesOf:textures[i]];
    [levels insertObject:texture atIndex:0];
  }
  return levels;
}

- (void)preprocess {
  [super preprocess];
  [self updateSmoothTexturesIfNecessary];
}

- (void)updateSmoothTexturesIfNecessary {
  if ([self.smoothTextureGenerationID isEqual:self.inputTexture.generationID] &&
      self.auxiliaryTextures[[LTTiltShiftFsh fineTexture]] &&
      self.auxiliaryTextures[[LTTiltShiftFsh mediumTexture]] &&
      self.auxiliaryTextures[[LTTiltShiftFsh coarseTexture]] &&
      self.auxiliaryTextures[[LTTiltShiftFsh veryCoarseTexture]]) {
    return;
  }

  self.smoothTextureGenerationID = self.inputTexture.generationID;

  NSArray<LTTexture *> *smoothTextures = [self createSmoothTextures:self.inputTexture];
  [self setAuxiliaryTexture:smoothTextures[0] withName:[LTTiltShiftFsh fineTexture]];
  [self setAuxiliaryTexture:smoothTextures[1] withName:[LTTiltShiftFsh mediumTexture]];
  [self setAuxiliaryTexture:smoothTextures[2] withName:[LTTiltShiftFsh coarseTexture]];
  [self setAuxiliaryTexture:smoothTextures[3] withName:[LTTiltShiftFsh veryCoarseTexture]];
}

LTPropertyWithoutSetter(CGFloat, intensity, Intensity, 0, 1, 1);
- (void)setIntensity:(CGFloat)intensity {
  [self _verifyAndSetIntensity:intensity];
  self[[LTTiltShiftFsh intensity]] = @(intensity);
}

@end

NS_ASSUME_NONNULL_END
