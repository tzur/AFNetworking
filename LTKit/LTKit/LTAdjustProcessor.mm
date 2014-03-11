// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTAdjustProcessor.h"

#import "LTBilateralFilterProcessor.h"
#import "LTBoxFilterProcessor.h"
#import "LTGLKitExtensions.h"
#import "LTOpenCVExtensions.h"
#import "LTProgram.h"
#import "LTShaderStorage+LTAdjustFsh.h"
#import "LTShaderStorage+LTPassthroughShaderVsh.h"
#import "LTTexture+Factory.h"
#import "NSBundle+LTKitBundle.h"

@interface LTGPUImageProcessor ()
@property (strong, nonatomic) NSDictionary *auxiliaryTextures;
@end

@interface LTAdjustProcessor ()

@property (strong, nonatomic) LTTexture *detailsLUT;
@property (strong, nonatomic) LTTexture *toneLUT;

//@property (readonly, nonatomic) const cv::Mat1b &identityCurve;
@property (readonly, nonatomic) const cv::Mat1b &highlightsCurve;
@property (readonly, nonatomic) const cv::Mat1b &shadowsCurve;
@property (readonly, nonatomic) const cv::Mat1b &fillLightCurve;

@property (readonly, nonatomic) const cv::Mat1b &positiveBrightnessCurve;
@property (readonly, nonatomic) const cv::Mat1b &negativeBrightnessCurve;
@property (readonly, nonatomic) const cv::Mat1b &positiveContrastCurve;
@property (readonly, nonatomic) const cv::Mat1b &negativeContrastCurve;

@end

@implementation LTAdjustProcessor

static cv::Mat1b _identityCurve;
static cv::Mat1b _highlightsCurve;
static cv::Mat1b _shadowsCurve;
static cv::Mat1b _fillLightCurve;
static cv::Mat1b _positiveBrightnessCurve;
static cv::Mat1b _negativeBrightnessCurve;
static cv::Mat1b _positiveContrastCurve;
static cv::Mat1b _negativeContrastCurve;

static const CGFloat kSmoothDownsampleFactor = 2.0;

static const ushort kLutSize = 256;

static const CGFloat kMinBrightness = -1.0;
static const CGFloat kMaxBrightness = 1.0;
static const CGFloat kDefaultBrightness = 0.0;

static const CGFloat kMinContrast = -1.0;
static const CGFloat kMaxContrast = 1.0;
static const CGFloat kDefaultContrast = 0.0;

static const CGFloat kMinExposure = -1.0;
static const CGFloat kMaxExposure = 1.0;
static const CGFloat kDefaultExposure = 0.0;

static const CGFloat kMinOffset = -1.0;
static const CGFloat kMaxOffset = 1.0;
static const CGFloat kDefaultOffset = 0.0;

static const GLKVector3 kDefaultBlackPoint = GLKVector3Make(0.0, 0.0, 0.0);
static const GLKVector3 kDefaultWhitePoint = GLKVector3Make(1.0, 1.0, 1.0);

static const CGFloat kMinSaturation = -1.0;
static const CGFloat kMaxSaturation = 1.0;
static const CGFloat kDefaultSaturation = 0.0;
static const CGFloat kSaturationScaling = 1.5;

static const CGFloat kMinTemperature = -1.0;
static const CGFloat kMaxTemperature = 1.0;
static const CGFloat kDefaultTemperature = 0.0;
static const CGFloat kTemperatureScaling = 0.3;

static const CGFloat kMinTint = -1.0;
static const CGFloat kMaxTint = 1.0;
static const CGFloat kDefaultTint = 0.0;
static const CGFloat kTintScaling = 0.3;

