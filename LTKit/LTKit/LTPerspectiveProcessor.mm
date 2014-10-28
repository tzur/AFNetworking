// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTPerspectiveProcessor.h"

#import <array>

#import "LTCGExtensions.h"
#import "LTGLKitExtensions.h"
#import "LTNextIterationPlacement.h"
#import "LTOneShotImageProcessor+Protected.h"
#import "LTProgram.h"
#import "LTRotatedRect.h"
#import "LTShaderStorage+LTPassthroughShaderVsh.h"
#import "LTShaderStorage+LTPerspectiveProcessorFsh.h"
#import "LTTexture.h"

/// Represents a trapezoid which is a result of a perspective projection of the input texture.
struct LTTrapezoid2 {
  LTTrapezoid2() {}

  LTTrapezoid2(const LTVector2 &topLeft, const LTVector2 &topRight,
               const LTVector2 &bottomLeft, const LTVector2 &bottomRight) :
      corners{{topLeft, topRight, bottomLeft, bottomRight}} {}

  inline LTVector2 &topLeft() {
    return corners[0];
  }

  inline LTVector2 &topRight() {
    return corners[1];
  }

  inline LTVector2 &bottomLeft() {
    return corners[2];
  }

  inline LTVector2 &bottomRight() {
    return corners[3];
  }

  std::array<LTVector2, 4> corners;
};

@interface LTPerspectiveProcessor ()

/// Uniform scale applied on the projection to guarantee that it entirely fits the output texture.
@property (nonatomic) CGFloat scale;

/// Translation applied to center the rectangle bounding the projected trapezoid.
@property (nonatomic) CGSize translation;

/// Matrix used to map a point in [-1,1]x[-1,1] (texture coordinates before projection) to its
/// corresponding point in texture coordinates after the projection (again, in [-1,1]x[-1,1]).
@property (nonatomic) GLKMatrix3 matrix;

/// Inverse matrix of the projection matrix above.
@property (nonatomic) GLKMatrix3 inverseMatrix;

/// Current result of the perspective projection of the input texture, in [0,1]x[0,1] coordinates.
@property (nonatomic) LTTrapezoid2 trapezoid;

@end

@implementation LTPerspectiveProcessor

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithInput:(LTTexture *)input andOutput:(LTTexture *)output {
  LTParameterAssert(input);
  LTParameterAssert(output);
  if (self = [super initWithVertexSource:[LTPassthroughShaderVsh source]
                          fragmentSource:[LTPerspectiveProcessorFsh source]
                                   input:input andOutput:output]) {
    [self updateModel];
    [self setupDrawerUniforms];
  }
  return self;
}

- (void)setupDrawerUniforms {
  self.drawer[[LTPerspectiveProcessorFsh aspectFactor]] = $(self.aspectFactor);
  self.drawer[[LTPerspectiveProcessorFsh distortionScaleCompensation]] =
      $(self.scaleCompensationForCurrentDistortion);
}

#pragma mark -
#pragma mark Input model
#pragma mark -

+ (NSSet *)inputModelPropertyKeys {
  static NSSet *properties;
  
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    properties = [NSSet setWithArray:@[
      @instanceKeypath(LTPerspectiveProcessor, scaleMode),
      @instanceKeypath(LTPerspectiveProcessor, horizontal),
      @instanceKeypath(LTPerspectiveProcessor, vertical),
      @instanceKeypath(LTPerspectiveProcessor, rotationAngle),
      @instanceKeypath(LTPerspectiveProcessor, distortion),
    ]];
  });
  
  return properties;
}

#pragma mark -
#pragma mark Processing
#pragma mark -

- (void)drawWithPlacement:(LTNextIterationPlacement *)placement {
  CGRect sourceRect = [self sourceRectForSourceTextureSize:self.inputTexture.size];
  CGRect targetRect = CGRectFromSize(self.outputTexture.size);
  [self.drawer drawRect:targetRect inFramebuffer:placement.targetFbo fromRect:sourceRect];
}

- (CGRect)sourceRectForFramebufferSize:(__unused CGSize)framebufferSize
                            outputRect:(__unused CGRect)rect
                     sourceTextureSize:(CGSize)size {
  return [self sourceRectForSourceTextureSize:size];
}

