// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTColorGradient.h"
#import "LTGLKitExtensions.h"
#import "LTTexture+Factory.h"

@implementation LTColorGradientControlPoint

- (instancetype)initWithPosition:(CGFloat)position color:(GLKVector3)color {
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

- (instancetype)initWithControlPoints:(NSArray *)controlPoints {
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

// Linearly interpolate/extrapolate two control points to get the values at position.
+ (GLKVector3)sampleWithPoint0:(LTColorGradientControlPoint *)p0
                        point1:(LTColorGradientControlPoint *)p1 atPosition:(CGFloat)position {
  CGFloat x0 = p0.position;
  CGFloat x1 = p1.position;
  GLKVector3 y0 = p0.color;
  GLKVector3 y1 = p1.color;
  return std::round((y0 + (position - x0)/(x1 - x0) * (y1 - y0)) * 255.0);
}

- (LTTexture *)textureWithSamplingPoints:(NSUInteger)numberOfPoints {
  LTParameterAssert(numberOfPoints >= 2, @"Number of bins in the texture should be larger than 2");
  
  // Initialize the interpolation edges with first two control points.
  LTColorGradientControlPoint *p0 = self.controlPoints[0];
  LTColorGradientControlPoint *p1 = self.controlPoints[1];
  
  NSUInteger rightEdgeIndex = 1;
  cv::Mat4b mat(1, (int)numberOfPoints);
  
  for (int col = 0; col < (int)numberOfPoints; ++col) {
    CGFloat currentPosition = ((CGFloat)col) / numberOfPoints;
    // Update the interpolation edges, only if currentPosition is passed the right edge and there is
    // a control point on the right that can be used as a new edge.
    if (currentPosition >= p1.position && rightEdgeIndex < self.controlPoints.count - 1) {
      rightEdgeIndex++;
      p0 = p1;
      p1 = self.controlPoints[rightEdgeIndex];
    }
    // Interpolate/extrapolate the control points to get the in-between values.
    GLKVector3 color = [LTColorGradient sampleWithPoint0:p0 point1:p1 atPosition:currentPosition];
    mat(0, col) = cv::Vec4b(color.r, color.g, color.b, 255);
  }
  
  return [LTTexture textureWithImage:mat];
}

@end