static const CGFloat kMinDetails = 0.0;
static const CGFloat kMaxDetails = 1.0;
static const CGFloat kDefaultDetails = 0.0;
static const CGFloat kDetailsScaling = 2.0;

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
        [LTAdjustFsh coarseTexture] : smoothTextures[1],
        [LTAdjustFsh detailsLUT] : [LTTexture textureWithImage:self.identityCurve],
        [LTAdjustFsh toneLUT] : [LTTexture textureWithImage:self.identityCurve]};
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
  CGFloat width = MAX(1.0, std::round(input.size.width / kSmoothDownsampleFactor));
  CGFloat height = MAX(1.0, std::round(input.size.height / kSmoothDownsampleFactor));
  
  LTTexture *fine = [LTTexture byteRGBATextureWithSize:CGSizeMake(width, height)];
  LTTexture *coarse = [LTTexture byteRGBATextureWithSize:CGSizeMake(width, height)];
 
  LTBilateralFilterProcessor *smoother =
      [[LTBilateralFilterProcessor alloc] initWithInput:input outputs:@[fine, coarse]];
  
  smoother.iterationsPerOutput = @[@2, @6];
  smoother.rangeSigma = 0.1;
  [smoother process];
  
  return @[fine, coarse];;
}

- (void)setBrightness:(CGFloat)brightness {
  LTParameterAssert(brightness >= kMinBrightness, @"Brightness is lower than minimum value");
  LTParameterAssert(brightness <= kMaxBrightness, @"Brightness is higher than maximum value");
  
  _brightness = brightness;
  [self updateToneLUT];
}

- (void)setContrast:(CGFloat)contrast {
  LTParameterAssert(contrast >= kMinContrast, @"Contrast is lower than minimum value");
  LTParameterAssert(contrast <= kMaxContrast, @"Contrast is higher than maximum value");
  
  _contrast = contrast;
  [self updateToneLUT];
}

- (void)setExposure:(CGFloat)exposure {
  LTParameterAssert(exposure >= kMinExposure, @"Exposure is lower than minimum value");
  LTParameterAssert(exposure <= kMaxExposure, @"Exposure is higher than maximum value");
  
  _exposure = exposure;
  [self updateToneLUT];
}

- (void)setOffset:(CGFloat)offset {
  LTParameterAssert(offset >= kMinOffset, @"Offset is lower than minimum value");
  LTParameterAssert(offset <= kMaxOffset, @"Offset is higher than maximum value");
  
  _offset = offset;
  [self updateToneLUT];
}

- (void)setBlackPoint:(GLKVector3)blackPoint {
  LTParameterAssert(GLKVectorInRange(blackPoint, -1.0, 1.0), @"Color filter is out of range.");
  
  _blackPoint = blackPoint;
  [self updateToneLUT];
}

- (void)setWhitePoint:(GLKVector3)whitePoint {
  LTParameterAssert(GLKVectorInRange(whitePoint, 0.0, 2.0), @"Color filter is out of range.");
  
  _whitePoint = whitePoint;
  [self updateToneLUT];
}

- (void)setSaturation:(CGFloat)saturation {
  LTParameterAssert(saturation >= kMinSaturation, @"Saturation is lower than minimum value");
  LTParameterAssert(saturation <= kMaxSaturation, @"Saturation is higher than maximum value");
  
  // Remap [-1, 0] -> [0, 1] and [0, 1] to [1, 3].
  _saturation = saturation < 0 ? saturation + 1 : 1 + saturation * kSaturationScaling;
  self[@"saturation"] = @(_saturation);
}

- (void)setTemperature:(CGFloat)temperature {
  LTParameterAssert(temperature >= kMinTemperature, @"Temperature is lower than minimum value");
  LTParameterAssert(temperature <= kMaxTemperature, @"Temperature is higher than maximum value");
  
  // Remap [-1, 1] to [-kTemperatureScaling, kTemperatureScaling]
  // Temperature in this processor is an additive scale of the I channel in YIQ, so theoretically
  // max value is 0.596 (pure red) and min value is -0.596 (green-blue color).
  // Min/max can be easily deduced from the RGB -> YIQ conversion matrix, while taking into account
  // that RGB values are alwasy positive.
  _temperature = temperature * kTemperatureScaling;
  self[@"temperature"] = @(_temperature);
}

