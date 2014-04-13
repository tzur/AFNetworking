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

// Texture that holds LUT that encapsulates brightess, contrast, exposure, offset, black point and
// white point adjustments.
@property (strong, nonatomic) LTTexture *toneLUT;
// Texture that holds LUT that encapsulates shadows, fill light and highlights adjustments.
@property (strong, nonatomic) LTTexture *detailsLUT;

@end

@implementation LTAdjustProcessor

// The follow matrices hold the curves data.
static cv::Mat1b kIdentityCurve;
static cv::Mat1b kHighlightsCurve;
static cv::Mat1b kShadowsCurve;
static cv::Mat1b kFillLightCurve;
static cv::Mat1b kPositiveBrightnessCurve;
static cv::Mat1b kNegativeBrightnessCurve;
static cv::Mat1b kPositiveContrastCurve;
static cv::Mat1b kNegativeContrastCurve;

static const CGFloat kSmoothDownsampleFactor = 2.0;
static const NSUInteger kFineTextureIterations = 2;
static const NSUInteger kCoarseTextureIterations = 6;

static const ushort kLutSize = 256;

static const CGFloat kSaturationScaling = 1.5;
static const CGFloat kTemperatureScaling = 0.3;
static const CGFloat kTintScaling = 0.3;
static const CGFloat kDetailsScaling = 2.0;

- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output {
  LTProgram *program = [[LTProgram alloc] initWithVertexSource:[LTPassthroughShaderVsh source]
                                                fragmentSource:[LTAdjustFsh source]];
  // TODO:(zeev) Since smooth textures are used for luminance only, it make sense to build a
  // smoother that can leverage that by intermediate results into different RGBA channels. This will
  // reduce the sampling overhead in shaders and YIQ conversion computation.
  NSArray *smoothTextures = [self createSmoothTextures:input];
  NSDictionary *auxiliaryTextures =
      @{[LTAdjustFsh fineTexture]: smoothTextures[0],
        [LTAdjustFsh coarseTexture]: smoothTextures[1],
        [LTAdjustFsh detailsLUT]: [LTTexture textureWithImage:kIdentityCurve],
        [LTAdjustFsh toneLUT]: [LTTexture textureWithImage:kIdentityCurve]};
  if (self = [super initWithProgram:program sourceTexture:input auxiliaryTextures:auxiliaryTextures
                          andOutput:output]) {
    [self setDefaultValues];
  }
  return self;
}

+ (void)initialize {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    kIdentityCurve = LTLoadMatFromBundle([NSBundle LTKitBundle], @"IdentityCurve.png");
    kFillLightCurve = LTLoadMatFromBundle([NSBundle LTKitBundle], @"FillLightCurve.png");
    kHighlightsCurve = LTLoadMatFromBundle([NSBundle LTKitBundle], @"HighlightsCurve.png");
    kShadowsCurve = LTLoadMatFromBundle([NSBundle LTKitBundle], @"ShadowsCurve.png");
    kPositiveBrightnessCurve = LTLoadMatFromBundle([NSBundle LTKitBundle],
                                                   @"PositiveBrightnessCurve.png");
    kNegativeBrightnessCurve = LTLoadMatFromBundle([NSBundle LTKitBundle],
                                                   @"NegativeBrightnessCurve.png");
    kPositiveContrastCurve = LTLoadMatFromBundle([NSBundle LTKitBundle],
                                                 @"PositiveContrastCurve.png");
    kNegativeContrastCurve = LTLoadMatFromBundle([NSBundle LTKitBundle],
                                                 @"NegativeContrastCurve.png");
  });
}

- (void)setDefaultValues {
  self.brightness = self.defaultBrightness;
  self.contrast = self.defaultContrast;
  self.exposure = self.defaultExposure;
  self.offset = self.defaultOffset;
  self.blackPoint = self.defaultBlackPoint;
  self.whitePoint = self.defaultWhitePoint;
  self.saturation = self.defaultSaturation;
  self.temperature = self.defaultTemperature;
  self.tint = self.defaultTint;
  self.details = self.defaultDetails;
  self.shadows = self.defaultShadows;
  self.fillLight = self.defaultFillLight;
  self.highlights = self.defaultHighlights;
}

- (NSArray *)createSmoothTextures:(LTTexture *)input {
  CGFloat width = MAX(1.0, std::round(input.size.width / kSmoothDownsampleFactor));
  CGFloat height = MAX(1.0, std::round(input.size.height / kSmoothDownsampleFactor));
  
  LTTexture *fine = [LTTexture byteRGBATextureWithSize:CGSizeMake(width, height)];
  LTTexture *coarse = [LTTexture byteRGBATextureWithSize:CGSizeMake(width, height)];
 
  LTBilateralFilterProcessor *smoother =
      [[LTBilateralFilterProcessor alloc] initWithInput:input outputs:@[fine, coarse]];
  
  smoother.iterationsPerOutput = @[@(kFineTextureIterations), @(kCoarseTextureIterations)];
  smoother.rangeSigma = 0.1;
  [smoother process];
  
  return @[fine, coarse];
}

