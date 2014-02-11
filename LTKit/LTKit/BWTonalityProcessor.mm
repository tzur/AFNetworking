// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "BWTonalityProcessor.h"

#import "LTBoxFilterProcessor.h"
#import "LTCGExtensions.h"
#import "LTColorGradient.h"
#import "LTGLKitExtensions.h"
#import "LTProgram.h"
#import "LTShaderStorage+BWTonalityFsh.h"
#import "LTShaderStorage+LTPassthroughShaderVsh.h"
#import "LTTexture+Factory.h"

@interface LTGPUImageProcessor ()
/// Dictionary of \c NSString to \c LTTexture of axiliary textures to use to assist processing.
/// @attention this property reveals auxiliaryTextures property of LTGPUImageProcessor.
@property (strong, nonatomic) NSDictionary *auxiliaryTextures;

@end

@implementation BWTonalityProcessor

static const CGFloat kSmoothDownsampleFactor = 6.0;

static const CGFloat kBrightnessMin = -1.0;
static const CGFloat kBrightnessMax = 1.0;
static const CGFloat kBrightnessDefault = 0.0;

static const CGFloat kContrastMin = 0.0;
static const CGFloat kContrastMax = 2.0;
static const CGFloat kContrastDefault = 1.0;

static const CGFloat kExposureMin = 0.0;
static const CGFloat kExposureMax = 2.0;
static const CGFloat kExposureDefault = 1.0;

static const CGFloat kStructureMin = 0.0;
static const CGFloat kStructureMax = 4.0;
static const CGFloat kStructureDefault = 1.0;

static const GLKVector3 kColorFilterDefault = GLKVector3Make(0.299, 0.587, 0.114);

- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output {
  LTProgram *program = [[LTProgram alloc] initWithVertexSource:[LTPassthroughShaderVsh source]
                                                fragmentSource:[BWTonalityFsh source]];
  // Prepare smoothed version of the image.
  LTTexture *smoothTexture = [self prepareSmoothTexture:input];
  
  LTBoxFilterProcessor *smoother =
      [[LTBoxFilterProcessor alloc] initWithInput:input outputs:@[smoothTexture]];
  smoother.iterationsPerOutput = @[@3];
  [smoother process];
  
  // Default color gradient.
  LTColorGradient *identityGradient = [LTColorGradient identityGradient];
  
  NSDictionary *auxiliaryTextures =
      @{[BWTonalityFsh smoothTexture] : smoothTexture,
        [BWTonalityFsh colorGradient] : [identityGradient textureWithSamplingPoints:256]};
  if (self = [super initWithProgram:program sourceTexture:input auxiliaryTextures:auxiliaryTextures
                          andOutput:output]) {
    self.colorFilter = kColorFilterDefault;
    self.brightness = kBrightnessDefault;
    self.contrast = kContrastDefault;
    self.exposure = kExposureDefault;
    self.structure = kStructureDefault;
    self.colorGradient = identityGradient;
  }
  return self;
}

- (LTTexture *)prepareSmoothTexture:(LTTexture *)input {
  CGFloat width = std::max(1.0f, input.size.width / kSmoothDownsampleFactor);
  CGFloat height = std::max(1.0f, input.size.height / kSmoothDownsampleFactor);
  
  return [LTTexture byteRGBATextureWithSize:CGSizeMake(width, height)];
}

- (void)setColorFilter:(GLKVector3)colorFilter {
  LTParameterAssert(GLKVectorInRange(colorFilter, 0.0, 1.0), @"Color filter is out of range.");
  LTParameterAssert(GLKVector3Length(colorFilter), @"Black is not a valid color filter");
  
  _colorFilter = colorFilter / std::sum(colorFilter);
  self[@"colorFilter"] = $(_colorFilter);
}

- (void)setBrightness:(CGFloat)brightness {
  LTParameterAssert(brightness >= kBrightnessMin, @"Brightness is lower than minimum value");
  LTParameterAssert(brightness <= kBrightnessMax, @"Brightness is higher than maximum value");
  
  _brightness = brightness;
  self[@"brightness"] = @(brightness);
}

- (void)setContrast:(CGFloat)contrast {
  LTParameterAssert(contrast >= kContrastMin, @"Contrast is lower than minimum value");
  LTParameterAssert(contrast <= kContrastMax, @"Contrast is higher than maximum value");
  
  _contrast = contrast;
  self[@"contrast"] = @(contrast);
}

- (void)setExposure:(CGFloat)exposure {
  LTParameterAssert(exposure >= kExposureMin, @"Exposure is lower than minimum value");
  LTParameterAssert(exposure <= kExposureMax, @"Exposure is higher than maximum value");
  
  _exposure = exposure;
  self[@"exposure"] = @(exposure);
}

- (void)setStructure:(CGFloat)structure {
  LTParameterAssert(structure >= kStructureMin, @"Structure is lower than minimum value");
  LTParameterAssert(structure <= kStructureMax, @"Structure is higher than maximum value");
  
  _structure = structure;
  self[@"structure"] = @(structure);
}

- (void)setColorGradient:(LTColorGradient *)colorGradient {
  _colorGradient = colorGradient;
  // Update color gradient texture in auxiliary textures.
  NSMutableDictionary *auxiliaryTextures = [self.auxiliaryTextures mutableCopy];
  auxiliaryTextures[[BWTonalityFsh colorGradient]] = [colorGradient textureWithSamplingPoints:256];
  self.auxiliaryTextures = auxiliaryTextures;
}

@end
