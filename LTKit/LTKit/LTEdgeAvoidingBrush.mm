// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTEdgeAvoidingBrush.h"

#import "LTCGExtensions.h"
#import "LTEasyBoxing.h"
#import "LTFbo.h"
#import "LTGLKitExtensions.h"
#import "LTProgram.h"
#import "LTRectDrawer.h"
#import "LTRotatedRect.h"
#import "LTShaderStorage+LTEdgeAvoidingBrushShaderFsh.h"
#import "LTShaderStorage+LTEdgeAvoidingBrushShaderVsh.h"
#import "LTTexture+Factory.h"

@interface LTBrush ()
- (void)drawRects:(NSArray *)targetRects inFramebuffer:(LTFbo *)fbo
        fromRects:(NSArray *)sourceRects;

@property (strong, nonatomic) LTTexture *texture;
@property (strong, nonatomic) LTProgram *program;
@property (strong, nonatomic) LTRectDrawer *drawer;
@end

@interface LTEdgeAvoidingBrush ()

/// A single pixel texture used when the inputTexture is set to \c nil, practically disabling the
/// edge-avoiding effect.
@property (strong, nonatomic) LTTexture *defaultInputTexture;

@end

@implementation LTEdgeAvoidingBrush

@synthesize inputTexture = _inputTexture;

/// Factor between the size (in pixels) of the target rect and the distance of the additional
/// edge-avoiding sampling points from its center.
static const CGFloat kSizeToSamplingFactor = 50;

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)init {
  if (self = [super init]) {
    [self setEdgeAvoidingBrushDefaults];
  }
  return self;
}

- (void)setEdgeAvoidingBrushDefaults {
  self.sigma = self.defaultSigma;
}

- (LTProgram *)createProgram {
  return [[LTProgram alloc] initWithVertexSource:[LTEdgeAvoidingBrushShaderVsh source]
                                  fragmentSource:[LTEdgeAvoidingBrushShaderFsh source]];
}

- (LTRectDrawer *)createDrawer {
  LTAssert(self.texture);
  LTAssert(self.program);
  LTAssert(self.inputTexture);
  return [[LTRectDrawer alloc]
              initWithProgram:self.program
                sourceTexture:self.texture
            auxiliaryTextures:@{[LTEdgeAvoidingBrushShaderFsh inputImage]: self.inputTexture}];
}

#pragma mark -
#pragma mark Drawing
#pragma mark -

- (void)startNewStrokeAtPoint:(LTPainterPoint *)point {
  [super startNewStrokeAtPoint:point];
}

- (void)drawRects:(NSArray *)targetRects inFramebuffer:(LTFbo *)fbo
        fromRects:(NSArray *)sourceRects {
  LTAssert(targetRects.count == sourceRects.count);
  [fbo bindAndDraw:^{
    for (NSUInteger i = 0; i < targetRects.count; ++i) {
      [self updateSamplingPointsForRect:targetRects[i] inSize:fbo.size];
      [self.drawer drawRotatedRect:targetRects[i] inBoundFramebufferWithSize:fbo.size
                   fromRotatedRect:sourceRects[i]];
    }
  }];
}

- (void)updateSamplingPointsForRect:(LTRotatedRect *)rotatedRect inSize:(CGSize)size {
  CGRect rect = rotatedRect.rect;
  CGSize offset = rect.size / kSizeToSamplingFactor;
  CGPoint sample0 = CGRectCenter(rect) / size;
  CGPoint sample1 = (CGRectCenter(rect) + CGSizeMake(-offset.width, -offset.height)) / size;
  CGPoint sample2 = (CGRectCenter(rect) + CGSizeMake(-offset.width, offset.height)) / size;
  CGPoint sample3 = (CGRectCenter(rect) + CGSizeMake(offset.width, -offset.height)) / size;
  CGPoint sample4 = (CGRectCenter(rect) + CGSizeMake(offset.width, offset.height)) / size;
  
  self.program[[LTEdgeAvoidingBrushShaderFsh samplePoint0]] = $(GLKVector2FromCGPoint(sample0));
  self.program[[LTEdgeAvoidingBrushShaderFsh samplePoint1]] = $(GLKVector2FromCGPoint(sample1));
  self.program[[LTEdgeAvoidingBrushShaderFsh samplePoint2]] = $(GLKVector2FromCGPoint(sample2));
  self.program[[LTEdgeAvoidingBrushShaderFsh samplePoint3]] = $(GLKVector2FromCGPoint(sample3));
  self.program[[LTEdgeAvoidingBrushShaderFsh samplePoint4]] = $(GLKVector2FromCGPoint(sample4));
}

- (void)updateProgramForCurrentProperties {
  self.program[[LTEdgeAvoidingBrushShaderFsh flow]] = @(self.flow);
  self.program[[LTEdgeAvoidingBrushShaderFsh sigma]] = @([self mappedSigma:self.sigma]);
  self.program[[LTEdgeAvoidingBrushShaderFsh opacity]] = @(self.opacity);
  self.program[[LTEdgeAvoidingBrushShaderFsh intensity]] = $(self.intensity);
}


- (CGFloat)mappedSigma:(CGFloat)sigma {
  LTParameterAssert(sigma >= 0 && sigma <= 1);
  static const CGFloat kSigmaMapPower = 2;
  static const CGFloat kSigmaMapFactor = 50;
  return std::pow(sigma, kSigmaMapPower) * kSigmaMapFactor;
}

#pragma mark -
#pragma mark Properties
#pragma mark -

LTPropertyUpdatingProgram(CGFloat, sigma, Sigma, 0.01, 1, 0.5);

- (CGFloat)minScale {
  return 0.5;
}

- (CGFloat)maxScale {
  return 3;
}

- (CGFloat)defaultScale {
  return 1;
}

- (CGFloat)defaultHardness {
  return 0.5;
}

- (NSArray *)adjustableProperties {
  return [super.adjustableProperties arrayByAddingObject:@"sigma"];
}

#pragma mark -
#pragma mark Input Image
#pragma mark -

- (void)setInputTexture:(LTTexture *)inputTexture {
  _inputTexture = inputTexture;
  [self.drawer setAuxiliaryTexture:self.inputTexture
                          withName:[LTEdgeAvoidingBrushShaderFsh inputImage]];
  [self updateProgramForCurrentProperties];
}

- (LTTexture *)inputTexture {
  return _inputTexture ?: self.defaultInputTexture;
}

- (LTTexture *)defaultInputTexture {
  if (!_defaultInputTexture) {
    cv::Mat4b mat(1, 1);
    mat = cv::Vec4b(0, 0, 0, 0);
    _defaultInputTexture = [LTTexture textureWithImage:mat];
  }
  return _defaultInputTexture;
}

@end