LTBoundedPrimitivePropertyImplementWithCustomSetter(CGFloat, brightness, Brightness, -1, 1, 0, ^{
  [self updateToneLUT];
});

LTBoundedPrimitivePropertyImplementWithCustomSetter(CGFloat, contrast, Contrast, -1, 1, 0, ^{
  [self updateToneLUT];
});

LTBoundedPrimitivePropertyImplementWithCustomSetter(CGFloat, exposure, Exposure, -1, 1, 0, ^{
  [self updateToneLUT];
});

LTBoundedPrimitivePropertyImplementWithCustomSetter(CGFloat, offset, Offset, -1, 1, 0, ^{
  [self updateToneLUT];
});

LTBoundedPrimitivePropertyImplementWithoutSetter(GLKVector3, blackPoint, BlackPoint,
                                                 GLKVector3Make(-1, -1, -1),
                                                 GLKVector3Make(1, 1, 1),
                                                 GLKVector3Make(0, 0, 0));

- (void)setBlackPoint:(GLKVector3)blackPoint {
  LTParameterAssert(GLKVector3AllGreaterThanOrEqualToVector3(blackPoint, self.minBlackPoint));
  LTParameterAssert(GLKVector3AllGreaterThanOrEqualToVector3(self.maxBlackPoint, blackPoint));
  _blackPoint = blackPoint;
  [self updateToneLUT];
}

LTBoundedPrimitivePropertyImplementWithoutSetter(GLKVector3, whitePoint, WhitePoint,
                                                 GLKVector3Make(0, 0, 0),
                                                 GLKVector3Make(2, 2, 2),
                                                 GLKVector3Make(1, 1, 1));

- (void)setWhitePoint:(GLKVector3)whitePoint {
  LTParameterAssert(GLKVectorInRange(whitePoint, 0.0, 2.0), @"Color filter is out of range.");
  LTParameterAssert(GLKVector3AllGreaterThanOrEqualToVector3(whitePoint, self.minWhitePoint));
  LTParameterAssert(GLKVector3AllGreaterThanOrEqualToVector3(self.maxWhitePoint, whitePoint));
  
  _whitePoint = whitePoint;
  [self updateToneLUT];
}

LTBoundedPrimitivePropertyImplementWithCustomSetter(CGFloat, saturation, Saturation, -1, 1, 0, ^{
  _saturation = saturation;
  // Remap [-1, 0] -> [0, 1] and [0, 1] to [1, 3].
  CGFloat remap = saturation < 0 ? saturation + 1 : 1 + saturation * kSaturationScaling;
  self[@"saturation"] = @(remap);
});

LTBoundedPrimitivePropertyImplementWithCustomSetter(CGFloat, temperature, Temperature, -1, 1, 0, ^{
  _temperature = temperature;
  // Remap [-1, 1] to [-kTemperatureScaling, kTemperatureScaling]
  // Temperature in this processor is an additive scale of the I channel in YIQ, so theoretically
  // max value is 0.596 (pure red) and min value is -0.596 (green-blue color).
  // Min/max can be easily deduced from the RGB -> YIQ conversion matrix, while taking into account
  // that RGB values are always positive.
  self[@"temperature"] = @(temperature * kTemperatureScaling);
});

LTBoundedPrimitivePropertyImplementWithCustomSetter(CGFloat, tint, Tint, -1, 1, 0, ^{
  _tint = tint;
  // Remap [-1, 1] to [-kTintScaling, kTintScaling]
  // Tint in this processor is an additive scale of the Q channel in YIQ, so theoretically
  // max value is 0.523 (red-blue) and min value is -0.523 (pure green).
  // Min/max can be easily deduced from the RGB -> YIQ conversion matrix, while taking into account
  // that RGB values are always positive.
  self[@"tint"] = @(tint * kTintScaling);
});

LTBoundedPrimitivePropertyImplementWithCustomSetter(CGFloat, details, Details, -1, 1, 0, ^{
  _details = details;
  self[@"details"] = @(details * kDetailsScaling);
});

LTBoundedPrimitivePropertyImplementWithCustomSetter(CGFloat, shadows, Shadows, 0, 1, 0, ^{
  [self updateDetailsLUT];
});

