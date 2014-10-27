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
}

- (void)setDefaultValues {
  self.rangeColor = self.defaultRangeColor;
  self.fuzziness = self.defaultFuzziness;
  self.hue = self.defaultHue;
  self.saturation = self.defaultSaturation;
  self.exposure = self.defaultExposure;
  self.contrast = self.defaultContrast;
  self.renderingMode = LTColorRangeRenderingModeImage;
}

#pragma mark -
#pragma mark Dual Mask
#pragma mark -

- (void)setMaskType:(LTDualMaskType)maskType {
  self.dualMaskProcessor.maskType = maskType;
  self.needsDualMaskProcessing = YES;
}

- (LTDualMaskType)maskType {
  return self.dualMaskProcessor.maskType;
}

- (void)setCenter:(LTVector2)center {
  LTParameterAssert(center.x >= 0 && center.y >= 0 && center.x < self.inputSize.width &&
                    center.y < self.inputSize.height,
                    @"Center should be inside the bounds of the input texture");
  self.dualMaskProcessor.center = center / kMaskDownscalingFactor;
  self.needsDualMaskProcessing = YES;
  self.rangeColor = [self.inputTexture pixelValue:(CGPoint)center].rgb();
}

- (LTVector2)center {
  return self.dualMaskProcessor.center * kMaskDownscalingFactor;
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

#pragma mark -
#pragma mark Properties
#pragma mark -

LTPropertyWithoutSetter(LTVector3, rangeColor, RangeColor, LTVector3(-1), LTVector3(1),
                        LTVector3(0, 1, 0));
- (void)setRangeColor:(LTVector3)rangeColor {
  [self _verifyAndSetRangeColor:rangeColor];
  self[[LTColorRangeAdjustFsh rangeColor]] = $(rangeColor);
}

static const CGFloat kDefaultEdge0 = 0.75;
static const CGFloat kEdge0Step = 0.35;

LTPropertyWithoutSetter(CGFloat, fuzziness, Fuzziness, -1, 1, 0);
- (void)setFuzziness:(CGFloat)fuzziness {
  [self _verifyAndSetFuzziness:fuzziness];
  self[[LTColorRangeAdjustFsh edge0]] = @(kDefaultEdge0 + kEdge0Step * fuzziness);
}

LTPropertyWithoutSetter(CGFloat, hue, Hue, -1, 1, 0);
- (void)setHue:(CGFloat)hue {
  [self _verifyAndSetHue:hue];
  self[[LTColorRangeAdjustFsh rotation]] = $([self hueToRotation:hue]);
}

LTPropertyWithoutSetter(CGFloat, saturation, Saturation, -1, 1, 0);
- (void)setSaturation:(CGFloat)saturation {
  [self _verifyAndSetSaturation:saturation];
  self[[LTColorRangeAdjustFsh saturation]] = @([self remapSaturation:saturation]);
}

LTPropertyWithoutSetter(CGFloat, exposure, Exposure, -1, 1, 0);
- (void)setExposure:(CGFloat)exposure {
  [self _verifyAndSetExposure:exposure];
  self[[LTColorRangeAdjustFsh exposure]] = @([self remapExposure:exposure]);
}

LTPropertyWithoutSetter(CGFloat, contrast, Contrast, -1, 1, 0);
- (void)setContrast:(CGFloat)contrast {
  [self _verifyAndSetContrast:contrast];
  self[[LTColorRangeAdjustFsh contrast]] = @([self remapContrast:contrast]);
}

static const CGFloat kSaturationScaling = 1.5;
static const CGFloat kContrastScaling = 2.0;
static const CGFloat kExposureBase = 4.0;

/// Scale the incoming [-1, 1] values by quarter, so each direction allows 180 degrees adjustment.
- (GLKMatrix2)hueToRotation:(CGFloat)hue {
  CGFloat theta = hue * M_PI_2;
  return GLKMatrix2Make(cos(theta), sin(theta), -sin(theta), cos(theta));
}

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
