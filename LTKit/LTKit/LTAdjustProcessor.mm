// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTAdjustProcessor.h"

#import "LTCLAHEProcessor.h"
#import "LTColorGradient.h"
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

/// RGBA textures with one row and 256 columns that encapsulates channel-to-channel mapping:
/// brightness, contrast, exposure, offset and curves. Default value is an identity mapping across
/// the channels. Two textures are used for ping-pong rendering that improves the performance.

/// First tone LUT texture.
@property (strong, nonatomic) LTTexture *toneLUTA;

/// Second tone LUT texture.
@property (strong, nonatomic) LTTexture *toneLUTB;

/// If \c YES, \c toneLUTA will be used during the next rendering pass, \c toneLUTB otherwise.
@property (nonatomic) BOOL shouldUseToneLUTTextureB;

/// If \c YES, tone LUT update should run at the next processing round of this processor.
@property (nonatomic) BOOL shouldUpdateToneLUT;

/// Texture that holds LUT that encapsulates shadows, fill light and highlights adjustments.
@property (strong, nonatomic) LTTexture *detailsLUT;

/// If \c YES, details LUT update should run at the next processing round of this processor.
@property (nonatomic) BOOL shouldUpdateDetailsLUT;

/// RGBA texture with one row and 256 columns that defines greyscale to color mapping. Alpha channel
/// is not used. Default value is an identity mapping across the channels.
@property (strong, nonatomic) LTTexture *colorGradientTexture;

/// If \c YES, color gradient update should run at the next processing round of this processor.
@property (nonatomic) BOOL shouldUpdateColorGradient;

/// If \c YES, tonal transform update should run at the next processing round of this processor.
@property (nonatomic) BOOL shouldUpdateTonalTransform;

/// The generation id of the input texture that was used to create the current details textures.
@property (nonatomic) NSUInteger detailsTextureGenerationID;

@end

@implementation LTAdjustProcessor

static const ushort kLutSize = 256;

static const CGFloat kSaturationScaling = 1.5;
static const CGFloat kTemperatureScaling = 0.3;
static const CGFloat kTintScaling = 0.3;

- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output {
  if (self = [super initWithVertexSource:[LTPassthroughShaderVsh source]
                          fragmentSource:[LTAdjustFsh source] input:input andOutput:output]) {
    [self createColorGradientTextures];
    [self setDefaultCurves];
    NSSet *keys = [NSSet setWithArray:@[@keypath(self.redCurve),
                                        @keypath(self.greenCurve),
                                        @keypath(self.blueCurve),
                                        @keypath(self.greyCurve)]];
    [self resetInputModelExceptKeys:keys];
  }
  return self;
}

- (void)createColorGradientTextures {
  self.toneLUTA = [[self defaultColorGradient] textureWithSamplingPoints:kLutSize];
  self.toneLUTB = [[self defaultColorGradient] textureWithSamplingPoints:kLutSize];
}

- (void)setDefaultCurves {
  _greyCurve = [self defaultGreyCurve];
  _redCurve = [self defaultRedCurve];
  _greenCurve = [self defaultGreenCurve];
  _blueCurve = [self defaultBlueCurve];
}

- (cv::Mat1b)defaultRedCurve {
  return [self defaultCurve];
}

- (cv::Mat1b)defaultGreenCurve {
  return [self defaultCurve];
}

- (cv::Mat1b)defaultBlueCurve {
  return [self defaultCurve];
}

- (cv::Mat1b)defaultGreyCurve {
  return [self defaultCurve];
}

- (cv::Mat1b)defaultCurve {
  cv::Mat1b mat(1, kLutSize, (uchar)1);
  for (ushort i = 0; i < kLutSize; ++i) {
    mat(0, i) = i;
  }
  return mat;
}

- (LTColorGradient *)defaultColorGradient {
  return [LTColorGradient identityGradient];
}

