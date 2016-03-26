// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTBWTonalityProcessor.h"

#import "LTBilateralFilterProcessor.h"
#import "LTColorGradient.h"
#import "LTCurve.h"
#import "LTGLKitExtensions.h"
#import "LTGPUImageProcessor+Protected.h"
#import "LTOpenCVExtensions.h"
#import "LTProgram.h"
#import "LTShaderStorage+LTBWTonalityFsh.h"
#import "LTShaderStorage+LTPassthroughShaderVsh.h"
#import "LTTexture+Factory.h"

@interface LTBWTonalityProcessor ()

/// Texture that holds LUT that encapsulates brightess, contrast, exposure and structure.
@property (strong, nonatomic) LTTexture *toneLUT;

@end

@implementation LTBWTonalityProcessor

- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output {
  LTTexture *smoothTexture = [self createSmoothTexture:input];
  // Default color gradient.
  LTColorGradient *identityGradient = [LTColorGradient identityGradient];

  NSDictionary *auxiliaryTextures =
      @{[LTBWTonalityFsh smoothTexture]: smoothTexture,
        [LTBWTonalityFsh toneLUT]: [LTTexture textureWithImage:[LTCurve identity]],
        [LTBWTonalityFsh colorGradient]: [identityGradient textureWithSamplingPoints:256]};
  if (self = [super initWithVertexSource:[LTPassthroughShaderVsh source]
                          fragmentSource:[LTBWTonalityFsh source] sourceTexture:input
                       auxiliaryTextures:auxiliaryTextures
                               andOutput:output]) {
    [self setDefaultValues];
  }
  return self;
}

- (void)setDefaultValues {
  self.colorFilter = self.defaultColorFilter;
  self.brightness = self.defaultBrightness;
  self.contrast = self.defaultContrast;
  self.exposure = self.defaultExposure;
  self.structure = self.defaultStructure;
  self.offset = self.defaultOffset;
  _colorGradientTexture = self.auxiliaryTextures[[LTBWTonalityFsh colorGradient]];
}

- (LTTexture *)createSmoothTexture:(LTTexture *)input {
  static const CGFloat kSmoothDownsampleFactor = 4.0;
  
  CGFloat width = MAX(1.0, input.size.width / kSmoothDownsampleFactor);
  CGFloat height = MAX(1.0, input.size.height / kSmoothDownsampleFactor);

  CGSize size = std::floor(CGSizeMake(width, height));
  LTTexture *smoothTexture = [LTTexture byteRGBATextureWithSize:size];
  LTBilateralFilterProcessor *smoother = [[LTBilateralFilterProcessor alloc]
                                          initWithInput:input outputs:@[smoothTexture]];
  smoother.rangeSigma = 0.15;
  smoother.iterationsPerOutput = @[@5];
  [smoother process];
  
  return smoothTexture;
}

LTPropertyWithoutSetter(LTVector3, colorFilter, ColorFilter,
                        LTVector3::zeros(), LTVector3::ones(), LTVector3(0.299, 0.587, 0.114));
- (void)setColorFilter:(LTVector3)colorFilter {
  [self _verifyAndSetColorFilter:colorFilter];
  LTParameterAssert(colorFilter.sum(), @"Black is not a valid color filter");
  _colorFilter = colorFilter / colorFilter.sum();
  self[[LTBWTonalityFsh colorFilter]] = $(_colorFilter);
}

LTPropertyWithoutSetter(CGFloat, brightness, Brightness, -1, 1, 0);
- (void)setBrightness:(CGFloat)brightness {
  [self _verifyAndSetBrightness:brightness];
  [self updateToneLUT];
}

LTPropertyWithoutSetter(CGFloat, contrast, Contrast, -1, 1, 0);
- (void)setContrast:(CGFloat)contrast {
  [self _verifyAndSetContrast:contrast];
  [self updateToneLUT];
}

LTPropertyWithoutSetter(CGFloat, exposure, Exposure, -1, 1, 0);
- (void)setExposure:(CGFloat)exposure {
  [self _verifyAndSetExposure:exposure];
  [self updateToneLUT];
}

LTPropertyWithoutSetter(CGFloat, offset, Offset, -1, 1, 0);
- (void)setOffset:(CGFloat)offset {
  [self _verifyAndSetOffset:offset];
  [self updateToneLUT];
}

LTPropertyWithoutSetter(CGFloat, structure, Structure, -1, 1, 0);
- (void)setStructure:(CGFloat)structure {
  [self _verifyAndSetStructure:structure];
  // Remap [-1, 1] -> [0.25, 4].
  CGFloat remap = std::powf(4.0, structure);
  self[[LTBWTonalityFsh structure]] = @(remap);
}

- (void)setColorGradientTexture:(LTTexture *)colorGradientTexture {
  if (!colorGradientTexture) {
    _colorGradientTexture = [[LTColorGradient identityGradient] textureWithSamplingPoints:256];
  } else {
    LTParameterAssert(colorGradientTexture.size.height == 1,
                      @"colorGradientTexture height is not one");
    LTParameterAssert(colorGradientTexture.size.width <= 256,
                      @"colorGradientTexture width is larger than 256");

    _colorGradientTexture = colorGradientTexture;
  }
  
  [self setAuxiliaryTexture:colorGradientTexture withName:[LTBWTonalityFsh colorGradient]];
}

- (void)updateToneLUT {
  static const ushort kLutSize = 256;
  
  cv::Mat1b toneCurve(1, kLutSize);
  
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
  cv::LUT((1.0 - contrast) * [LTCurve identity] + contrast * contrastCurve,
          (1.0 - brightness) * [LTCurve identity] + brightness * brightnessCurve,
          toneCurve);
  
  toneCurve = toneCurve * std::pow(2.0, self.exposure) + self.offset * 255;
  [(LTTexture *)self.auxiliaryTextures[[LTBWTonalityFsh toneLUT]] load:toneCurve];
}

@end
