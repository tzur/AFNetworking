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
  CGFloat width = MAX(1.0, input.size.width / kSmoothDownsampleFactor);
  CGFloat height = MAX(1.0, input.size.height / kSmoothDownsampleFactor);
  
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

static const uchar identityCurveData[256] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15,
  16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41,
  42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67,
  68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127, 128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143, 144, 145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 155, 156, 157, 158, 159, 160, 161, 162, 163, 164, 165, 166, 167, 168, 169, 170, 171, 172, 173, 174, 175, 176, 177, 178, 179, 180, 181, 182, 183, 184, 185, 186, 187, 188, 189, 190, 191, 192, 193, 194, 195, 196, 197, 198, 199, 200, 201, 202, 203, 204, 205, 206, 207, 208, 209, 210, 211, 212, 213, 214, 215, 216, 217, 218, 219, 220, 221, 222, 223, 224, 225, 226, 227, 228, 229, 230, 231, 232, 233, 234, 235, 236, 237, 238, 239, 240, 241, 242, 243, 244, 245, 246, 247, 248, 249, 250, 251, 252, 253, 254, 255};

// Details curves.
static const uchar fillLightCurveData[256] = {0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 25, 27, 29, 31, 33, 35, 37, 39, 41, 43, 46, 48, 50, 52, 54, 56, 59, 61, 63, 65, 67, 70, 72, 74, 77, 79, 81, 83, 86, 88, 90, 92, 94, 97, 99, 101, 103, 105, 107, 109, 111, 113, 115, 117, 119, 121, 122, 124, 126, 127, 129, 131, 132, 134, 135, 137, 138, 139, 141, 142, 143, 145, 146, 147, 148, 149, 151, 152, 153, 154, 155, 156, 157, 158, 159, 160, 161, 162, 163, 164, 165, 166, 167, 168, 169, 170, 171, 172, 172, 173, 174, 175, 176, 177, 177, 178, 179, 180, 181, 181, 182, 183, 184, 185, 185, 186, 187, 187, 188, 189, 190, 190, 191, 192, 192, 193, 194, 195, 195, 196, 197, 197, 198, 199, 199, 200, 200, 201, 202, 202, 203, 204, 204, 205, 205, 206, 207, 207, 208, 208, 209, 210, 210, 211, 211, 212, 212, 213, 214, 214, 215, 215, 216, 216, 217, 217, 218, 218, 219, 219, 220, 220, 221, 221, 222, 222, 223, 223, 224, 224, 225, 225, 226, 226, 227, 227, 228, 228, 229, 229, 229, 230, 230, 231, 231, 232, 232, 233, 233, 233, 234, 234, 235, 235, 236, 236, 236, 237, 237, 238, 238, 239, 239, 239, 240, 240, 241, 241, 241, 242, 242, 243, 243, 243, 244, 244, 245, 245, 245, 246, 246, 247, 247, 247, 248, 248, 249, 249, 249, 250, 250, 250, 251, 251, 252, 252, 252, 253, 253, 253, 254, 254, 255, 255};

static const uchar shadowsCurveData[256] = {0, 3, 6, 9, 12, 15, 18, 21, 24, 27, 29, 32, 35, 37, 39, 41, 44, 46, 48, 50, 51, 53, 55, 56, 58, 59, 61, 62, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 75, 76, 77, 77, 78, 78, 79, 80, 80, 81, 81, 81, 82, 82, 83, 83, 84, 84, 84, 85, 85, 85, 86, 86, 86, 87, 87, 87, 88, 88, 88, 89, 89, 89, 90, 90, 90, 91, 91, 92, 92, 93, 93, 93, 94, 94, 95, 96, 96, 97, 97, 98, 98, 99, 100, 100, 101, 102, 102, 103, 104, 105, 105, 106, 107, 108, 108, 109, 110, 111, 112, 112, 113, 114, 115, 116, 117, 118, 119, 120, 120, 121, 122, 123, 124, 125, 126, 127, 128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143, 144, 145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 155, 156, 157, 158, 159, 160, 161, 162, 163, 164, 165, 166, 167, 168, 169, 170, 171, 172, 173, 174, 175, 176, 177, 178, 179, 180, 181, 182, 183, 184, 185, 186, 187, 188, 189, 190, 191, 192, 193, 194, 195, 196, 197, 198, 199, 200, 201, 202, 203, 204, 205, 206, 207, 208, 209, 210, 211, 212, 213, 214, 215, 216, 217, 218, 219, 220, 221, 222, 223, 224, 225, 226, 227, 228, 229, 230, 231, 232, 233, 234, 235, 236, 237, 238, 239, 240, 241, 242, 243, 244, 245, 246, 247, 248, 249, 250, 251, 252, 253, 254, 255};