LTBoundedPrimitivePropertyImplementWithCustomSetter(CGFloat, fillLight, FillLight, 0, 1, 0, ^{
  [self updateDetailsLUT];
});

LTBoundedPrimitivePropertyImplementWithCustomSetter(CGFloat, highlights, Highlights, 0, 1, 0, ^{
  [self updateDetailsLUT];
});

- (LTTexture *)detailsLUT {
  if (!_detailsLUT) {
    _detailsLUT = [LTTexture textureWithImage:kIdentityCurve];
  }
  return _detailsLUT;
}

- (LTTexture *)toneLUT {
  if (!_toneLUT) {
    _toneLUT = [LTTexture textureWithImage:kIdentityCurve];
  }
  return _toneLUT;
}

- (void)updateDetailsLUT {
  cv::Mat1b detailsCurve(1, kLutSize);
  
  cv::LUT((1.0 - self.fillLight) * kIdentityCurve + self.fillLight * kFillLightCurve,
          (1.0 - self.shadows) * kIdentityCurve + self.shadows * kShadowsCurve, detailsCurve);
  
  cv::LUT(detailsCurve,
          (1.0 - self.highlights) * kIdentityCurve + self.highlights * kHighlightsCurve,
          detailsCurve);
  
  // Update details LUT texture in auxiliary textures.
  NSMutableDictionary *auxiliaryTextures = [self.auxiliaryTextures mutableCopy];
  auxiliaryTextures[[LTAdjustFsh detailsLUT]] = [LTTexture textureWithImage:detailsCurve];
  self.auxiliaryTextures = auxiliaryTextures;
}

// Update brightness, contrast, exposure and offset.
// Since these manipulations do not differ across RGB channels, they only require luminance update.
- (cv::Mat1b)toneLuminanceCurve {
  cv::Mat1b toneCurve(1, kLutSize);
  
  cv::Mat1b brightnessCurve(1, kLutSize);
  if (self.brightness >= self.defaultBrightness) {
    brightnessCurve = kPositiveBrightnessCurve;
  } else {
    brightnessCurve = kNegativeBrightnessCurve;
  }
  
  cv::Mat1b contrastCurve(1, kLutSize);
  if (self.contrast >= self.defaultContrast) {
    contrastCurve = kPositiveContrastCurve;
  } else {
    contrastCurve = kNegativeContrastCurve;
  }
  
  float brightness = std::abs(self.brightness);
  float contrast = std::abs(self.contrast);
  cv::LUT((1.0 - contrast) * kIdentityCurve + contrast * contrastCurve,
          (1.0 - brightness) * kIdentityCurve + brightness * brightnessCurve,
          toneCurve);
  
  toneCurve = toneCurve * std::pow(2.0, self.exposure) + self.offset * 255;
  
  return toneCurve;
}

// Update levels (white and black points) and curves.
// These manipulations can differ across RGB channels, thus 3-channels LUT is required.
- (cv::Mat1b)toneRGBACurveForLuminanceCurve:(cv::Mat1b)toneCurve {
  cv::Mat4b toneRGBACurve(1, kLutSize);
  
  GLKVector3 blackPoint = self.blackPoint * 255;
  GLKVector3 whitePoint = self.whitePoint * 255;
  
  // Levels: black and white point.
  for (int i = 0; i < kLutSize; i++) {
    // Remaps to [-kMinBlackPoint, kMaxWhitePoint].
    CGFloat red = (toneCurve(0, i) - blackPoint.r) / (whitePoint.r - blackPoint.r);
    CGFloat green = (toneCurve(0, i) - blackPoint.g) / (whitePoint.g - blackPoint.g);
    CGFloat blue = (toneCurve(0, i) - blackPoint.b) / (whitePoint.b - blackPoint.b);
    // Back to [0, 255].
    red = MIN(MAX(std::round(red * 255), 0), 255);
    green = MIN(MAX(std::round(green * 255), 0), 255);
    blue = MIN(MAX(std::round(blue * 255), 0), 255);
    
    toneRGBACurve(0, i) = cv::Vec4b(red, green, blue, 255);
  }
  return toneRGBACurve;
}

- (void)updateToneLUT {
  cv::Mat1b toneCurve = [self toneLuminanceCurve];
  cv::Mat4b toneRGBACurve = [self toneRGBACurveForLuminanceCurve:toneCurve];
  
  // Update details LUT texture in auxiliary textures.
  NSMutableDictionary *auxiliaryTextures = [self.auxiliaryTextures mutableCopy];
  auxiliaryTextures[[LTAdjustFsh toneLUT]] = [LTTexture textureWithImage:toneRGBACurve];
  self.auxiliaryTextures = auxiliaryTextures;
}

@end
