// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTEdgeAvoidingMultiTextureBrush.h"

#import "LTOpenCVExtensions.h"
#import "LTProgram.h"
#import "LTRectDrawer.h"
#import "LTShaderStorage+LTEdgeAvoidingBrushVsh.h"
#import "LTShaderStorage+LTEdgeAvoidingMultiTextureBrushFsh.h"
#import "LTTexture+Factory.h"

@interface LTBrush ()
@property (strong, nonatomic) LTProgram *program;
@property (strong, nonatomic) LTRectDrawer *drawer;
@end

@interface LTTextureBrush ()
@property (strong, nonatomic) LTTexture *texture;
@end

@interface LTEdgeAvoidingMultiTextureBrush ()

/// A texture with a gaussian at the size of the brush, used as a spatial distance weight for the
/// edge-avoiding factor. A texture is used to avoid calculating this value inside the fragment
/// shader for every fragment.
@property (strong, nonatomic) LTTexture *gaussianTexture;

/// A single pixel texture used when the inputTexture is set to \c nil, practically disabling the
/// edge-avoiding effect.
@property (strong, nonatomic) LTTexture *defaultInputTexture;

@end

@implementation LTEdgeAvoidingMultiTextureBrush

- (LTProgram *)createProgram {
  return [[LTProgram alloc] initWithVertexSource:[LTEdgeAvoidingBrushVsh source]
                                  fragmentSource:[LTEdgeAvoidingMultiTextureBrushFsh source]];
}

- (LTRectDrawer *)createDrawer {
  LTAssert(self.texture);
  LTAssert(self.program);
  LTAssert(self.gaussianTexture);
  return [[LTRectDrawer alloc] initWithProgram:self.program sourceTexture:self.texture
              auxiliaryTextures:@{[LTEdgeAvoidingMultiTextureBrushFsh gaussianTexture]:
                                  self.gaussianTexture,
                                  [LTEdgeAvoidingMultiTextureBrushFsh auxiliaryTexture]:
                                  self.inputOrDefaultTexture}];
}

- (void)updateProgramForCurrentProperties {
  self.program[[LTEdgeAvoidingMultiTextureBrushFsh flow]] = @(self.flow);
  self.program[[LTEdgeAvoidingMultiTextureBrushFsh opacity]] = @(self.opacity);
  self.program[[LTEdgeAvoidingMultiTextureBrushFsh intensity]] = $(self.intensity);
  self.program[[LTEdgeAvoidingMultiTextureBrushFsh sigma]] = @(self.sigma);
  self.program[[LTEdgeAvoidingMultiTextureBrushFsh premultiplied]] = @(self.premultipliedAlpha);
  self.program[[LTEdgeAvoidingMultiTextureBrushFsh useAuxiliaryTexture]] =
      self.inputTexture ? @(YES) : @(NO);
}

#pragma mark -
#pragma mark Properties
#pragma mark -

LTPropertyUpdatingProgram(CGFloat, sigma, Sigma, 0.01, 1, 1);

/// Sigma used for generating the gaussian, yielding a falloff which is very close to \c 0 at the
/// edges.
static const double kGaussianSigma = 0.3;

- (void)setTexture:(LTTexture *)texture {
  [super setTexture:texture];
  self.gaussianTexture =
      [LTTexture textureWithImage:LTCreateGaussianMat(texture.size, kGaussianSigma)];
}

- (void)setGaussianTexture:(LTTexture *)gaussianTexture {
  LTParameterAssert(gaussianTexture.format == LTTextureFormatRed);
  _gaussianTexture = gaussianTexture;
  [self.drawer setAuxiliaryTexture:gaussianTexture
                          withName:[LTEdgeAvoidingMultiTextureBrushFsh gaussianTexture]];
}

- (NSArray *)adjustableProperties {
  return @[@"scale", @"spacing", @"flow", @"opacity", @"angle", @"sigma"];
}

- (void)setInputTexture:(LTTexture *)inputTexture {
  _inputTexture = inputTexture;
  [self.drawer setAuxiliaryTexture:self.inputOrDefaultTexture
                          withName:[LTEdgeAvoidingMultiTextureBrushFsh auxiliaryTexture]];
  [self updateProgramForCurrentProperties];
}

- (LTTexture *)defaultInputTexture {
  if (!_defaultInputTexture) {
    cv::Mat4b mat(1, 1, cv::Vec4b(0, 0, 0, 0));
    _defaultInputTexture = [LTTexture textureWithImage:mat];
  }
  return _defaultInputTexture;
}

- (LTTexture *)inputOrDefaultTexture {
  return self.inputTexture ?: self.defaultInputTexture;
}

@end