static const uchar highlightsCurveData[256] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127, 128, 129, 130, 131, 132, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143, 144, 145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 155, 156, 157, 158, 159, 160, 161, 162, 163, 164, 165, 166, 166, 167, 168, 169, 170, 171, 172, 172, 173, 174, 175, 175, 176, 177, 178, 178, 179, 180, 180, 181, 181, 182, 183, 183, 184, 184, 185, 185, 186, 186, 187, 187, 187, 188, 188, 189, 189, 189, 190, 190, 190, 190, 191, 191, 191, 192, 192, 192, 192, 192, 193, 193, 193, 193, 193, 193, 194, 194, 194, 194, 194, 194, 194, 194, 194, 194, 195, 195, 195, 195, 195, 195, 195, 195, 195, 195, 195, 195, 195, 195, 195, 195, 195, 195, 195, 195, 195, 195, 195, 195};

// Tone curves.
static const uchar positiveBrightnessCurveData[256] = {0, 3, 6, 9, 12, 14, 17, 20, 23, 26, 29, 32, 35, 37, 40, 43, 46, 49, 52, 54, 57, 60, 63, 65, 68, 71, 74, 76, 79, 82, 84, 87, 89, 92, 95, 97, 100, 102, 104, 107, 109, 112, 114, 116, 119, 121, 123, 125, 128, 130, 132, 134, 136, 138, 140, 142, 144, 146, 148, 150, 151, 153, 155, 157, 158, 160, 162, 163, 165, 167, 168, 170, 171, 173, 174, 175, 177, 178, 180, 181, 182, 183, 185, 186, 187, 188, 189, 191, 192, 193, 194, 195, 196, 197, 198, 199, 200, 201, 202, 203, 204, 205, 206, 206, 207, 208, 209, 210, 211, 211, 212, 213, 214, 214, 215, 216, 216, 217, 218, 218, 219, 220, 220, 221, 222, 222, 223, 223, 224, 225, 225, 226, 226, 227, 227, 228, 228, 229, 229, 230, 230, 231, 231, 232, 232, 233, 233, 234, 234, 235, 235, 235, 236, 236, 237, 237, 237, 238, 238, 239, 239, 239, 240, 240, 240, 241, 241, 241, 242, 242, 242, 242, 243, 243, 243, 244, 244, 244, 244, 245, 245, 245, 245, 246, 246, 246, 246, 247, 247, 247, 247, 247, 248, 248, 248, 248, 248, 249, 249, 249, 249, 249, 249, 250, 250, 250, 250, 250, 250, 251, 251, 251, 251, 251, 251, 251, 251, 252, 252, 252, 252, 252, 252, 252, 252, 252, 253, 253, 253, 253, 253, 253, 253, 253, 253, 253, 254, 254, 254, 254, 254, 254, 254, 254, 254, 254, 254, 254, 254, 255, 255, 255, 255, 255, 255, 255};

