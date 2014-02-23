// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTAdjustProcessor.h"

#import "LTBilateralFilterProcessor.h"
#import "LTBoxFilterProcessor.h"
#import "LTGLKitExtensions.h"
#import "LTProgram.h"
#import "LTShaderStorage+LTAdjustFsh.h"
#import "LTShaderStorage+LTPassthroughShaderVsh.h"
#import "LTTexture+Factory.h"

@interface LTGPUImageProcessor ()
@property (strong, nonatomic) NSDictionary *auxiliaryTextures;
@end

@implementation LTAdjustProcessor

static const CGFloat kSmoothDownsampleFactor = 6.0;

static const CGFloat kMinBrightness = -1.0;
static const CGFloat kMaxBrightness = 1.0;
static const CGFloat kDefaultBrightness = 0.0;

static const CGFloat kMinContrast = 0.0;
static const CGFloat kMaxContrast = 2.0;
static const CGFloat kDefaultContrast = 1.0;

static const CGFloat kMinExposure = 0.0;
static const CGFloat kMaxExposure = 3.0;
static const CGFloat kDefaultExposure = 1.0;

static const CGFloat kMinOffset = -1.0;
static const CGFloat kMaxOffset = 1.0;
static const CGFloat kDefaultOffset = 0.0;

static const GLKVector3 kDefaultBlackPoint = GLKVector3Make(0.0, 0.0, 0.0);
static const GLKVector3 kDefaultWhitePoint = GLKVector3Make(1.0, 1.0, 1.0);

static const CGFloat kMinSaturation = 0.0;
static const CGFloat kMaxSaturation = 3.0;
static const CGFloat kDefaultSaturation = 1.0;

static const CGFloat kMinTemperature = -1.0;
static const CGFloat kMaxTemperature = 1.0;
static const CGFloat kDefaultTemperature = 0.0;

static const CGFloat kMinTint = -1.0;
static const CGFloat kMaxTint = 1.0;
static const CGFloat kDefaultTint = 0.0;

static const CGFloat kMinDetails = 0.0;
static const CGFloat kMaxDetails = 2.0;
static const CGFloat kDefaultDetails = 1.0;

static const CGFloat kMinShadows = 0.0;
static const CGFloat kMaxShadows = 1.0;
static const CGFloat kDefaultShadows = 0.0;

static const CGFloat kMinFillLight = 0.0;
static const CGFloat kMaxFillLight = 1.0;
static const CGFloat kDefaultFillLight = 0.0;

static const CGFloat kMinHighlights = 0.0;
static const CGFloat kMaxHighlights = 1.0;
static const CGFloat kDefaultHighlights = 0.0;

- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output {
  LTProgram *program = [[LTProgram alloc] initWithVertexSource:[LTPassthroughShaderVsh source]
                                                fragmentSource:[LTAdjustFsh source]];
  // TODO:(zeev) Since smooth textures are used for luminance only, it make sense to build a
  // smoother that can leverage that by intermediate results into different RGBA channels. This will
  // reduce the sampling overhead in shaders, YIQ c
  NSArray *smoothTextures = [self createSmoothTexture:input];
  NSDictionary *auxiliaryTextures =
      @{[LTAdjustFsh fineTexture] : smoothTextures[0],
        [LTAdjustFsh coarseTexture] : smoothTextures[1]};
  if (self = [super initWithProgram:program sourceTexture:input auxiliaryTextures:auxiliaryTextures
                          andOutput:output]) {
    self.brightness = kDefaultBrightness;
    self.contrast = kDefaultContrast;
    self.exposure = kDefaultExposure;
    self.offset = kDefaultOffset;
    self.blackPoint = kDefaultBlackPoint;
    self.whitePoint = kDefaultWhitePoint;
    self.saturation = kDefaultSaturation;
    self.temperature = kDefaultTemperature;
    self.tint = kDefaultTint;
    self.details = kDefaultDetails;
    self.shadows = kDefaultShadows;
    self.fillLight = kDefaultFillLight;
    self.highlights = kDefaultHighlights;
  }
  return self;
}

- (NSArray *)createSmoothTexture:(LTTexture *)input {
  CGFloat width = MAX(1.0, input.size.width / kSmoothDownsampleFactor);
  CGFloat height = MAX(1.0, input.size.height / kSmoothDownsampleFactor);
  
  LTTexture *fine = [LTTexture byteRGBATextureWithSize:CGSizeMake(width, height)];
  LTTexture *coarse = [LTTexture byteRGBATextureWithSize:CGSizeMake(width, height)];
  
  LTBoxFilterProcessor *smoother = [[LTBoxFilterProcessor alloc] initWithInput:input
                                                                       outputs:@[fine, coarse]];
  smoother.iterationsPerOutput = @[@2, @4];
  [smoother process];
  
  return @[fine, coarse];;
}

