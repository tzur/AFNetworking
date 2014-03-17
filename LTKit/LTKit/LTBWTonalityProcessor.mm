// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTBWTonalityProcessor.h"

#import "LTBoxFilterProcessor.h"
#import "LTCGExtensions.h"
#import "LTColorGradient.h"
#import "LTGLKitExtensions.h"
#import "LTProgram.h"
#import "LTShaderStorage+LTBWTonalityFsh.h"
#import "LTShaderStorage+LTPassthroughShaderVsh.h"
#import "LTTexture+Factory.h"

@interface LTGPUImageProcessor ()
@property (strong, nonatomic) NSDictionary *auxiliaryTextures;
@end

@implementation LTBWTonalityProcessor

static const CGFloat kSmoothDownsampleFactor = 6.0;

static const GLKVector3 kColorFilterDefault = GLKVector3Make(0.299, 0.587, 0.114);

- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output {
  LTProgram *program = [[LTProgram alloc] initWithVertexSource:[LTPassthroughShaderVsh source]
                                                fragmentSource:[LTBWTonalityFsh source]];
  LTTexture *smoothTexture = [self createSmoothTexture:input];
  // Default color gradient.
  LTColorGradient *identityGradient = [LTColorGradient identityGradient];
  
  NSDictionary *auxiliaryTextures =
      @{[LTBWTonalityFsh smoothTexture]: smoothTexture,
        [LTBWTonalityFsh colorGradient]: [identityGradient textureWithSamplingPoints:256]};
  if (self = [super initWithProgram:program sourceTexture:input auxiliaryTextures:auxiliaryTextures
                          andOutput:output]) {
    [self setDefaultValues];
  }
  return self;
}

- (void)setDefaultValues {
  self.colorFilter = kColorFilterDefault;
  self.brightness = kDefaultBrightness;
  self.contrast = kDefaultContrast;
  self.exposure = kDefaultExposure;
  self.structure = kDefaultStructure;
  _colorGradientTexture = self.auxiliaryTextures[[LTBWTonalityFsh colorGradient]];
}

- (LTTexture *)createSmoothTexture:(LTTexture *)input {
  CGFloat width = MAX(1.0, input.size.width / kSmoothDownsampleFactor);
  CGFloat height = MAX(1.0, input.size.height / kSmoothDownsampleFactor);

  CGSize size = std::floor(CGSizeMake(width, height));
  LTTexture *smoothTexture = [LTTexture byteRGBATextureWithSize:size];
  
  LTBoxFilterProcessor *smoother = [[LTBoxFilterProcessor alloc] initWithInput:input
                                                                       outputs:@[smoothTexture]];
  smoother.iterationsPerOutput = @[@3];
  [smoother process];
  
  return smoothTexture;
}

- (void)setColorFilter:(GLKVector3)colorFilter {
  LTParameterAssert(GLKVectorInRange(colorFilter, 0.0, 1.0), @"Color filter is out of range.");
  LTParameterAssert(GLKVector3Length(colorFilter), @"Black is not a valid color filter");
  
  _colorFilter = colorFilter / std::sum(colorFilter);
  self[@"colorFilter"] = $(_colorFilter);
}

LTBoundedPrimitivePropertyImplementWithCustomSetter(CGFloat, brightness, Brightness, -1, 1, 0, ^{
  _brightness = brightness;
  self[@"brightness"] = @(_brightness);
});

LTBoundedPrimitivePropertyImplementWithCustomSetter(CGFloat, contrast, Contrast, -1, 1, 0, ^{
  _contrast = contrast;
  // Remap [-1, 0] -> [0, 1] and [0, 1] to [1, 2].
  CGFloat remap = contrast < 0 ? contrast + 1 : 1 + contrast;
  self[@"contrast"] = @(remap);
});

LTBoundedPrimitivePropertyImplementWithCustomSetter(CGFloat, exposure, Exposure, -1, 1, 0, ^{
  _exposure = exposure;
  // Remap [-1, 1] -> [0.5, 2].
  CGFloat remap = std::powf(2.0, exposure);
  self[@"exposure"] = @(remap);
});

LTBoundedPrimitivePropertyImplementWithCustomSetter(CGFloat, structure, Structure, -1, 1, 0, ^{
  _structure = structure;
  // Remap [-1, 1] -> [0.25, 4].
  CGFloat remap = std::powf(4.0, structure);
  self[@"structure"] = @(remap);
});

- (void)setColorGradientTexture:(LTTexture *)colorGradientTexture {
  LTParameterAssert(colorGradientTexture.size.height == 1,
                    @"colorGradientTexture height is not one");
  LTParameterAssert(colorGradientTexture.size.width <= 256,
                    @"colorGradientTexture width is larger than 256");
  
  _colorGradientTexture = colorGradientTexture;
  NSMutableDictionary *auxiliaryTextures = [self.auxiliaryTextures mutableCopy];
  auxiliaryTextures[[LTBWTonalityFsh colorGradient]] = colorGradientTexture;
  self.auxiliaryTextures = auxiliaryTextures;
}

@end