static const uchar negativeBrightnessCurveData[256] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 4, 4, 4, 4, 4, 5, 5, 5, 5, 5, 6, 6, 6, 6, 7, 7, 7, 7, 8, 8, 8, 9, 9, 9, 9, 10, 10, 11, 11, 11, 12, 12, 13, 13, 13, 14, 14, 15, 15, 16, 16, 17, 17, 18, 18, 19, 19, 20, 21, 21, 22, 23, 23, 24, 25, 25, 26, 27, 27, 28, 29, 30, 31, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 52, 53, 54, 55, 57, 58, 59, 61, 62, 63, 65, 66, 68, 69, 71, 72, 74, 75, 77, 79, 80, 82, 84, 85, 87, 89, 91, 93, 95, 96, 98, 100, 102, 104, 107, 109, 111, 113, 115, 117, 120, 122, 124, 126, 129, 131, 134, 136, 139, 141, 144, 146, 149, 152, 155, 157, 160, 163, 166, 169, 172, 175, 178, 181, 184, 187, 190, 194, 197, 200, 203, 207, 210, 214, 217, 221, 224, 228, 232, 236, 239, 243, 247, 251, 255};

static const uchar positiveContrastCurveData[256] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 6, 6, 6, 7, 7, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 13, 13, 14, 15, 15, 16, 17, 17, 18, 19, 20, 21, 22, 23, 24, 24, 26, 27, 28, 29, 30, 31, 32, 34, 35, 36, 38, 39, 41, 42, 44, 45, 47, 49, 50, 52, 54, 56, 58, 60, 62, 64, 66, 68, 70, 72, 74, 77, 79, 81, 84, 86, 88, 91, 93, 95, 98, 100, 103, 105, 108, 110, 112, 115, 117, 120, 122, 125, 128, 130, 133, 135, 138, 140, 143, 145, 147, 150, 152, 155, 157, 160, 162, 164, 167, 169, 171, 174, 176, 178, 180, 183, 185, 187, 189, 191, 193, 195, 197, 199, 201, 203, 205, 206, 208, 210, 211, 213, 215, 216, 217, 219, 220, 222, 223, 224, 225, 226, 227, 229, 230, 231, 232, 232, 233, 234, 235, 236, 237, 237, 238, 239, 239, 240, 241, 241, 242, 242, 243, 243, 244, 244, 245, 245, 246, 246, 247, 247, 247, 248, 248, 249, 249, 249, 250, 250, 250, 250, 251, 251, 251, 251, 252, 252, 252, 252, 252, 253, 253, 253, 253, 253, 253, 253, 253, 254, 254, 254, 254, 254, 254, 254, 254, 254, 254, 254, 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255};

static const uchar negativeContrastCurveData[256] = {128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128};


- (const cv::Mat1b &)identityCurve {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _identityCurve = dataToCurve(identityCurveData);
//     _identityCurve = LTLoadMat([self class], @"identityCurve.png");

//    _identityCurve = LTLoadMatWithName([self class], @"identityCurve.png");
    
  });
  return _identityCurve;
}

- (const cv::Mat1b &)fillLightCurve {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _fillLightCurve = dataToCurve(fillLightCurveData);
  });
  return _fillLightCurve;
}

- (const cv::Mat1b &)highlightsCurve {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _highlightsCurve = dataToCurve(highlightsCurveData);
  });
  return _highlightsCurve;
}

- (const cv::Mat1b &)shadowsCurve {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _shadowsCurve = dataToCurve(shadowsCurveData);
  });
  return _shadowsCurve;
}

- (const cv::Mat1b &)positiveBrightnessCurve {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _positiveBrightnessCurve = dataToCurve(positiveBrightnessCurveData);
  });
  return _positiveBrightnessCurve;
}

- (const cv::Mat1b &)negativeBrightnessCurve {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _negativeBrightnessCurve = dataToCurve(negativeBrightnessCurveData);
  });
  return _negativeBrightnessCurve;
}

- (const cv::Mat1b &)positiveContrastCurve {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _positiveContrastCurve = dataToCurve(positiveContrastCurveData);
  });
  return _positiveContrastCurve;
}

- (const cv::Mat1b &)negativeContrastCurve {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _negativeContrastCurve = dataToCurve(negativeContrastCurveData);
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