- (void)updateDetailsTextureIfNecessary {
  if (self.detailsTextureGenerationID != self.inputTexture.generationID ||
      !self.auxiliaryTextures[[LTAdjustFsh detailsTexture]]) {
    self.detailsTextureGenerationID = self.inputTexture.generationID;
    [self setAuxiliaryTexture:[self createDetailsTexture:self.inputTexture]
                     withName:[LTAdjustFsh detailsTexture]];
  }
}

- (LTTexture *)createDetailsTexture:(LTTexture *)inputTexture {
  LTTexture *detailsTexture = [LTTexture byteRedTextureWithSize:inputTexture.size];
  LTCLAHEProcessor *processor = [[LTCLAHEProcessor alloc] initWithInputTexture:self.inputTexture
                                                                 outputTexture:detailsTexture];
  [processor process];
  return detailsTexture;
}

#pragma mark -
#pragma mark Input model
#pragma mark -

+ (NSSet *)inputModelPropertyKeys {
  static NSSet *properties;
  
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    properties = [NSSet setWithArray:@[
      @instanceKeypath(LTAdjustProcessor, brightness),
      @instanceKeypath(LTAdjustProcessor, contrast),
      @instanceKeypath(LTAdjustProcessor, exposure),
      @instanceKeypath(LTAdjustProcessor, offset),

      @instanceKeypath(LTAdjustProcessor, blackPointShift),
      @instanceKeypath(LTAdjustProcessor, whitePointShift),

      @instanceKeypath(LTAdjustProcessor, redCurve),
      @instanceKeypath(LTAdjustProcessor, greenCurve),
      @instanceKeypath(LTAdjustProcessor, blueCurve),
      @instanceKeypath(LTAdjustProcessor, greyCurve),
       
      @instanceKeypath(LTAdjustProcessor, hue),
      @instanceKeypath(LTAdjustProcessor, saturation),
      @instanceKeypath(LTAdjustProcessor, temperature),
      @instanceKeypath(LTAdjustProcessor, tint),
       
      @instanceKeypath(LTAdjustProcessor, details),
      @instanceKeypath(LTAdjustProcessor, shadows),
      @instanceKeypath(LTAdjustProcessor, fillLight),
      @instanceKeypath(LTAdjustProcessor, highlights),

      @instanceKeypath(LTAdjustProcessor, darksSaturation),
      @instanceKeypath(LTAdjustProcessor, darksHue),
      @instanceKeypath(LTAdjustProcessor, lightsSaturation),
      @instanceKeypath(LTAdjustProcessor, lightsHue),
      @instanceKeypath(LTAdjustProcessor, balance)
    ]];
  });
  
  return properties;
}

#pragma mark -
#pragma mark Processing
#pragma mark -

- (void)preprocess {
  [self updateDetailsTextureIfNecessary];

  [self updateLUTs];
}

- (void)setNeedsToneLUTUpdate {
  self.shouldUpdateToneLUT = YES;
}

- (void)setNeedsDetailsLUTUpdate {
  self.shouldUpdateDetailsLUT = YES;
}

- (void)setNeedsColorGradientUpdate {
  self.shouldUpdateColorGradient = YES;
}

- (void)setNeedsTonalTransformUpdate {
  self.shouldUpdateTonalTransform = YES;
}

- (void)updateLUTs {
  if (self.shouldUpdateToneLUT) {
    [self updateToneLUT];
    self.shouldUpdateToneLUT = NO;
  }
  if (self.shouldUpdateDetailsLUT) {
    [self updateDetailsLUT];
    self.shouldUpdateDetailsLUT = NO;
  }
  if (self.shouldUpdateColorGradient) {
    [self updateColorGradient];
    self.shouldUpdateColorGradient = NO;
  }
  if (self.shouldUpdateTonalTransform) {
    [self updateTonalTransform];
    self.shouldUpdateTonalTransform = NO;
  }
}

#pragma mark -
#pragma mark Tone
#pragma mark -

