// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTAdjustProcessor.h"

#import "LTBilateralFilterProcessor.h"
#import "LTBoxFilterProcessor.h"
#import "LTCurve.h"
#import "LTGLKitExtensions.h"
#import "LTGPUImageProcessor+Protected.h"
#import "LTOpenCVExtensions.h"
#import "LTProgram.h"
#import "LTShaderStorage+LTAdjustFsh.h"
#import "LTShaderStorage+LTPassthroughShaderVsh.h"
#import "LTTexture+Factory.h"
#import "NSBundle+LTKitBundle.h"

@interface LTAdjustProcessor ()

/// Texture that holds LUT that encapsulates brightess, contrast, exposure, offset, black point and
/// white point adjustments.
@property (strong, nonatomic) LTTexture *toneLUT;

/// Texture that holds LUT that encapsulates shadows, fill light and highlights adjustments.
@property (strong, nonatomic) LTTexture *detailsLUT;

@end

@implementation LTAdjustProcessor

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
        [LTAdjustFsh detailsLUT]: [LTTexture textureWithImage:[LTCurve identity]],
        [LTAdjustFsh toneLUT]: [LTTexture textureWithImage:[LTCurve identity]]};
  if (self = [super initWithProgram:program sourceTexture:input auxiliaryTextures:auxiliaryTextures
                          andOutput:output]) {
    [self setDefaultValues];
  }
  return self;
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

LTPropertyWithSetter(CGFloat, brightness, Brightness, -1, 1, 0, ^{
  [self updateToneLUT];
});

LTPropertyWithSetter(CGFloat, contrast, Contrast, -1, 1, 0, ^{
  [self updateToneLUT];
});

LTPropertyWithSetter(CGFloat, exposure, Exposure, -1, 1, 0, ^{
  [self updateToneLUT];
});

LTPropertyWithSetter(CGFloat, offset, Offset, -1, 1, 0, ^{
  [self updateToneLUT];
});

LTPropertyWithSetter(GLKVector3, blackPoint, BlackPoint,
                     -GLKVector3One, GLKVector3One, GLKVector3Zero, ^{
  [self updateToneLUT];
});

LTPropertyWithSetter(GLKVector3, whitePoint, WhitePoint,
                     GLKVector3Zero, GLKVector3Make(2), GLKVector3One, ^{
  [self updateToneLUT];
});

LTPropertyWithSetter(CGFloat, saturation, Saturation, -1, 1, 0, ^{
  // Remap [-1, 0] -> [0, 1] and [0, 1] to [1, 3].
  CGFloat remap = saturation < 0 ? saturation + 1 : 1 + saturation * kSaturationScaling;
  self[[LTAdjustFsh saturation]] = @(remap);
});

LTPropertyWithSetter(CGFloat, temperature, Temperature, -1, 1, 0, ^{
  // Remap [-1, 1] to [-kTemperatureScaling, kTemperatureScaling]
  // Temperature in this processor is an additive scale of the I channel in YIQ, so theoretically
  // max value is 0.596 (pure red) and min value is -0.596 (green-blue color).
  // Min/max can be easily deduced from the RGB -> YIQ conversion matrix, while taking into account
  // that RGB values are always positive.
  self[[LTAdjustFsh temperature]] = @(temperature * kTemperatureScaling);
});

LTPropertyWithSetter(CGFloat, tint, Tint, -1, 1, 0, ^{
  // Remap [-1, 1] to [-kTintScaling, kTintScaling]
  // Tint in this processor is an additive scale of the Q channel in YIQ, so theoretically
  // max value is 0.523 (red-blue) and min value is -0.523 (pure green).
  // Min/max can be easily deduced from the RGB -> YIQ conversion matrix, while taking into account
  // that RGB values are always positive.
  self[[LTAdjustFsh tint]] = @(tint * kTintScaling);
});

LTPropertyWithSetter(CGFloat, details, Details, -1, 1, 0, ^{
  self[[LTAdjustFsh details]] = @(details * kDetailsScaling);
});

LTPropertyWithSetter(CGFloat, shadows, Shadows, 0, 1, 0, ^{
  [self updateDetailsLUT];
});

LTPropertyWithSetter(CGFloat, fillLight, FillLight, 0, 1, 0, ^{
  [self updateDetailsLUT];
});

LTPropertyWithSetter(CGFloat, highlights, Highlights, 0, 1, 0, ^{
  [self updateDetailsLUT];
});

- (LTTexture *)detailsLUT {
  if (!_detailsLUT) {
    _detailsLUT = [LTTexture textureWithImage:[LTCurve identity]];
  }
  return _detailsLUT;
}

- (LTTexture *)toneLUT {
  if (!_toneLUT) {
    _toneLUT = [LTTexture textureWithImage:[LTCurve identity]];
  }
  return _toneLUT;
}

- (void)updateDetailsLUT {
  cv::Mat1b detailsCurve(1, kLutSize);
  
  cv::LUT((1.0 - self.fillLight) * [LTCurve identity] + self.fillLight * [LTCurve fillLight],
          (1.0 - self.shadows) * [LTCurve identity] + self.shadows * [LTCurve shadows],
          detailsCurve);
  
  cv::LUT(detailsCurve,
          (1.0 - self.highlights) * [LTCurve identity] + self.highlights * [LTCurve highlights],
          detailsCurve);

  [self setAuxiliaryTexture:[LTTexture textureWithImage:detailsCurve]
                   withName:[LTAdjustFsh detailsLUT]];
}

// Update brightness, contrast, exposure and offset.
// Since these manipulations do not differ across RGB channels, they only require luminance update.
- (cv::Mat1b)toneLuminanceCurve {
  cv::Mat1b toneCurve(1, kLutSize);
  
  cv::Mat1b brightnessCurve(1, kLutSize);
  if (self.brightness >= self.defaultBrightness) {
    brightnessCurve = [LTCurve positiveBrightness];
  } else {
    brightnessCurve = [LTCurve negativeBrightness];
  }
  
  cv::Mat1b contrastCurve(1, kLutSize);
  if (self.contrast >= self.defaultContrast) {
    contrastCurve = [LTCurve positiveContrast];
  } else {
    contrastCurve = [LTCurve negativeContrast];
  }
  
  float brightness = std::abs(self.brightness);
  float contrast = std::abs(self.contrast);
  cv::LUT((1.0 - contrast) * [LTCurve identity] + contrast * contrastCurve,
          (1.0 - brightness) * [LTCurve identity] + brightness * brightnessCurve,
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
  
  [self setAuxiliaryTexture:[LTTexture textureWithImage:toneRGBACurve]
                   withName:[LTAdjustFsh toneLUT]];
}

@end
