// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTColorGradient.h"
#import "LTGLKitExtensions.h"
#import "LTGLTexture.h"

@implementation LTColorGradientControlPoint

- (id)initWithPosition:(CGFloat)position color:(GLKVector3)color {
  LTParameterAssert(position >= 0 && position <= 1, @"Position should be in [0-1] range");
  if (self = [super init]) {
    _position = position;
    _color = color;
  }
  return self;
}

@end

@interface LTColorGradient()

// Array of LTColorGradientControlPoints.
@property (strong, nonatomic) NSArray *controlPoints;

@end

@implementation LTColorGradient

- (id)initWithControlPoints:(NSArray *)controlPoints {
  if (self = [super init]) {
    [self validateInputs:controlPoints];
    self.controlPoints = controlPoints;
  }
  return self;
}

- (void)validateInputs:(NSArray *)controlPoints {
  LTParameterAssert(controlPoints.count >= 2,
                    @"At least two points are required to construct the color gradient");
  
  [controlPoints enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *) {
    LTParameterAssert([obj isKindOfClass:[LTColorGradientControlPoint class]],
                      @"Given object is not of type LTColorGradientControlPoint");
    // Check monotonicity starting from the second point.
    if (idx) {
      LTColorGradientControlPoint *point0 = (LTColorGradientControlPoint *)controlPoints[idx-1];
      LTColorGradientControlPoint *point1 = (LTColorGradientControlPoint *)obj;
      LTParameterAssert(point0.position < point1.position,
                        @"Control points should be monotonically increasing");
    }
  }];
}

- (LTTexture *)textureWithSamplingPoints:(NSUInteger)numberOfPoints {
  LTParameterAssert(numberOfPoints >= 2, @"Number of bins in the texture should be larger than 2");
  
  // Initialize the interpolation edges.
  LTColorGradientControlPoint *p0 = self.controlPoints[0];
  LTColorGradientControlPoint *p1 = self.controlPoints[1];
  CGFloat x0 = p0.position;
  CGFloat x1 = p1.position;
  GLKVector3 y0 = p0.color;
  GLKVector3 y1 = p1.color;
  NSUInteger x1PositionIndex = 1;
  cv::Mat4b mat(1, (int)numberOfPoints);
  for (uint i = 0; i < numberOfPoints; ++i) {
    CGFloat normalizedIndex = ((CGFloat)i) / numberOfPoints;
    // Update the interpolation edges, if necessary.
    if (normalizedIndex >= x1 && x1PositionIndex < self.controlPoints.count - 1) {
      x1PositionIndex++;
      x0 = x1;
      y0 = y1;
      x1 = ((LTColorGradientControlPoint *)self.controlPoints[x1PositionIndex]).position;
      y1 = ((LTColorGradientControlPoint *)self.controlPoints[x1PositionIndex]).color;
    }
    // Interpolate/extrapolate the control points to get the in-between values.
    GLKVector3 color = std::round((y0 + (normalizedIndex - x0)/(x1 - x0) * (y1 - y0)) * 255.0);
    mat(0, i) = cv::Vec4b(color.r, color.g, color.b, 255);
  }
  
  return [[LTGLTexture alloc] initWithImage:mat];
}

@end