LTPropertyWithoutSetter(CGFloat, brightness, Brightness, -1, 1, 0);
- (void)setBrightness:(CGFloat)brightness {
  [self _verifyAndSetBrightness:brightness];
  [self setNeedsToneLUTUpdate];
}

LTPropertyWithoutSetter(CGFloat, contrast, Contrast, -1, 1, 0);
- (void)setContrast:(CGFloat)contrast {
  [self _verifyAndSetContrast:contrast];
  [self setNeedsToneLUTUpdate];
}

LTPropertyWithoutSetter(CGFloat, exposure, Exposure, -1, 1, 0);
- (void)setExposure:(CGFloat)exposure {
  [self _verifyAndSetExposure:exposure];
  [self setNeedsToneLUTUpdate];
}

LTPropertyWithoutSetter(CGFloat, offset, Offset, -1, 1, 0);
- (void)setOffset:(CGFloat)offset {
  [self _verifyAndSetOffset:offset];
  [self setNeedsToneLUTUpdate];
}

- (BOOL)validateCurve:(cv::Mat1b)curve {
  return curve.rows == 1 && curve.cols == kLutSize && curve.type() == CV_8U;
}

- (void)setGreyCurve:(cv::Mat1b)greyCurve {
  LTParameterAssert([self validateCurve:greyCurve], @"Grey curve should be 1x256 CV_8U matrix");
  _greyCurve = greyCurve.clone();
  [self setNeedsToneLUTUpdate];
}

- (void)setRedCurve:(cv::Mat1b)redCurve {
  LTParameterAssert([self validateCurve:redCurve], @"Red curve should be 1x256 CV_8U matrix");
  _redCurve = redCurve.clone();
  [self setNeedsToneLUTUpdate];
}

- (void)setGreenCurve:(cv::Mat1b)greenCurve {
  LTParameterAssert([self validateCurve:greenCurve], @"Green curve should be 1x256 CV_8U matrix");
  _greenCurve = greenCurve.clone();
  [self setNeedsToneLUTUpdate];
}

- (void)setBlueCurve:(cv::Mat1b)blueCurve {
  LTParameterAssert([self validateCurve:blueCurve], @"Blue curve should be 1x256 CV_8U matrix");
  _blueCurve = blueCurve.clone();
  [self setNeedsToneLUTUpdate];
}

#pragma mark -
#pragma mark Levels
#pragma mark -

LTPropertyWithoutSetter(CGFloat, blackPointShift, BlackPointShift, -1, 1, 0);
- (void)setBlackPointShift:(CGFloat)blackPointShift {
  [self _verifyAndSetBlackPointShift:blackPointShift];
  self[[LTAdjustFsh blackPoint]] = @(blackPointShift);
}

LTPropertyWithoutSetter(CGFloat, whitePointShift, WhitePointShift, -1, 1, 0);
- (void)setWhitePointShift:(CGFloat)whitePointShift {
  [self _verifyAndSetWhitePointShift:whitePointShift];
  self[[LTAdjustFsh whitePoint]] = @(1 + whitePointShift);
}

#pragma mark -
#pragma mark Color
#pragma mark -

LTPropertyWithoutSetter(CGFloat, saturation, Saturation, -1, 1, 0);
- (void)setSaturation:(CGFloat)saturation {
  [self _verifyAndSetSaturation:saturation];
  [self setNeedsTonalTransformUpdate];
}

LTPropertyWithoutSetter(CGFloat, temperature, Temperature, -1, 1, 0);
- (void)setTemperature:(CGFloat)temperature {
  [self _verifyAndSetTemperature:temperature];
  [self setNeedsTonalTransformUpdate];
}

LTPropertyWithoutSetter(CGFloat, tint, Tint, -1, 1, 0);
- (void)setTint:(CGFloat)tint {
  [self _verifyAndSetTint:tint];
  [self setNeedsTonalTransformUpdate];
}

LTPropertyWithoutSetter(CGFloat, hue, Hue, -1, 1, 0);
- (void)setHue:(CGFloat)hue {
  [self _verifyAndSetHue:hue];
  [self setNeedsTonalTransformUpdate];
}

