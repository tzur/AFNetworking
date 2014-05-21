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

LTPropertyWithSetter(CGFloat, redSaturation, RedSaturation, -1, 1, 0, ^{
  self[[LTSelectiveAdjustFsh redSaturation]] = @([self remapSaturation:redSaturation]);
});

LTPropertyWithSetter(CGFloat, redLuminance, RedLuminance, -1, 1, 0, ^{
  self[[LTSelectiveAdjustFsh redLuminance]] = @([self remapLuminance:redLuminance]);
});

LTPropertyWithSetter(CGFloat, orangeSaturation, OrangeSaturation, -1, 1, 0, ^{
  self[[LTSelectiveAdjustFsh orangeSaturation]] = @([self remapSaturation:orangeSaturation]);
});

LTPropertyWithSetter(CGFloat, orangeLuminance, OrangeLuminance, -1, 1, 0, ^{
  self[[LTSelectiveAdjustFsh orangeLuminance]] = @([self remapLuminance:orangeLuminance]);
});

LTPropertyWithSetter(CGFloat, yellowSaturation, YellowSaturation, -1, 1, 0, ^{
  self[[LTSelectiveAdjustFsh yellowSaturation]] = @([self remapSaturation:yellowSaturation]);
});

LTPropertyWithSetter(CGFloat, yellowLuminance, YellowLuminance, -1, 1, 0, ^{
  self[[LTSelectiveAdjustFsh yellowLuminance]] = @([self remapLuminance:yellowLuminance]);
});

LTPropertyWithSetter(CGFloat, greenSaturation, GreenSaturation, -1, 1, 0, ^{
  self[[LTSelectiveAdjustFsh greenSaturation]] = @([self remapSaturation:greenSaturation]);
});

LTPropertyWithSetter(CGFloat, greenLuminance, GreenLuminance, -1, 1, 0, ^{
  self[[LTSelectiveAdjustFsh greenLuminance]] = @([self remapLuminance:greenLuminance]);
});

LTPropertyWithSetter(CGFloat, cyanSaturation, CyanSaturation, -1, 1, 0, ^{
  self[[LTSelectiveAdjustFsh cyanSaturation]] = @([self remapSaturation:cyanSaturation]);
});

LTPropertyWithSetter(CGFloat, cyanLuminance, CyanLuminance, -1, 1, 0, ^{
  self[[LTSelectiveAdjustFsh cyanLuminance]] = @([self remapLuminance:cyanLuminance]);
});

LTPropertyWithSetter(CGFloat, blueSaturation, BlueSaturation, -1, 1, 0, ^{
  self[[LTSelectiveAdjustFsh blueSaturation]] = @([self remapSaturation:blueSaturation]);
});

LTPropertyWithSetter(CGFloat, blueLuminance, BlueLuminance, -1, 1, 0, ^{
  self[[LTSelectiveAdjustFsh blueLuminance]] = @([self remapLuminance:blueLuminance]);
});

@end
