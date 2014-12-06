// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTColorRangeAdjustProcessor.h"

#import "LTGLKitExtensions.h"
#import "LTGPUImageProcessor+Protected.h"
#import "LTProgram.h"
#import "LTShaderStorage+LTPassthroughShaderVsh.h"
#import "LTShaderStorage+LTColorRangeAdjustFsh.h"
#import "LTTexture+Factory.h"

@interface LTColorRangeAdjustProcessor ()

/// \c YES if dual mask needs processing prior to executing this processor.
@property (nonatomic) BOOL needsDualMaskProcessing;

/// Internal dual mask processor.
@property (strong, nonatomic) LTDualMaskProcessor *dualMaskProcessor;

/// Color that is used to construct a mask that defines a color range upon which tonal manipulation
/// is applied. Components should be in [-1, 1] range. Default value is green (0, 1, 0).
@property (nonatomic) LTVector3 rangeColor;
LTPropertyDeclare(LTVector3, rangeColor, RangeColor);

/// If \c YES, tonal transform update should run at the next processing round of this processor.
@property (nonatomic) BOOL shouldUpdateTonalTransform;

@end

@implementation LTColorRangeAdjustProcessor

static const CGFloat kMaskDownscalingFactor = 4;

- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output {
  // Setup dual mask.
  CGSize maskSize = std::ceil(output.size / kMaskDownscalingFactor);
  LTTexture *dualMaskTexture = [LTTexture byteRedTextureWithSize:maskSize];
  self.dualMaskProcessor = [[LTDualMaskProcessor alloc] initWithOutput:dualMaskTexture];

  if (self = [super initWithVertexSource:[LTPassthroughShaderVsh source]
                          fragmentSource:[LTColorRangeAdjustFsh source] sourceTexture:input
                       auxiliaryTextures:@{[LTColorRangeAdjustFsh dualMaskTexture]: dualMaskTexture}
                               andOutput:output]) {
    [self setDefaultValues];
  }
  return self;
}

- (void)preprocess {
  [super preprocess];

  if (self.needsDualMaskProcessing) {
    [self.dualMaskProcessor process];
    self.needsDualMaskProcessing = NO;
  }
  if (self.shouldUpdateTonalTransform) {
    [self updateTonalTransform];
    self.shouldUpdateTonalTransform = NO;
  }
}

- (void)setNeedsTonalTransformUpdate {
  self.shouldUpdateTonalTransform = YES;
}

- (void)setDefaultValues {
  self.rangeColor = self.defaultRangeColor;
  self.fuzziness = self.defaultFuzziness;
  self.hue = self.defaultHue;
  self.saturation = self.defaultSaturation;
  self.exposure = self.defaultExposure;
  self.contrast = self.defaultContrast;
  self.renderingMode = LTColorRangeRenderingModeImage;
  self.maskColor = self.defaultMaskColor;
}

#pragma mark -
#pragma mark Mask
#pragma mark -

- (void)setMaskType:(LTDualMaskType)maskType {
  self.dualMaskProcessor.maskType = maskType;
  self.needsDualMaskProcessing = YES;
}

- (LTDualMaskType)maskType {
  return self.dualMaskProcessor.maskType;
}

- (void)setCenter:(LTVector2)center {
  if (center.isNull()) {
    _center = center;
    return;
  }
  LTParameterAssert(center.x >= 0 && center.y >= 0 && center.x < self.inputSize.width &&
                    center.y < self.inputSize.height,
                    @"Center should be inside the bounds of the input texture");
  _center = center;
  self.dualMaskProcessor.center = center / kMaskDownscalingFactor;
  self.needsDualMaskProcessing = YES;
  self.rangeColor = [self.inputTexture pixelValue:(CGPoint)center].rgb();
}

- (void)setDiameter:(CGFloat)diameter {
  self.dualMaskProcessor.diameter = diameter / kMaskDownscalingFactor;
  self.needsDualMaskProcessing = YES;
}

- (CGFloat)diameter {
  return self.dualMaskProcessor.diameter * kMaskDownscalingFactor;
}

LTPropertyWithoutSetter(CGFloat, spread, Spread, -1, 1, 0);
- (void)setSpread:(CGFloat)spread {
  [self _verifyAndSetSpread:spread];
  self.dualMaskProcessor.spread = spread;
  self.needsDualMaskProcessing = YES;
}

- (void)setAngle:(CGFloat)angle {
  self.dualMaskProcessor.angle = angle;
  self.needsDualMaskProcessing = YES;
}

- (CGFloat)angle {
  return self.dualMaskProcessor.angle;
}

LTPropertyWithoutSetter(LTVector3, rangeColor, RangeColor, LTVector3Zero, LTVector3One,
                        LTVector3(1, 0, 0));
- (void)setRangeColor:(LTVector3)rangeColor {
  [self _verifyAndSetRangeColor:rangeColor];
  self[[LTColorRangeAdjustFsh rangeColor]] = $(rangeColor);
  [self updateTonalTransform];
}

static const CGFloat kDefaultEdge0 = 1.0;
static const CGFloat kEdge0Step = 0.35;