/// This method passes to the shader a 4x4 matrix that encapsulated the following tonal adjustments:
/// Hue, saturation, temperature and tint.
/// Using the formalism of the affine transformations, conversion to and from YIQ color space is
/// a rotation. Saturation is a scaling of y and z axis. Temparature and tint are offsets of these
/// two axis. Hue is a rotation around x axis.
- (void)updateTonalTransform {
  static const GLKMatrix4 kRGBtoYIQ = GLKMatrix4Make(0.299, 0.596, 0.212, 0,
                                                     0.587, -0.274, -0.523, 0,
                                                     0.114, -0.322, 0.311, 0,
                                                     0, 0, 0, 1);
  static const GLKMatrix4 kYIQtoRGB = GLKMatrix4Make(1, 1, 1, 0,
                                                     0.9563, -0.2721, -1.107, 0,
                                                     0.621, -0.6474, 1.7046, 0,
                                                     0, 0, 0, 1);
  GLKMatrix4 temperatureAndTint = GLKMatrix4Identity;
  temperatureAndTint.m31 = [self remapTemperature:self.temperature];
  temperatureAndTint.m32 = [self remapTint:self.tint];

  GLKMatrix4 saturation = GLKMatrix4Identity;
  saturation.m11 = [self remapSaturation:self.saturation];
  saturation.m22 = [self remapSaturation:self.saturation];

  GLKMatrix4 hue = GLKMatrix4MakeXRotation(self.hue * M_PI);

  GLKMatrix4 tonalTranform = GLKMatrix4Multiply(saturation, kRGBtoYIQ);
  tonalTranform = GLKMatrix4Multiply(hue, tonalTranform);
  tonalTranform = GLKMatrix4Multiply(temperatureAndTint, tonalTranform);
  tonalTranform = GLKMatrix4Multiply(kYIQtoRGB, tonalTranform);

  self[[LTAdjustFsh tonalTransform]] = $(tonalTranform);
}

/// Remap [-1, 0] -> [0, 1] and [0, 1] to [1, kSaturationScaling].
- (CGFloat)remapSaturation:(CGFloat)saturation {
  return saturation < 0 ? saturation + 1 : 1 + saturation * kSaturationScaling;
}

- (CGFloat)remapTint:(CGFloat)tint {
  // Remap [-1, 1] to [-kTintScaling, kTintScaling]
  // Tint in this processor is an additive scale of the Q channel in YIQ, so theoretically
  // max value is 0.523 (red-blue) and min value is -0.523 (pure green).
  // Min/max can be easily deduced from the RGB -> YIQ conversion matrix, while taking into account
  // that RGB values are always positive.
  return tint * kTintScaling;
}

- (CGFloat)remapTemperature:(CGFloat)temperature {
  // Remap [-1, 1] to [-kTemperatureScaling, kTemperatureScaling]
  // Temperature in this processor is an additive scale of the I channel in YIQ, so theoretically
  // max value is 0.596 (pure red) and min value is -0.596 (green-blue color).
  // Min/max can be easily deduced from the RGB -> YIQ conversion matrix, while taking into account
  // that RGB values are always positive.
  return temperature * kTemperatureScaling;
}

#pragma mark -
#pragma mark Details
#pragma mark -

LTPropertyWithoutSetter(CGFloat, details, Details, -1, 1, 0);
- (void)setDetails:(CGFloat)details {
  [self _verifyAndSetDetails:details];
  [self updateDetails];
}

- (void)updateDetails {
  CGFloat details = MAX(0, self.shadows) * 0.1 + self.details * 0.90;
  self[[LTAdjustFsh detailsBoost]] = @(details);
}

LTPropertyWithoutSetter(CGFloat, shadows, Shadows, -1, 1, 0);
- (void)setShadows:(CGFloat)shadows {
  [self _verifyAndSetShadows:shadows];
  [self setNeedsDetailsLUTUpdate];
  [self updateDetails];
}

