// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTTiltShiftProcessor.h"

#import "LTBoxFilterProcessor.h"
#import "LTDualMaskProcessor.h"
#import "LTProgram.h"
#import "LTShaderStorage+LTTiltShiftFsh.h"
#import "LTShaderStorage+LTPassthroughShaderVsh.h"
#import "LTTexture+Factory.h"

@interface LTGPUImageProcessor ()
@property (strong, nonatomic) NSDictionary *auxiliaryTextures;
@end

@interface LTTiltShiftProcessor ()

@property (nonatomic) BOOL subProcessorInitialized;
@property (strong, nonatomic) LTDualMaskProcessor *dualMaskProcessor;

@end

@implementation LTTiltShiftProcessor

- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output {
  // Setup dual mask.
  LTTexture *dualMaskTexture = [LTTexture textureWithPropertiesOf:output];
  self.dualMaskProcessor = [[LTDualMaskProcessor alloc] initWithOutput:dualMaskTexture];
  // Setup smoothing.
  NSArray *smoothTextures = [self createSmoothTextures:input];
  NSDictionary *auxiliaryTextures =
      @{[LTTiltShiftFsh fineTexture]: smoothTextures[0],
        [LTTiltShiftFsh coarseTexture]: smoothTextures[1],
        [LTTiltShiftFsh dualMaskTexture]: dualMaskTexture};
  if (self = [super initWithProgram:[self createProgram] sourceTexture:input
                  auxiliaryTextures:auxiliaryTextures andOutput:output]) {
    [self setDefaultValues];
  }
  return self;
}

- (LTProgram *)createProgram {
  return [[LTProgram alloc] initWithVertexSource:[LTPassthroughShaderVsh source]
                                  fragmentSource:[LTTiltShiftFsh source]];
}

- (void)initializeSubProcessor {
  [self.dualMaskProcessor process];
  self.subProcessorInitialized = YES;
}

- (id<LTImageProcessorOutput>)process {
  if (!self.subProcessorInitialized) {
    [self initializeSubProcessor];
  }
  return [super process];
}

- (void)setDefaultValues {
  self.intensity = self.defaultIntensity;
}

// Downsampling wrt original image that is used when creating a smooth texture.
static const CGFloat kSmoothDownsampleFactor = 2.0;
static const NSUInteger kFineTextureIterations = 2;
static const NSUInteger kCoarseTextureIterations = 6;

- (NSArray *)createSmoothTextures:(LTTexture *)input {
  CGFloat width = MAX(1.0, std::round(input.size.width / kSmoothDownsampleFactor));
  CGFloat height = MAX(1.0, std::round(input.size.height / kSmoothDownsampleFactor));
  
  LTTexture *fine = [LTTexture byteRGBATextureWithSize:CGSizeMake(width, height)];
  LTTexture *coarse = [LTTexture byteRGBATextureWithSize:CGSizeMake(width, height)];
  
  LTBoxFilterProcessor *smoother =
      [[LTBoxFilterProcessor alloc] initWithInput:input outputs:@[fine, coarse]];
  
  smoother.iterationsPerOutput = @[@(kFineTextureIterations), @(kCoarseTextureIterations)];
  [smoother process];
  
  return @[fine, coarse];
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

- (void)setCenter:(GLKVector2)center {
  self.dualMaskProcessor.center = center;
  [self.dualMaskProcessor process];
}

- (GLKVector2)center {
  return self.dualMaskProcessor.center;
}

- (void)setDiameter:(CGFloat)diameter {
  self.dualMaskProcessor.diameter = diameter;
  [self.dualMaskProcessor process];
}

- (CGFloat)diameter {
  return self.dualMaskProcessor.diameter;
}

- (void)setSpread:(CGFloat)spread {
  self.dualMaskProcessor.spread = spread;
  [self.dualMaskProcessor process];
}

- (CGFloat)spread {
  return self.dualMaskProcessor.spread;
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

LTBoundedPrimitivePropertyImplementWithCustomSetter(CGFloat, intensity, Intensity, 0, 1, 1, ^{
  self[[LTTiltShiftFsh intensity]] = @(intensity);
});

@end
