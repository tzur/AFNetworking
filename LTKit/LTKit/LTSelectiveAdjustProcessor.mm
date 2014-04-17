// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTSelectiveAdjustProcessor.h"

#import "LTProgram.h"
#import "LTRGBToHSVProcessor.h"
#import "LTShaderStorage+LTPassthroughShaderVsh.h"
#import "LTShaderStorage+LTSelectiveAdjustFsh.h"
#import "LTTexture+Factory.h"

@implementation LTSelectiveAdjustProcessor

static const CGFloat kSaturationScaling = 1.5;
static const CGFloat kLuminanceExponentBase = 2.0;

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

LTBoundedPrimitivePropertyImplementWithCustomSetter(CGFloat, redSaturation, RedSaturation,
    -1, 1, 0, ^{
  // Remap [-1, 0] -> [0, 1] and [0, 1] to [1, kSaturationScaling].
  CGFloat remap = redSaturation < 0 ? redSaturation + 1 : 1 + redSaturation * kSaturationScaling;
  self[[LTSelectiveAdjustFsh redSaturation]] = @(remap);
});

LTBoundedPrimitivePropertyImplementWithCustomSetter(CGFloat, redLuminance, RedLuminance,
    -1, 1, 0, ^{
  CGFloat remap = std::pow(kLuminanceExponentBase, redLuminance);
  self[[LTSelectiveAdjustFsh redLuminance]] = @(remap);
});

LTBoundedPrimitivePropertyImplementWithCustomSetter(CGFloat, orangeSaturation, OrangeSaturation,
    -1, 1, 0, ^{
  // Remap [-1, 0] -> [0, 1] and [0, 1] to [1, kSaturationScaling].
  CGFloat remap = orangeSaturation < 0 ? orangeSaturation + 1 :
      1 + orangeSaturation * kSaturationScaling;
  self[[LTSelectiveAdjustFsh orangeSaturation]] = @(remap);
});

LTBoundedPrimitivePropertyImplementWithCustomSetter(CGFloat, orangeLuminance, OrangeLuminance,
    -1, 1, 0, ^{
  CGFloat remap = std::pow(kLuminanceExponentBase, orangeLuminance);
  self[[LTSelectiveAdjustFsh orangeLuminance]] = @(remap);
});

LTBoundedPrimitivePropertyImplementWithCustomSetter(CGFloat, yellowSaturation, YellowSaturation,
    -1, 1, 0, ^{
  // Remap [-1, 0] -> [0, 1] and [0, 1] to [1, kSaturationScaling].
  CGFloat remap = yellowSaturation < 0 ? yellowSaturation + 1 :
      1 + yellowSaturation * kSaturationScaling;
  self[[LTSelectiveAdjustFsh yellowSaturation]] = @(remap);
});

LTBoundedPrimitivePropertyImplementWithCustomSetter(CGFloat, yellowLuminance, YellowLuminance,
    -1, 1, 0, ^{
  CGFloat remap = std::pow(kLuminanceExponentBase, yellowLuminance);
  self[[LTSelectiveAdjustFsh yellowLuminance]] = @(remap);
});

LTBoundedPrimitivePropertyImplementWithCustomSetter(CGFloat, greenSaturation, GreenSaturation,
    -1, 1, 0, ^{
  // Remap [-1, 0] -> [0, 1] and [0, 1] to [1, kSaturationScaling].
  CGFloat remap = greenSaturation < 0 ? greenSaturation + 1 :
      1 + greenSaturation * kSaturationScaling;
  self[[LTSelectiveAdjustFsh greenSaturation]] = @(remap);
});

LTBoundedPrimitivePropertyImplementWithCustomSetter(CGFloat, greenLuminance, GreenLuminance,
    -1, 1, 0, ^{
  CGFloat remap = std::pow(kLuminanceExponentBase, greenLuminance);
  self[[LTSelectiveAdjustFsh greenLuminance]] = @(remap);
});

LTBoundedPrimitivePropertyImplementWithCustomSetter(CGFloat, cyanSaturation, CyanSaturation,
    -1, 1, 0, ^{
  // Remap [-1, 0] -> [0, 1] and [0, 1] to [1, kSaturationScaling].
  CGFloat remap = cyanSaturation < 0 ? cyanSaturation + 1 :
      1 + cyanSaturation * kSaturationScaling;
  self[[LTSelectiveAdjustFsh cyanSaturation]] = @(remap);
});

LTBoundedPrimitivePropertyImplementWithCustomSetter(CGFloat, cyanLuminance, CyanLuminance,
    -1, 1, 0, ^{
  CGFloat remap = std::pow(kLuminanceExponentBase, cyanLuminance);
  self[[LTSelectiveAdjustFsh cyanLuminance]] = @(remap);
});

LTBoundedPrimitivePropertyImplementWithCustomSetter(CGFloat, blueSaturation, BlueSaturation,
    -1, 1, 0, ^{
  // Remap [-1, 0] -> [0, 1] and [0, 1] to [1, kSaturationScaling].
  CGFloat remap = blueSaturation < 0 ? blueSaturation + 1 :
      1 + blueSaturation * kSaturationScaling;
  self[[LTSelectiveAdjustFsh blueSaturation]] = @(remap);
});

LTBoundedPrimitivePropertyImplementWithCustomSetter(CGFloat, blueLuminance, BlueLuminance,
    -1, 1, 0, ^{
  CGFloat remap = std::pow(kLuminanceExponentBase, blueLuminance);
  self[[LTSelectiveAdjustFsh blueLuminance]] = @(remap);
});

@end