LTPropertyWithoutSetter(CGFloat, fillLight, FillLight, 0, 1, 0);
- (void)setFillLight:(CGFloat)fillLight {
  [self _verifyAndSetFillLight:fillLight];
  [self setNeedsDetailsLUTUpdate];
}

LTPropertyWithoutSetter(CGFloat, highlights, Highlights, -1, 1, 0);
- (void)setHighlights:(CGFloat)highlights {
  [self _verifyAndSetHighlights:highlights];
  [self setNeedsDetailsLUTUpdate];
}

#pragma mark -
#pragma mark Split Toning
#pragma mark -

LTPropertyWithoutSetter(CGFloat, darksSaturation, DarksSaturation, 0, 1, 0);
- (void)setDarksSaturation:(CGFloat)darksSaturation {
  [self _verifyAndSetDarksSaturation:darksSaturation];
  [self setNeedsColorGradientUpdate];
}

LTPropertyWithoutSetter(CGFloat, darksHue, DarksHue, 0, 1, 0);
- (void)setDarksHue:(CGFloat)darksHue {
  [self _verifyAndSetDarksHue:darksHue];
  [self setNeedsColorGradientUpdate];
}

LTPropertyWithoutSetter(CGFloat, lightsSaturation, LightsSaturation, 0, 1, 0);
- (void)setLightsSaturation:(CGFloat)lightsSaturation {
  [self _verifyAndSetLightsSaturation:lightsSaturation];
  [self setNeedsColorGradientUpdate];
}

LTPropertyWithoutSetter(CGFloat, lightsHue, LightsHue, 0, 1, 2/3);
- (void)setLightsHue:(CGFloat)lightsHue {
  [self _verifyAndSetLightsHue:lightsHue];
  [self setNeedsColorGradientUpdate];
}

LTPropertyWithoutSetter(CGFloat, balance, Balance, -1, 1, 0);
- (void)setBalance:(CGFloat)balance {
  [self _verifyAndSetBalance:balance];
  [self setNeedsColorGradientUpdate];
}

static const CGFloat kBalanceScaling = 0.15;
static const CGFloat kBalanceShift = 0.15;
- (void)updateColorGradient {
  CGFloat split = 0.5 + self.balance * kBalanceScaling;
  CGFloat darksPosition = split - kBalanceShift;
  CGFloat lightsPosition = split + kBalanceShift;

  LTVector3 darkPoint =
      [self hslToRgb:LTVector3(self.darksHue, self.darksSaturation * 0.5, darksPosition)];
  LTVector3 lightPoint =
      [self hslToRgb:LTVector3(self.lightsHue, self.lightsSaturation * 0.5, lightsPosition)];
  LTVector3 whitePoint =
      [self hslToRgb:LTVector3(self.lightsHue, self.lightsSaturation * 0.5,
                               1.0 - self.lightsSaturation * 0.1)];
  LTColorGradientControlPoint *blacks =
      [[LTColorGradientControlPoint alloc] initWithPosition:0.0 color:LTVector3Zero];
  LTColorGradientControlPoint *darks =
      [[LTColorGradientControlPoint alloc] initWithPosition:darksPosition color:darkPoint];
  LTColorGradientControlPoint *lights =
      [[LTColorGradientControlPoint alloc] initWithPosition:lightsPosition color:lightPoint];
  LTColorGradientControlPoint *whites =
      [[LTColorGradientControlPoint alloc] initWithPosition:1.0 color:whitePoint];

  self.colorGradientTexture =
      [[[LTColorGradient alloc] initWithControlPoints:@[blacks, darks, lights, whites]]
       textureWithSamplingPoints:kLutSize];
  [self setAuxiliaryTexture:self.colorGradientTexture withName:[LTAdjustFsh colorGradientTexture]];
}

