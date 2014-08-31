// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTColorRangeAdjustProcessor.h"

#import "LTGLKitExtensions.h"
#import "LTGPUImageProcessor+Protected.h"
#import "LTProgram.h"
#import "LTShaderStorage+LTPassthroughShaderVsh.h"
#import "LTShaderStorage+LTColorRangeAdjustFsh.h"
#import "LTTexture+Factory.h"

@implementation LTColorRangeAdjustProcessor

- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output {
  if (self = [super initWithVertexSource:[LTPassthroughShaderVsh source]
                          fragmentSource:[LTColorRangeAdjustFsh source]
                                   input:input andOutput:output]) {
    [self setDefaultValues];
  }
  return self;
}

- (void)setDefaultValues {
  self.rangeColor = self.defaultRangeColor;
  self.fuzziness = self.defaultFuzziness;
  self.hue = self.defaultHue;
  self.saturation = self.defaultSaturation;
  self.luminance = self.defaultLuminance;
  self.renderingMode = LTColorRangeRenderingModeImage;
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

static const CGFloat kDefaultEdge0 = 0.5;
static const CGFloat kDefaultEdge1 = 0.05;
static const CGFloat kEdge0Step = 0.4;
static const CGFloat kEdge1Step = 0.05;

LTPropertyWithoutSetter(CGFloat, fuzziness, Fuzziness, -1, 1, 0);
- (void)setFuzziness:(CGFloat)fuzziness {
  [self _verifyAndSetFuzziness:fuzziness];
  self[[LTColorRangeAdjustFsh edge0]] = @(kDefaultEdge0 + kEdge0Step * fuzziness);
  self[[LTColorRangeAdjustFsh edge1]] = @(kDefaultEdge1 + kEdge1Step * fuzziness);
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

LTPropertyWithoutSetter(CGFloat, luminance, Luminance, -1, 1, 0);
- (void)setLuminance:(CGFloat)luminance {
  [self _verifyAndSetLuminance:luminance];
  self[[LTColorRangeAdjustFsh luminance]] = @([self remapLuminance:luminance]);
}

static const CGFloat kSaturationScaling = 1.5;
static const CGFloat kLuminanceScaling = 0.75;

/// Scale the incoming [-1, 1] values by quarter, so each direction allows 180 degrees adjustment.
- (GLKMatrix2)hueToRotation:(CGFloat)hue {
  CGFloat theta = hue * M_PI_2;
  return GLKMatrix2Make(cos(theta), sin(theta), -sin(theta), cos(theta));
}

/// Remap [-1, 0] -> [0, 1] and [0, 1] to [1, kSaturationScaling].
- (CGFloat)remapSaturation:(CGFloat)saturation {
  return saturation < 0 ? saturation + 1 : 1 + saturation * kSaturationScaling;
}

- (CGFloat)remapLuminance:(CGFloat)luminance {
  return luminance * kLuminanceScaling;
}

- (void)setRenderingMode:(LTColorRangeRenderingMode)renderingMode {
  _renderingMode = renderingMode;
  self[[LTColorRangeAdjustFsh mode]] = @(renderingMode);
}

@end