- (CGRect)sourceRectForSourceTextureSize:(CGSize)size {
  CGPoint center = CGPointMake(0.5, 0.5) + self.translation / self.scale;
  return CGRectCenteredAt(size * center, size / self.scale);
}

#pragma mark -
#pragma mark Public Interface
#pragma mark -

- (BOOL)pointInTexture:(CGPoint)point {
  // CGRectContainsPoint is not used since we want to include the maxX and maxY edges.
  CGPoint transformed = [self transformedPoint:point];
  return transformed.x >= 0 && transformed.x <= 1 && transformed.y >= 0 && transformed.y <= 1;
}

- (CGPoint)transformedPoint:(CGPoint)point {
  point = point + self.translation;
  point = point * 2.0 - CGSizeMakeUniform(1);
  point = point / self.scale;
  
  GLKVector3 v = GLKVector3Make(point.x, point.y, 1.0);
  v = GLKMatrix3MultiplyVector3(self.matrix, v);
  v = v / v.z;
  v = (v + GLKVector3One) / 2.0;
  return CGPointMake(v.x, v.y);
}

#pragma mark -
#pragma mark Updating Model
#pragma mark -

- (void)updateModel {
  self.matrix = [self matrixForCurrentProperties];
  self.inverseMatrix = [self inverseMatrixForCurrentProperties];
  self.scale = [self scaleForCurrentMatrix];
  self.translation = [self translationForCurrentMatrixAndScale];
  self.trapezoid = [self trapezoidForScale:self.scale translation:self.translation];
}

- (GLKMatrix3)matrixForCurrentProperties {
  CGSize size = self.inputTexture.size;
  GLKMatrix3 matrix = GLKMatrix3Identity;
  matrix = GLKMatrix3Rotate(matrix, self.horizontal, 0, 1, 0);
  matrix = GLKMatrix3Rotate(matrix, self.vertical, 1, 0, 0);
  matrix = GLKMatrix3Scale(matrix, 1.0 / size.width, 1.0 / size.height, 1);
  matrix = GLKMatrix3Rotate(matrix, -self.rotationAngle, 0, 0, 1);
  matrix = GLKMatrix3Scale(matrix, size.width, size.height, 1);
  return matrix;
}

- (GLKMatrix3)inverseMatrixForCurrentProperties {
  CGSize size = self.inputTexture.size;
  GLKMatrix3 matrix = GLKMatrix3Identity;
  matrix = GLKMatrix3Scale(matrix, 1.0 / size.width, 1.0 / size.height, 1);
  matrix = GLKMatrix3Rotate(matrix, self.rotationAngle, 0, 0, 1);
  matrix = GLKMatrix3Scale(matrix, size.width, size.height, 1);
  matrix = GLKMatrix3Rotate(matrix, -self.vertical, 1, 0, 0);
  matrix = GLKMatrix3Rotate(matrix, -self.horizontal, 0, 1, 0);
  return matrix;
}

- (CGFloat)scaleForCurrentMatrix {
  // TODO:(amit) implement scale mode fill for perspective corrections when LTQuad will
  // support boundedRectWithAspectRatio calculation.
  LTAssert(self.scaleMode == LTPerspectiveProcessorScaleModeFit ||
           (!self.horizontal && !self.vertical && !self.distortion),
           @"LTPerspectiveProcessorScaleModeFill currently supports rotation only");
  CGRect rectForScale =
      [self boundingRectForTrapezoid:[self trapezoidForScale:1 translation:CGSizeZero]];
  CGFloat scale = std::max(rectForScale.size);
  return self.scaleMode == LTPerspectiveProcessorScaleModeFill ? scale : 1.0 / scale;
}

- (CGSize)translationForCurrentMatrixAndScale {
  CGRect rectForTranslation =
      [self boundingRectForTrapezoid:[self trapezoidForScale:self.scale translation:CGSizeZero]];
  return (CGRectCenter(rectForTranslation) - CGPointMake(0.5, 0.5));
}