- (LTVector3)hslToRgb:(LTVector3)hsl {
  cv::Mat3f hlsMat(1, 1, cv::Vec3f(hsl.r() * 360, hsl.b(), hsl.g()));
  cv::Mat3f rgbMat(1, 1);
  cv::cvtColor(hlsMat, rgbMat, CV_HLS2RGB);
  cv::Vec3f color = rgbMat(0, 0);
  return LTVector3(color[0], color[1], color[2]);
}

#pragma mark -
#pragma mark LUTs
#pragma mark -

- (LTTexture *)detailsLUT {
  if (!_detailsLUT) {
    _detailsLUT = [LTTexture textureWithImage:[LTCurve identity]];
    [self setAuxiliaryTexture:_detailsLUT withName:[LTAdjustFsh detailsLUT]];
  }
  return _detailsLUT;
}

- (LTTexture *)colorGradientTexture {
  if (!_colorGradientTexture) {
    _colorGradientTexture = [[self defaultColorGradient] textureWithSamplingPoints:kLutSize];
    [self setAuxiliaryTexture:_colorGradientTexture withName:[LTAdjustFsh colorGradientTexture]];
  }
  return _colorGradientTexture;
}

- (void)updateDetailsLUT {
  cv::Mat1b shadowsCurve(1, kLutSize);
  if (self.shadows >= self.defaultShadows) {
    shadowsCurve = [LTCurve positiveShadows];
  } else {
    shadowsCurve = [LTCurve negativeShadows];
  }

  cv::Mat1b highlightsCurve(1, kLutSize);
  if (self.highlights >= self.defaultHighlights) {
    highlightsCurve = [LTCurve positiveHighlights];
  } else {
    highlightsCurve = [LTCurve negativeHighlights];
  }

  float shadows = std::abs(self.shadows);
  float highlights = std::abs(self.highlights);
  [self.detailsLUT mappedImageForWriting:^(cv::Mat *detailsCurve, BOOL) {
    cv::LUT((1.0 - self.fillLight) * [LTCurve identity] + self.fillLight * [LTCurve fillLight],
            (1.0 - shadows) * [LTCurve identity] + shadows * shadowsCurve, *detailsCurve);
    cv::LUT(*detailsCurve, (1.0 - highlights) * [LTCurve identity] + highlights * highlightsCurve,
            *detailsCurve);
  }];
}

// Update brightness, contrast, exposure and offset.
// Since these manipulations do not differ across RGB channels, they only require luminance update.
- (cv::Mat1b)applyTone {
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

  cv::Mat1b toneCurve(1, kLutSize);
  cv::LUT((1.0 - contrast) * [LTCurve identity] + contrast * contrastCurve,
          (1.0 - brightness) * [LTCurve identity] + brightness * brightnessCurve,
          toneCurve);
  
  toneCurve = toneCurve * std::pow(4.0, self.exposure) + self.offset * 255;

  return toneCurve;
}

- (void)updateToneLUT {
  cv::Mat1b toneCurve = [self applyTone];

  std::vector<cv::Mat1b> colorChannels(3);
  cv::LUT(toneCurve, self.redCurve, colorChannels[0]);
  cv::LUT(toneCurve, self.greenCurve, colorChannels[1]);
  cv::LUT(toneCurve, self.blueCurve, colorChannels[2]);
  
  // Apply grey (luminance) curve across the channels.
  std::vector<cv::Mat1b> channels(4);
  for (NSUInteger i = 0; i < 3; ++i) {
    cv::LUT(colorChannels[i], self.greyCurve, channels[i]);
  }
  channels[3] = cv::Mat1b(1, kLutSize, 255);

  LTTexture *target = self.shouldUseToneLUTTextureB ? self.toneLUTB : self.toneLUTA;
  [target mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
    cv::merge(channels, *mapped);
  }];
  [self setAuxiliaryTexture:target withName:[LTAdjustFsh toneLUT]];

  self.shouldUseToneLUTTextureB = !self.shouldUseToneLUTTextureB;
}

@end