- (void)setTint:(CGFloat)tint {
  LTParameterAssert(tint >= kMinTint, @"Tint is lower than minimum value");
  LTParameterAssert(tint <= kMaxTint, @"Tint is higher than maximum value");
  
  // Remap [-1, 1] to [-kTintScaling, kTintScaling]
  // Tint in this processor is an additive scale of the Q channel in YIQ, so theoretically
  // max value is 0.523 (red-blue) and min value is -0.523 (pure green).
  // Min/max can be easily deduced from the RGB -> YIQ conversion matrix, while taking into account
  // that RGB values are alwasy positive.
  _tint = tint * kTintScaling;
  self[@"tint"] = @(_tint);
}

- (void)setDetails:(CGFloat)details {
  LTParameterAssert(details >= kMinDetails, @"Details is lower than minimum value");
  LTParameterAssert(details <= kMaxDetails, @"Details is higher than maximum value");
  
  _details = details * kDetailsScaling;
  self[@"details"] = @(_details);
}

- (void)setShadows:(CGFloat)shadows {
  LTParameterAssert(shadows >= kMinShadows, @"Shadows is lower than minimum value");
  LTParameterAssert(shadows <= kMaxShadows, @"Shadows is higher than maximum value");
  
  _shadows = shadows;
  [self updateDetailsLUT];
}

- (void)setFillLight:(CGFloat)fillLight {
  LTParameterAssert(fillLight >= kMinFillLight, @"FillLight is lower than minimum value");
  LTParameterAssert(fillLight <= kMaxFillLight, @"FillLight is higher than maximum value");
  
  _fillLight = fillLight;
  [self updateDetailsLUT];
}

- (void)setHighlights:(CGFloat)highlights {
  LTParameterAssert(highlights >= kMinHighlights, @"Highlights is lower than minimum value");
  LTParameterAssert(highlights <= kMaxHighlights, @"Highlights is higher than maximum value");
  
  _highlights = highlights;
  [self updateDetailsLUT];
}

- (LTTexture *)detailsLUT {
  if (!_detailsLUT) {
    _detailsLUT = [LTTexture textureWithImage:[self identityCurve]];
  }
  return _detailsLUT;
}

- (LTTexture *)toneLUT {
  if (!_toneLUT) {
    _toneLUT = [LTTexture textureWithImage:[self identityCurve]];
  }
  return _toneLUT;
}

cv::Mat1b dataToCurve(const uchar *data) {
  cv::Mat1b curve(1, kLutSize);
  memcpy(curve.data, data, kLutSize * sizeof(uchar));
  return curve;
}

- (const cv::Mat1b &)identityCurve {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
     _identityCurve = LTLoadMatFromBundle([NSBundle LTKitBundle], @"IdentityCurve.png");
  });
  return _identityCurve;
}

- (const cv::Mat1b &)fillLightCurve {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _fillLightCurve = LTLoadMatFromBundle([NSBundle LTKitBundle], @"FillLightCurve.png");
  });
  return _fillLightCurve;
}

- (const cv::Mat1b &)highlightsCurve {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _highlightsCurve = LTLoadMatFromBundle([NSBundle LTKitBundle], @"HighlightsCurve.png");
  });
  return _highlightsCurve;
}

- (const cv::Mat1b &)shadowsCurve {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _shadowsCurve = LTLoadMatFromBundle([NSBundle LTKitBundle], @"ShadowsCurve.png");
  });
  return _shadowsCurve;
}

- (const cv::Mat1b &)positiveBrightnessCurve {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _positiveBrightnessCurve = LTLoadMatFromBundle([NSBundle LTKitBundle],
                                                   @"PositiveBrightnessCurve.png");
  });
  return _positiveBrightnessCurve;
}