- (LTTrapezoid2)trapezoidForScale:(CGFloat)scale translation:(CGSize)translation {
  GLKVector3 trapezoid[] = {
    GLKVector3Make(-1, -1, 1),
    GLKVector3Make(1, -1, 1),
    GLKVector3Make(-1, 1, 1),
    GLKVector3Make(1, 1, 1)
  };
  
  GLKMatrix3MultiplyVector3Array(self.inverseMatrix, trapezoid, 4);
  for (GLKVector3 &corner : trapezoid) {
    corner = corner / corner.z;
    corner = corner * scale;
    corner.x -= 2.0 * translation.width;
    corner.y -= 2.0 * translation.height;
    corner.x = 0.5 + 0.5 * corner.x;
    corner.y = 0.5 + 0.5 * corner.y;
  }
  
  return LTTrapezoid2(LTVector2(trapezoid[0].x, trapezoid[0].y),
                      LTVector2(trapezoid[1].x, trapezoid[1].y),
                      LTVector2(trapezoid[2].x, trapezoid[2].y),
                      LTVector2(trapezoid[3].x, trapezoid[3].y));
}

- (CGRect)boundingRectForTrapezoid:(const LTTrapezoid2 &)trapezoid {
  CGPoint topLeft = CGPointMake(INFINITY, INFINITY);
  CGPoint bottomRight = CGPointMake(-INFINITY, -INFINITY);
  for (const LTVector2 &corner : trapezoid.corners) {
    topLeft.x = MIN(topLeft.x, corner.x);
    topLeft.y = MIN(topLeft.y, corner.y);
    bottomRight.x = MAX(bottomRight.x, corner.x);
    bottomRight.y = MAX(bottomRight.y, corner.y);
  }
  return CGRectFromPoints(topLeft, bottomRight);
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (void)setMatrix:(GLKMatrix3)matrix {
  if (matrix == _matrix) {
    return;
  }

  _matrix = matrix;
  self.drawer[[LTPerspectiveProcessorFsh perspective]] = $(self.matrix);
}

- (void)setScaleMode:(LTPerspectiveProcessorScaleMode)scaleMode {
  _scaleMode = scaleMode;
  [self updateModel];
}

LTPropertyWithoutSetter(CGFloat, horizontal, Horizontal, -M_PI / 10, M_PI / 10, 0);
- (void)setHorizontal:(CGFloat)horizontal {
  [self _verifyAndSetHorizontal:horizontal];
  [self updateModel];
}

LTPropertyWithoutSetter(CGFloat, vertical, Vertical, -M_PI / 10, M_PI / 10, 0);
- (void)setVertical:(CGFloat)vertical {
  [self _verifyAndSetVertical:vertical];
  [self updateModel];
}

LTPropertyWithoutSetter(CGFloat, rotationAngle, RotationAngle, -M_PI / 6, M_PI / 6, 0);
- (void)setRotationAngle:(CGFloat)rotationAngle {
  [self _verifyAndSetRotationAngle:rotationAngle];
  [self updateModel];
}

LTPropertyWithoutSetter(CGFloat, distortion, Distortion, -0.5, 0.5, 0);
- (void)setDistortion:(CGFloat)distortion {
  [self _verifyAndSetDistortion:distortion];
  self.drawer[[LTPerspectiveProcessorFsh distortion]] = @(self.mappedDistortion);
  self.drawer[[LTPerspectiveProcessorFsh distortionScaleCompensation]] =
      $(self.scaleCompensationForCurrentDistortion);
}

static const CGFloat kPincushionCorrectionFactor = 2;

- (CGFloat)mappedDistortion {
  return self.distortion < 0 ? self.distortion : self.distortion * kPincushionCorrectionFactor;
}

- (LTVector2)scaleCompensationForCurrentDistortion {
  LTVector2 corner(0.5 * self.aspectFactor);
  corner *= 1 + self.mappedDistortion * corner.dot(corner);
  return corner / (0.5 * self.aspectFactor);
}

- (LTVector2)aspectFactor {
  return LTVector2(self.inputTexture.size / std::max(self.inputTexture.size));
}

- (LTVector2)topLeft {
  return self.trapezoid.topLeft();
}

- (LTVector2)topRight {
  return self.trapezoid.topRight();
}

- (LTVector2)bottomLeft {
  return self.trapezoid.bottomLeft();
}

- (LTVector2)bottomRight {
  return self.trapezoid.bottomRight();
}

- (CGRect)boundingRect {
  return [self boundingRectForTrapezoid:self.trapezoid];
}

@end