LTPropertyWithoutSetter(CGFloat, fuzziness, Fuzziness, -1, 1, 0);
- (void)setFuzziness:(CGFloat)fuzziness {
  [self _verifyAndSetFuzziness:fuzziness];
  self[[LTColorRangeAdjustFsh edge0]] = @(kDefaultEdge0 + kEdge0Step * fuzziness);
}

LTPropertyWithoutSetter(LTVector3, maskColor, MaskColor, LTVector3Zero, LTVector3One,
                        LTVector3(1, 0, 0));
- (void)setMaskColor:(LTVector3)maskColor {
  [self _verifyAndSetMaskColor:maskColor];
  self[[LTColorRangeAdjustFsh maskColor]] = $(maskColor);
}

#pragma mark -
#pragma mark Tone
#pragma mark -

LTPropertyWithoutSetter(CGFloat, hue, Hue, -1, 1, 0);
- (void)setHue:(CGFloat)hue {
  [self _verifyAndSetHue:hue];
  [self setNeedsTonalTransformUpdate];
}

LTPropertyWithoutSetter(CGFloat, saturation, Saturation, -1, 1, 0);
- (void)setSaturation:(CGFloat)saturation {
  [self _verifyAndSetSaturation:saturation];
  [self setNeedsTonalTransformUpdate];
}

LTPropertyWithoutSetter(CGFloat, exposure, Exposure, -1, 1, 0);
- (void)setExposure:(CGFloat)exposure {
  [self _verifyAndSetExposure:exposure];
  [self setNeedsTonalTransformUpdate];
}

LTPropertyWithoutSetter(CGFloat, contrast, Contrast, -1, 1, 0);
- (void)setContrast:(CGFloat)contrast {
  [self _verifyAndSetContrast:contrast];
  [self setNeedsTonalTransformUpdate];
}

/// This method passes to the shader a 4x4 matrix that encapsulated the following tonal adjustments:
/// Hue, saturation, exposure and contrast.
/// Using the formalism of the affine transformations, conversion to and from YIQ color space is
/// a rotation. Saturation is a scaling of y and z axis. Hue is a rotation around x axis. Contrast
/// is scaling and translation of x axis. Exposure is formulated as scaling in RGB color space.
- (void)updateTonalTransform {
  static const GLKMatrix4 kRGBtoYIQ = GLKMatrix4Make(0.299, 0.596, 0.212, 0,
                                                     0.587, -0.274, -0.523, 0,
                                                     0.114, -0.322, 0.311, 0,
                                                     0, 0, 0, 1);
  static const GLKMatrix4 kYIQtoRGB = GLKMatrix4Make(1, 1, 1, 0,
                                                     0.9563, -0.2721, -1.107, 0,
                                                     0.621, -0.6474, 1.7046, 0,
                                                     0, 0, 0, 1);

  GLKMatrix4 saturation = GLKMatrix4Identity;
  saturation.m11 = [self remapSaturation:self.saturation];
  saturation.m22 = [self remapSaturation:self.saturation];

  GLKMatrix4 hue = GLKMatrix4MakeXRotation(self.hue * M_PI);

  GLKMatrix4 exposure = GLKMatrix4Identity;
  exposure.m00 = [self remapExposure:self.exposure];
  exposure.m11 = [self remapExposure:self.exposure];
  exposure.m22 = [self remapExposure:self.exposure];

  GLKMatrix4 contrast = GLKMatrix4Identity;
  CGFloat remappedContrast = [self remapContrast:self.contrast];
  contrast.m00 = remappedContrast;
  static const LTVector3 kYPrime = LTVector3(0.299, 0.587, 0.114);
  // Shader uses cheap square linearization, pivot should undergo the same transformation.
  contrast.m30 = (1 - remappedContrast) * kYPrime.dot(self.rangeColor * self.rangeColor);

  GLKMatrix4 tonalTranform = GLKMatrix4Multiply(saturation, kRGBtoYIQ);
  tonalTranform = GLKMatrix4Multiply(hue, tonalTranform);
  tonalTranform = GLKMatrix4Multiply(contrast, tonalTranform);
  tonalTranform = GLKMatrix4Multiply(kYIQtoRGB, tonalTranform);
  tonalTranform = GLKMatrix4Multiply(exposure, tonalTranform);

  self[[LTColorRangeAdjustFsh tonalTransform]] = $(tonalTranform);
}

static const CGFloat kSaturationScaling = 1.5;
static const CGFloat kContrastScaling = 2.5;
static const CGFloat kExposureBase = 6.0;

/// Remap [-1, 0] -> [0, 1] and [0, 1] to [1, kSaturationScaling].
- (CGFloat)remapSaturation:(CGFloat)saturation {
  return saturation < 0 ? saturation + 1 : 1 + saturation * kSaturationScaling;
}

/// Remap [-1, 0] -> [0, 1] and [0, 1] to [1, kSaturationScaling].
- (CGFloat)remapContrast:(CGFloat)contrast {
  return contrast < 0 ? contrast + 1 : 1 + contrast * kContrastScaling;
}

- (CGFloat)remapExposure:(CGFloat)exposure {
  return std::pow(kExposureBase, exposure);
}

- (void)setRenderingMode:(LTColorRangeRenderingMode)renderingMode {
  _renderingMode = renderingMode;
  self[[LTColorRangeAdjustFsh mode]] = @(renderingMode);
}

@end
