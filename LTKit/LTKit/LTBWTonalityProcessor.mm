// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTBWTonalityProcessor.h"

#import "LTBilateralFilterProcessor.h"
#import "LTCGExtensions.h"
#import "LTColorGradient.h"
#import "LTGLKitExtensions.h"
#import "LTOpenCVExtensions.h"
#import "LTProgram.h"
#import "LTShaderStorage+LTBWTonalityFsh.h"
#import "LTShaderStorage+LTPassthroughShaderVsh.h"
#import "LTTexture+Factory.h"
#import "NSBundle+LTKitBundle.h"

@interface LTGPUImageProcessor ()
@property (strong, nonatomic) NSDictionary *auxiliaryTextures;
@end

@interface LTBWTonalityProcessor ()
// Texture that holds LUT that encapsulates brightess, contrast, exposure and structure.
@property (strong, nonatomic) LTTexture *toneLUT;
@end

@implementation LTBWTonalityProcessor

// The follow matrices hold the curves data.
static cv::Mat1b kIdentityCurve;
static cv::Mat1b kPositiveBrightnessCurve;
static cv::Mat1b kNegativeBrightnessCurve;
static cv::Mat1b kPositiveContrastCurve;
static cv::Mat1b kNegativeContrastCurve;

static const GLKVector3 kColorFilterDefault = GLKVector3Make(0.299, 0.587, 0.114);

- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output {
  LTProgram *program = [[LTProgram alloc] initWithVertexSource:[LTPassthroughShaderVsh source]
                                                fragmentSource:[LTBWTonalityFsh source]];
  LTTexture *smoothTexture = [self createSmoothTexture:input];
  // Default color gradient.
  LTColorGradient *identityGradient = [LTColorGradient identityGradient];

  NSDictionary *auxiliaryTextures =
      @{[LTBWTonalityFsh smoothTexture]: smoothTexture,
        [LTBWTonalityFsh toneLUT]: [LTTexture textureWithImage:kIdentityCurve],
        [LTBWTonalityFsh colorGradient]: [identityGradient textureWithSamplingPoints:256]};
  if (self = [super initWithProgram:program sourceTexture:input auxiliaryTextures:auxiliaryTextures
                          andOutput:output]) {
    [self setDefaultValues];
  }
  return self;
}

+ (void)initialize {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    kIdentityCurve = LTLoadMatFromBundle([NSBundle LTKitBundle], @"IdentityCurve.png");
    kPositiveBrightnessCurve = LTLoadMatFromBundle([NSBundle LTKitBundle],
                                                   @"PositiveBrightnessCurve.png");
    kNegativeBrightnessCurve = LTLoadMatFromBundle([NSBundle LTKitBundle],
                                                   @"NegativeBrightnessCurve.png");
    kPositiveContrastCurve = LTLoadMatFromBundle([NSBundle LTKitBundle],
                                                 @"PositiveContrastCurve.png");
    kNegativeContrastCurve = LTLoadMatFromBundle([NSBundle LTKitBundle],
                                                 @"NegativeContrastCurve.png");
  });
}

- (void)setDefaultValues {
  self.colorFilter = kColorFilterDefault;
  self.brightness = kDefaultBrightness;
  self.contrast = kDefaultContrast;
  self.exposure = kDefaultExposure;
  self.structure = kDefaultStructure;
  _colorGradientTexture = self.auxiliaryTextures[[LTBWTonalityFsh colorGradient]];
}

- (LTTexture *)createSmoothTexture:(LTTexture *)input {
  static const CGFloat kSmoothDownsampleFactor = 4.0;
  
  CGFloat width = MAX(1.0, input.size.width / kSmoothDownsampleFactor);
  CGFloat height = MAX(1.0, input.size.height / kSmoothDownsampleFactor);

  CGSize size = std::floor(CGSizeMake(width, height));
  LTTexture *smoothTexture = [LTTexture byteRGBATextureWithSize:size];
  
   LTBilateralFilterProcessor *smoother = [[LTBilateralFilterProcessor alloc] initWithInput:input
                                                                       outputs:@[smoothTexture]];
  smoother.rangeSigma = 0.15;
  smoother.iterationsPerOutput = @[@5];
  [smoother process];
  
  return smoothTexture;
}

- (void)setColorFilter:(GLKVector3)colorFilter {
  LTParameterAssert(GLKVectorInRange(colorFilter, 0.0, 1.0), @"Color filter is out of range.");
  LTParameterAssert(GLKVector3Length(colorFilter), @"Black is not a valid color filter");
  
  _colorFilter = colorFilter / std::sum(colorFilter);
  self[@"colorFilter"] = $(_colorFilter);
}

LTBoundedPrimitivePropertyImplementWithCustomSetter(CGFloat, brightness, Brightness, -1, 1, 0, ^{
  [self updateToneLUT];
});

LTBoundedPrimitivePropertyImplementWithCustomSetter(CGFloat, contrast, Contrast, -1, 1, 0, ^{
  [self updateToneLUT];
});

LTBoundedPrimitivePropertyImplementWithCustomSetter(CGFloat, exposure, Exposure, -1, 1, 0, ^{
  [self updateToneLUT];
});

LTBoundedPrimitivePropertyImplementWithCustomSetter(CGFloat, structure, Structure, -1, 1, 0, ^{
  // Remap [-1, 1] -> [0.25, 4].
  CGFloat remap = std::powf(4.0, structure);
  self[@"structure"] = @(remap);
});

- (void)setColorGradientTexture:(LTTexture *)colorGradientTexture {
  LTParameterAssert(colorGradientTexture.size.height == 1,
                    @"colorGradientTexture height is not one");
  LTParameterAssert(colorGradientTexture.size.width <= 256,
                    @"colorGradientTexture width is larger than 256");
  
  _colorGradientTexture = colorGradientTexture;
  NSMutableDictionary *auxiliaryTextures = [self.auxiliaryTextures mutableCopy];
  auxiliaryTextures[[LTBWTonalityFsh colorGradient]] = colorGradientTexture;
  self.auxiliaryTextures = auxiliaryTextures;
}

- (void)updateToneLUT {
  static const ushort kLutSize = 256;
  
  cv::Mat1b toneCurve(1, kLutSize);
  
  cv::Mat1b brightnessCurve(1, kLutSize);
  if (self.brightness >= kDefaultBrightness) {
    brightnessCurve = kPositiveBrightnessCurve;
  } else {
    brightnessCurve = kNegativeBrightnessCurve;
  }
  
  cv::Mat1b contrastCurve(1, kLutSize);
  if (self.contrast >= kDefaultContrast) {
    contrastCurve = kPositiveContrastCurve;
  } else {
    contrastCurve = kNegativeContrastCurve;
  }
  
  float brightness = std::abs(self.brightness);
  float contrast = std::abs(self.contrast);
  cv::LUT((1.0 - contrast) * kIdentityCurve + contrast * contrastCurve,
          (1.0 - brightness) * kIdentityCurve + brightness * brightnessCurve,
          toneCurve);
  
  toneCurve = toneCurve * std::pow(2.0, self.exposure);
  NSMutableDictionary *auxiliaryTextures = [self.auxiliaryTextures mutableCopy];
  [auxiliaryTextures[[LTBWTonalityFsh toneLUT]] load:toneCurve];
  self.auxiliaryTextures = auxiliaryTextures;
}

@end