- (void)setBrightness:(CGFloat)brightness {
  LTParameterAssert(brightness >= kMinBrightness, @"Brightness is lower than minimum value");
  LTParameterAssert(brightness <= kMaxBrightness, @"Brightness is higher than maximum value");
  
  _brightness = brightness;
  self[@"brightness"] = @(brightness);
}

- (void)setContrast:(CGFloat)contrast {
  LTParameterAssert(contrast >= kMinContrast, @"Contrast is lower than minimum value");
  LTParameterAssert(contrast <= kMaxContrast, @"Contrast is higher than maximum value");
  
  _contrast = contrast;
  self[@"contrast"] = @(contrast);
}

- (void)setExposure:(CGFloat)exposure {
  LTParameterAssert(exposure >= kMinExposure, @"Exposure is lower than minimum value");
  LTParameterAssert(exposure <= kMaxExposure, @"Exposure is higher than maximum value");
  
  _exposure = exposure;
  self[@"exposure"] = @(exposure);
}

- (void)setOffset:(CGFloat)offset {
  LTParameterAssert(offset >= kMinOffset, @"Offset is lower than minimum value");
  LTParameterAssert(offset <= kMaxOffset, @"Offset is higher than maximum value");
  
  _offset = offset;
  self[@"offset"] = @(offset);
}

- (void)setBlackPoint:(GLKVector3)blackPoint {
  LTParameterAssert(GLKVectorInRange(blackPoint, -1.0, 1.0), @"Color filter is out of range.");
  
  _blackPoint = blackPoint;
  self[@"blackPoint"] = $(blackPoint);
}

- (void)setWhitePoint:(GLKVector3)whitePoint {
  LTParameterAssert(GLKVectorInRange(whitePoint, 0.0, 2.0), @"Color filter is out of range.");
  
  _whitePoint = whitePoint;
  self[@"whitePoint"] = $(whitePoint);
}

- (void)setSaturation:(CGFloat)saturation {
  LTParameterAssert(saturation >= kMinSaturation, @"Saturation is lower than minimum value");
  LTParameterAssert(saturation <= kMaxSaturation, @"Saturation is higher than maximum value");
  
  _saturation = saturation;
  self[@"saturation"] = @(saturation);
}

- (void)setTemperature:(CGFloat)temperature {
  LTParameterAssert(temperature >= kMinTemperature, @"Temperature is lower than minimum value");
  LTParameterAssert(temperature <= kMaxTemperature, @"Temperature is higher than maximum value");
  
  _temperature = temperature;
  self[@"temperature"] = @(temperature);
}

- (void)setTint:(CGFloat)tint {
  LTParameterAssert(tint >= kMinTint, @"Tint is lower than minimum value");
  LTParameterAssert(tint <= kMaxTint, @"Tint is higher than maximum value");
  
  _tint = tint;
  self[@"tint"] = @(tint);
}

- (void)setDetails:(CGFloat)details {
  LTParameterAssert(details >= kMinDetails, @"Details is lower than minimum value");
  LTParameterAssert(details <= kMaxDetails, @"Details is higher than maximum value");
  
  _details = details;
  self[@"details"] = @(details);
}

- (void)setShadows:(CGFloat)shadows {
  LTParameterAssert(shadows >= kMinShadows, @"Shadows is lower than minimum value");
  LTParameterAssert(shadows <= kMaxShadows, @"Shadows is higher than maximum value");
  
  _shadows = shadows;
  self[@"shadows"] = @(shadows);
}

- (void)setFillLight:(CGFloat)fillLight {
  LTParameterAssert(fillLight >= kMinFillLight, @"FillLight is lower than minimum value");
  LTParameterAssert(fillLight <= kMaxFillLight, @"FillLight is higher than maximum value");
  
  _fillLight = fillLight;
  self[@"fillLight"] = @(fillLight);
}

- (void)setHighlights:(CGFloat)highlights {
  LTParameterAssert(highlights >= kMinHighlights, @"Highlights is lower than minimum value");
  LTParameterAssert(highlights <= kMaxHighlights, @"Highlights is higher than maximum value");
  
  _highlights = highlights;
  self[@"highlights"] = @(highlights);
}

@end
