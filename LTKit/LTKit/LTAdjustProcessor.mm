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
  // TODO:(zeev) Since smooth textures are used for luminance only, it make sense to build a
  // smoother that can leverage that by intermediate results into different RGBA channels. This will
  // reduce the sampling overhead in shaders and YIQ conversion computation.
  NSArray *smoothTextures = [self createSmoothTextures:input];
  NSDictionary *auxiliaryTextures =
      @{[LTAdjustFsh fineTexture]: smoothTextures[0],
        [LTAdjustFsh coarseTexture]: smoothTextures[1],
        [LTAdjustFsh detailsLUT]: [LTTexture textureWithImage:[LTCurve identity]],
        [LTAdjustFsh toneLUT]: [LTTexture textureWithImage:[LTCurve identity]]};
  if (self = [super initWithVertexSource:[LTPassthroughShaderVsh source]
                          fragmentSource:[LTAdjustFsh source] sourceTexture:input
                       auxiliaryTextures:auxiliaryTextures
                               andOutput:output]) {
    [self setDefaultValues];
  }
  return self;
}

- (void)setDefaultValues {
  [self setDefaultCurves];
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

- (void)setDefaultCurves {
  cv::Mat1b mat(1, kLutSize);
  for (ushort i = 0; i < kLutSize; ++i) {
    mat(0, i) = i;
  }
  _greyCurve = mat;
  _redCurve = mat;
  _greenCurve = mat;
  _blueCurve = mat;
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

#pragma mark -
#pragma mark Properties
#pragma mark -

LTPropertyWithoutSetter(CGFloat, brightness, Brightness, -1, 1, 0);
- (void)setBrightness:(CGFloat)brightness {
  [self _verifyAndSetBrightness:brightness];
  [self updateToneLUT];
}

LTPropertyWithoutSetter(CGFloat, contrast, Contrast, -1, 1, 0);
- (void)setContrast:(CGFloat)contrast {
  [self _verifyAndSetContrast:contrast];
  [self updateToneLUT];
}

LTPropertyWithoutSetter(CGFloat, exposure, Exposure, -1, 1, 0);
- (void)setExposure:(CGFloat)exposure {
  [self _verifyAndSetExposure:exposure];
  [self updateToneLUT];
}

LTPropertyWithoutSetter(CGFloat, offset, Offset, -1, 1, 0);
- (void)setOffset:(CGFloat)offset {
  [self _verifyAndSetOffset:offset];
  [self updateToneLUT];
}

LTPropertyWithoutSetter(LTVector3, blackPoint, BlackPoint,
                        -LTVector3One, LTVector3One, LTVector3Zero);
- (void)setBlackPoint:(LTVector3)blackPoint {
  [self _verifyAndSetBlackPoint:blackPoint];
  [self updateToneLUT];
}

LTPropertyWithoutSetter(LTVector3, whitePoint, WhitePoint,
                        LTVector3Zero, LTVector3(2, 2, 2), LTVector3One);
- (void)setWhitePoint:(LTVector3)whitePoint {
  [self _verifyAndSetWhitePoint:whitePoint];
  [self updateToneLUT];
}

LTPropertyWithoutSetter(LTVector3, midPoint, MidPoint,
                        -LTVector3One, LTVector3One, LTVector3Zero);
- (void)setMidPoint:(LTVector3)midPoint {
  [self _verifyAndSetMidPoint:midPoint];
  [self updateToneLUT];
}

LTPropertyWithoutSetter(CGFloat, saturation, Saturation, -1, 1, 0);
- (void)setSaturation:(CGFloat)saturation {
  [self _verifyAndSetSaturation:saturation];
  // Remap [-1, 0] -> [0, 1] and [0, 1] to [1, 3].
  CGFloat remap = saturation < 0 ? saturation + 1 : 1 + saturation * kSaturationScaling;
  self[[LTAdjustFsh saturation]] = @(remap);
}

LTPropertyWithoutSetter(CGFloat, temperature, Temperature, -1, 1, 0);
- (void)setTemperature:(CGFloat)temperature {
  [self _verifyAndSetTemperature:temperature];
  // Remap [-1, 1] to [-kTemperatureScaling, kTemperatureScaling]
  // Temperature in this processor is an additive scale of the I channel in YIQ, so theoretically
  // max value is 0.596 (pure red) and min value is -0.596 (green-blue color).
  // Min/max can be easily deduced from the RGB -> YIQ conversion matrix, while taking into account
  // that RGB values are always positive.
  self[[LTAdjustFsh temperature]] = @(temperature * kTemperatureScaling);
}

LTPropertyWithoutSetter(CGFloat, tint, Tint, -1, 1, 0);
- (void)setTint:(CGFloat)tint {
  [self _verifyAndSetTint:tint];
  // Remap [-1, 1] to [-kTintScaling, kTintScaling]
  // Tint in this processor is an additive scale of the Q channel in YIQ, so theoretically
  // max value is 0.523 (red-blue) and min value is -0.523 (pure green).
  // Min/max can be easily deduced from the RGB -> YIQ conversion matrix, while taking into account
  // that RGB values are always positive.
  self[[LTAdjustFsh tint]] = @(tint * kTintScaling);
}

LTPropertyWithoutSetter(CGFloat, details, Details, -1, 1, 0);
- (void)setDetails:(CGFloat)details {
  [self _verifyAndSetDetails:details];
  self[[LTAdjustFsh details]] = @(details * kDetailsScaling);
}

LTPropertyWithoutSetter(CGFloat, shadows, Shadows, 0, 1, 0);
- (void)setShadows:(CGFloat)shadows {
  [self _verifyAndSetShadows:shadows];
  [self updateDetailsLUT];
}

LTPropertyWithoutSetter(CGFloat, fillLight, FillLight, 0, 1, 0);
- (void)setFillLight:(CGFloat)fillLight {
  [self _verifyAndSetFillLight:fillLight];
  [self updateDetailsLUT];
}

LTPropertyWithoutSetter(CGFloat, highlights, Highlights, 0, 1, 0);
- (void)setHighlights:(CGFloat)highlights {
  [self _verifyAndSetHighlights:highlights];
  [self updateDetailsLUT];
}

- (BOOL)validateCurve:(cv::Mat1b)curve {
  return curve.rows == 1 && curve.cols == 256 && curve.type() == CV_8U;
}

- (void)setGreyCurve:(cv::Mat1b)greyCurve {
  LTParameterAssert([self validateCurve:greyCurve], @"Grey curve should be 1x256 CV_8U matrix");
  _greyCurve = greyCurve.clone();
  [self updateToneLUT];
}

- (void)setRedCurve:(cv::Mat1b)redCurve {
  LTParameterAssert([self validateCurve:redCurve], @"Red curve should be 1x256 CV_8U matrix");
  _redCurve = redCurve.clone();
  [self updateToneLUT];
}

- (void)setGreenCurve:(cv::Mat1b)greenCurve {
  LTParameterAssert([self validateCurve:greenCurve], @"Green curve should be 1x256 CV_8U matrix");
  _greenCurve = greenCurve.clone();
  [self updateToneLUT];
}

- (void)setBlueCurve:(cv::Mat1b)blueCurve {
  LTParameterAssert([self validateCurve:blueCurve], @"Blue curve should be 1x256 CV_8U matrix");
  _blueCurve = blueCurve.clone();
  [self updateToneLUT];
}

#pragma mark -
#pragma mark Processing
#pragma mark -

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
- (cv::Mat1b)applyTone {
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

typedef std::vector<cv::Mat1b> Channels;

- (Channels)applyLevels:(cv::Mat1b)toneCurve {
  LTVector3 midPoint = LTVector3One + self.midPoint * 0.8;
  
  // Levels: black, white and mid points.
  std::vector<cv::Mat1b> levels = {cv::Mat1b(1, kLutSize), cv::Mat1b(1, kLutSize),
    cv::Mat1b(1, kLutSize)};
  for (int i = 0; i < kLutSize; i++) {
    // Remaps to [-kMinBlackPoint, kMaxWhitePoint].
    CGFloat red = (std::powf(toneCurve(0, i) / 255.0, midPoint.r()) - self.blackPoint.r()) /
        (self.whitePoint.r() - self.blackPoint.r());
    CGFloat green = (std::powf(toneCurve(0, i) / 255.0, midPoint.g())  - self.blackPoint.g()) /
        (self.whitePoint.g() - self.blackPoint.g());
    CGFloat blue = (std::powf(toneCurve(0, i) / 255.0, midPoint.b())  - self.blackPoint.b()) /
        (self.whitePoint.b() - self.blackPoint.b());
    // Back to [0, 255].
    levels[0](0, i) = MIN(MAX(std::round(red * 255), 0), 255);
    levels[1](0, i) = MIN(MAX(std::round(green * 255), 0), 255);
    levels[2](0, i) = MIN(MAX(std::round(blue * 255), 0), 255);
  }
  return levels;
}

- (cv::Mat4b)applyCurves:(Channels)levels {
  // Apply per-channel rgb curves.
  std::vector<cv::Mat1b> colorChannels(3);
  cv::LUT(levels[0], self.redCurve, colorChannels[0]);
  cv::LUT(levels[1], self.greenCurve, colorChannels[1]);
  cv::LUT(levels[2], self.blueCurve, colorChannels[2]);
  
  // Apply grey (luminance) curve across the channels.
  std::vector<cv::Mat1b> channels(4);
  for (NSUInteger i = 0; i < 3; ++i) {
    cv::LUT(colorChannels[i], self.greyCurve, channels[i]);
  }
  channels[3] = cv::Mat1b(1, kLutSize, 255);
  
  cv::Mat4b mergedCurves(1, kLutSize);
  cv::merge(channels, mergedCurves);
  
  return mergedCurves;
}

- (void)updateToneLUT {
  cv::Mat1b toneCurve = [self applyTone];
  Channels levels = [self applyLevels:toneCurve];
  cv::Mat4b curves = [self applyCurves:levels];

  [self setAuxiliaryTexture:[LTTexture textureWithImage:curves]
                   withName:[LTAdjustFsh toneLUT]];
}

@end
