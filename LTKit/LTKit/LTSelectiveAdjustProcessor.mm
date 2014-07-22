// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTSelectiveAdjustProcessor.h"

#import "LTGPUImageProcessor+Protected.h"
#import "LTProgram.h"
#import "LTRGBToHSVProcessor.h"
#import "LTShaderStorage+LTPassthroughShaderVsh.h"
#import "LTShaderStorage+LTSelectiveAdjustFsh.h"
#import "LTTexture+Factory.h"

@implementation LTSelectiveAdjustProcessor

- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output {
  NSDictionary *auxiliaryTextures = [self prepareAuxiliaryTexturesForInput:input output:output];
  if (self = [super initWithProgram:[self createProgram] sourceTexture:input
                  auxiliaryTextures:auxiliaryTextures andOutput:output]) {
    [self setDefaultValues];
  }
  return self;
}

- (LTProgram *)createProgram {
  return [[LTProgram alloc] initWithVertexSource:[LTPassthroughShaderVsh source]
                                  fragmentSource:[LTSelectiveAdjustFsh source]];
}

- (NSDictionary *)prepareAuxiliaryTexturesForInput:(LTTexture *)input output:(LTTexture *)output {
  LTTexture *hsv = [LTTexture textureWithPropertiesOf:output];
  LTRGBToHSVProcessor *processor = [[LTRGBToHSVProcessor alloc] initWithInput:input output:hsv];
  [processor process];
  
  NSDictionary *auxiliaryTextures = @{[LTSelectiveAdjustFsh hsvTexture]: hsv};
  return auxiliaryTextures;
}

- (void)setDefaultValues {
  self.redSaturation = self.defaultRedSaturation;
  self.redLuminance = self.defaultRedLuminance;
  
  self.orangeSaturation = self.defaultOrangeSaturation;
  self.orangeLuminance = self.defaultOrangeLuminance;
  
  self.yellowSaturation = self.defaultYellowSaturation;
  self.yellowLuminance = self.defaultYellowLuminance;
  
  self.greenSaturation = self.defaultGreenSaturation;
  self.greenLuminance = self.defaultGreenLuminance;
  
  self.cyanSaturation = self.defaultCyanSaturation;
  self.cyanLuminance = self.defaultCyanLuminance;
  
  self.blueSaturation = self.defaultBlueSaturation;
  self.blueLuminance = self.defaultBlueLuminance;
}

#pragma mark -
#pragma mark Properties
#pragma mark -

static const CGFloat kSaturationScaling = 1.5;
static const CGFloat kLuminanceExponentBase = 2.0;

// Remap [-1, 0] -> [0, 1] and [0, 1] to [1, kSaturationScaling].
- (CGFloat)remapSaturation:(CGFloat)saturation {
  return saturation < 0 ? saturation + 1 : 1 + saturation * kSaturationScaling;
}

- (CGFloat)remapLuminance:(CGFloat)luminance {
  return std::pow(kLuminanceExponentBase, luminance);
}

LTPropertyWithoutSetter(CGFloat, redSaturation, RedSaturation, -1, 1, 0);
- (void)setRedSaturation:(CGFloat)redSaturation {
  [self _verifyAndSetRedSaturation:redSaturation];
  self[[LTSelectiveAdjustFsh redSaturation]] = @([self remapSaturation:redSaturation]);
}

LTPropertyWithoutSetter(CGFloat, redLuminance, RedLuminance, -1, 1, 0);
- (void)setRedLuminance:(CGFloat)redLuminance {
  [self _verifyAndSetRedLuminance:redLuminance];
  self[[LTSelectiveAdjustFsh redLuminance]] = @([self remapLuminance:redLuminance]);
}

LTPropertyWithoutSetter(CGFloat, orangeSaturation, OrangeSaturation, -1, 1, 0);
- (void)setOrangeSaturation:(CGFloat)orangeSaturation {
  [self _verifyAndSetOrangeSaturation:orangeSaturation];
  self[[LTSelectiveAdjustFsh orangeSaturation]] = @([self remapSaturation:orangeSaturation]);
}

LTPropertyWithoutSetter(CGFloat, orangeLuminance, OrangeLuminance, -1, 1, 0);
- (void)setOrangeLuminance:(CGFloat)orangeLuminance {
  [self _verifyAndSetOrangeLuminance:orangeLuminance];
  self[[LTSelectiveAdjustFsh orangeLuminance]] = @([self remapLuminance:orangeLuminance]);
}

LTPropertyWithoutSetter(CGFloat, yellowSaturation, YellowSaturation, -1, 1, 0);
- (void)setYellowSaturation:(CGFloat)yellowSaturation {
  [self _verifyAndSetYellowSaturation:yellowSaturation];
  self[[LTSelectiveAdjustFsh yellowSaturation]] = @([self remapSaturation:yellowSaturation]);
}

LTPropertyWithoutSetter(CGFloat, yellowLuminance, YellowLuminance, -1, 1, 0);
- (void)setYellowLuminance:(CGFloat)yellowLuminance {
  [self _verifyAndSetYellowLuminance:yellowLuminance];
  self[[LTSelectiveAdjustFsh yellowLuminance]] = @([self remapLuminance:yellowLuminance]);
}

LTPropertyWithoutSetter(CGFloat, greenSaturation, GreenSaturation, -1, 1, 0);
- (void)setGreenSaturation:(CGFloat)greenSaturation {
  [self _verifyAndSetGreenSaturation:greenSaturation];
  self[[LTSelectiveAdjustFsh greenSaturation]] = @([self remapSaturation:greenSaturation]);
}

LTPropertyWithoutSetter(CGFloat, greenLuminance, GreenLuminance, -1, 1, 0);
- (void)setGreenLuminance:(CGFloat)greenLuminance {
  [self _verifyAndSetGreenLuminance:greenLuminance];
  self[[LTSelectiveAdjustFsh greenLuminance]] = @([self remapLuminance:greenLuminance]);
}

LTPropertyWithoutSetter(CGFloat, cyanSaturation, CyanSaturation, -1, 1, 0);
- (void)setCyanSaturation:(CGFloat)cyanSaturation {
  [self _verifyAndSetCyanSaturation:cyanSaturation];
  self[[LTSelectiveAdjustFsh cyanSaturation]] = @([self remapSaturation:cyanSaturation]);
}

LTPropertyWithoutSetter(CGFloat, cyanLuminance, CyanLuminance, -1, 1, 0);
- (void)setCyanLuminance:(CGFloat)cyanLuminance {
  [self _verifyAndSetCyanLuminance:cyanLuminance];
  self[[LTSelectiveAdjustFsh cyanLuminance]] = @([self remapLuminance:cyanLuminance]);
}

LTPropertyWithoutSetter(CGFloat, blueSaturation, BlueSaturation, -1, 1, 0);
- (void)setBlueSaturation:(CGFloat)blueSaturation {
  [self _verifyAndSetBlueSaturation:blueSaturation];
  self[[LTSelectiveAdjustFsh blueSaturation]] = @([self remapSaturation:blueSaturation]);
}

LTPropertyWithoutSetter(CGFloat, blueLuminance, BlueLuminance, -1, 1, 0);
- (void)setBlueLuminance:(CGFloat)blueLuminance {
  [self _verifyAndSetBlueLuminance:blueLuminance];
  self[[LTSelectiveAdjustFsh blueLuminance]] = @([self remapLuminance:blueLuminance]);
}

@end