- (const cv::Mat1b &)negativeBrightnessCurve {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _negativeBrightnessCurve = LTLoadMatFromBundle([NSBundle LTKitBundle],
                                                   @"NegativeBrightnessCurve.png");
  });
  return _negativeBrightnessCurve;
}

- (const cv::Mat1b &)positiveContrastCurve {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _positiveContrastCurve = LTLoadMatFromBundle([NSBundle LTKitBundle],
                                                 @"PositiveContrastCurve.png");
  });
  return _positiveContrastCurve;
}

- (const cv::Mat1b &)negativeContrastCurve {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _negativeContrastCurve = LTLoadMatFromBundle([NSBundle LTKitBundle],
                                                 @"NegativeContrastCurve.png");
  });
  return _negativeContrastCurve;
}

- (void)updateDetailsLUT {
  cv::Mat1b detailsCurve(1, kLutSize);
  
  cv::LUT((1.0 - self.fillLight) * self.identityCurve + self.fillLight * self.fillLightCurve,
          (1.0 - self.shadows) * self.identityCurve + self.shadows * self.shadowsCurve,
          detailsCurve);
  
  cv::LUT(detailsCurve,
          (1.0 - self.highlights) * self.identityCurve + self.highlights * self.highlightsCurve,
          detailsCurve);
  
  // Update details LUT texture in auxiliary textures.
  NSMutableDictionary *auxiliaryTextures = [self.auxiliaryTextures mutableCopy];
  auxiliaryTextures[[LTAdjustFsh detailsLUT]] = [LTTexture textureWithImage:detailsCurve];
  self.auxiliaryTextures = auxiliaryTextures;
}

- (void)updateToneLUT {
  cv::Mat1b toneCurve(1, kLutSize);
  cv::Mat4b toneRGBACurve(1, kLutSize);
  
  cv::Mat1b brightnessCurve(1, kLutSize);
  if (self.brightness >= kDefaultBrightness) {
    brightnessCurve = self.positiveBrightnessCurve;
  } else {
    brightnessCurve = self.negativeBrightnessCurve;
  }
  
  cv::Mat1b contrastCurve(1, kLutSize);
  if (self.contrast >= kDefaultContrast) {
    contrastCurve = self.positiveContrastCurve;
  } else {
    contrastCurve = self.negativeContrastCurve;
  }
  
  float brightness = std::abs(self.brightness);
  float contrast = std::abs(self.contrast);
  cv::LUT((1.0 - contrast) * self.identityCurve + contrast * contrastCurve,
          (1.0 - brightness) * self.identityCurve + brightness * brightnessCurve,
          toneCurve);
  
  toneCurve = toneCurve * std::pow(2.0, self.exposure) + self.offset * 255;
  
  GLKVector3 blackPoint = self.blackPoint * 255;
  GLKVector3 whitePoint = self.whitePoint * 255;
  
  // Levels: black and white point.
  for (NSUInteger i = 0; i < kLutSize; i++) {
    // Remaps to [0, 1].
    CGFloat red = (toneCurve(0, i) - blackPoint.r) / (whitePoint.r - blackPoint.r);
    CGFloat green = (toneCurve(0, i) - blackPoint.g) / (whitePoint.g - blackPoint.g);
    CGFloat blue = (toneCurve(0, i) - blackPoint.b) / (whitePoint.b - blackPoint.b);
    // Back to [0, 255].
    red = MIN(MAX(std::round(red * 255), 0), 255);
    green = MIN(MAX(std::round(green * 255), 0), 255);
    blue = MIN(MAX(std::round(blue * 255), 0), 255);
    
    toneRGBACurve(0, i) = cv::Vec4b(red, green, blue, 255);
  }
  
  // Update details LUT texture in auxiliary textures.
  NSMutableDictionary *auxiliaryTextures = [self.auxiliaryTextures mutableCopy];
  auxiliaryTextures[[LTAdjustFsh toneLUT]] = [LTTexture textureWithImage:toneRGBACurve];
  self.auxiliaryTextures = auxiliaryTextures;
}

@end
