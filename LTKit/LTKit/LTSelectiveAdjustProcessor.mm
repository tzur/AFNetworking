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
static const CGFloat kLuminanceExponentBase = 1.5;

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

@end
