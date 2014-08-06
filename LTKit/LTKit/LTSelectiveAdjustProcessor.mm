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
  self.redSaturation = self.defaultRedSaturation;
  
  self.orangeSaturation = self.defaultOrangeSaturation;
  self.orangeLuminance = self.defaultOrangeLuminance;
  self.orangeSaturation = self.defaultOrangeSaturation;
  
  self.yellowSaturation = self.defaultYellowSaturation;
  self.yellowLuminance = self.defaultYellowLuminance;
  self.yellowSaturation = self.defaultYellowSaturation;
  
  self.greenSaturation = self.defaultGreenSaturation;
  self.greenLuminance = self.defaultGreenLuminance;
  self.greenSaturation = self.defaultGreenSaturation;
  
  self.cyanSaturation = self.defaultCyanSaturation;
  self.cyanLuminance = self.defaultCyanLuminance;
  self.cyanSaturation = self.defaultCyanSaturation;
  
  self.blueSaturation = self.defaultBlueSaturation;
  self.blueLuminance = self.defaultBlueLuminance;
  self.blueSaturation = self.defaultBlueSaturation;
}

#pragma mark -
#pragma mark Properties
#pragma mark -

static const CGFloat kHueScaling = 0.25;
static const CGFloat kSaturationScaling = 1.5;
static const CGFloat kLuminanceExponentBase = 1.5;

/// Scale the incoming [-1, 1] values by quarter, so each direction allows 90 degrees adjustment.
- (CGFloat)remapHue:(CGFloat)hue {
  return hue * kHueScaling;
}

/// Remap [-1, 0] -> [0, 1] and [0, 1] to [1, kSaturationScaling].
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

LTPropertyWithoutSetter(CGFloat, redHue, RedHue, -1, 1, 0);
- (void)setRedHue:(CGFloat)redHue {
  [self _verifyAndSetRedHue:redHue];
  self[[LTSelectiveAdjustFsh redHue]] = @([self remapHue:redHue]);
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

LTPropertyWithoutSetter(CGFloat, orangeHue, OrangeHue, -1, 1, 0);
- (void)setOrangeHue:(CGFloat)orangeHue {
  [self _verifyAndSetRedHue:orangeHue];
  self[[LTSelectiveAdjustFsh orangeHue]] = @([self remapHue:orangeHue]);
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

LTPropertyWithoutSetter(CGFloat, yellowHue, YellowHue, -1, 1, 0);
- (void)setYellowHue:(CGFloat)yellowHue {
  [self _verifyAndSetYellowHue:yellowHue];
  self[[LTSelectiveAdjustFsh yellowHue]] = @([self remapHue:yellowHue]);
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

LTPropertyWithoutSetter(CGFloat, greenHue, GreenHue, -1, 1, 0);
- (void)setGreenHue:(CGFloat)greenHue {
  [self _verifyAndSetGreenHue:greenHue];
  self[[LTSelectiveAdjustFsh greenHue]] = @([self remapHue:greenHue]);
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

LTPropertyWithoutSetter(CGFloat, cyanHue, CyanHue, -1, 1, 0);
- (void)setCyanHue:(CGFloat)cyanHue {
  [self _verifyAndSetCyanHue:cyanHue];
  self[[LTSelectiveAdjustFsh cyanHue]] = @([self remapHue:cyanHue]);
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

LTPropertyWithoutSetter(CGFloat, blueHue, BlueHue, -1, 1, 0);
- (void)setBlueHue:(CGFloat)blueHue {
  [self _verifyAndSetBlueHue:blueHue];
  self[[LTSelectiveAdjustFsh blueHue]] = @([self remapHue:blueHue]);
}

@end
