// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTColorGradient.h"
#import "LTGLKitExtensions.h"
#import "LTTexture+Factory.h"

@implementation LTColorGradientControlPoint

- (instancetype)initWithPosition:(CGFloat)position colorWithAlpha:(LTVector4)color {
  LTParameterAssert(position >= 0 && position <= 1, @"Position should be in [0-1] range");
  if (self = [super init]) {
    _position = position;
    _color = color;
  }
  return self;
}

+ (LTColorGradientControlPoint *)controlPointWithPosition:(CGFloat)position
                                                    color:(LTVector3)color {
  return [[LTColorGradientControlPoint alloc]
      initWithPosition:position colorWithAlpha:LTVector4(color.r(), color.g(), color.b(), 1)];
}

+ (LTColorGradientControlPoint *)controlPointWithPosition:(CGFloat)position
                                           colorWithAlpha:(LTVector4)color {
  return [[LTColorGradientControlPoint alloc] initWithPosition:position colorWithAlpha:color];
}

- (instancetype)initWithPosition:(CGFloat)position color:(LTVector3)color {
  return [self initWithPosition:position
                 colorWithAlpha:LTVector4(color.r(), color.g(), color.b(), 1)];
}

@end

@interface LTColorGradient ()

/// Array of LTColorGradientControlPoints.
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
+ (LTVector4)sampleWithPoint0:(LTColorGradientControlPoint *)p0
                       point1:(LTColorGradientControlPoint *)p1 atPosition:(CGFloat)position {
  CGFloat x0 = p0.position;
  CGFloat x1 = p1.position;
  LTVector4 y0 = p0.color;
  LTVector4 y1 = p1.color;
  return std::round((y0 + (y1 - y0) * (position - x0) / (x1 - x0)) * 255.0);
}

- (cv::Mat4b)matWithSamplingPoints:(NSUInteger)numberOfPoints {
  LTParameterAssert(numberOfPoints >= 2, @"Number of bins in the texture should be larger than 2");

  // Initialize the interpolation edges with first two control points.
  LTColorGradientControlPoint *p0 = self.controlPoints[0];
  LTColorGradientControlPoint *p1 = self.controlPoints[1];

  NSUInteger rightEdgeIndex = 1;
  cv::Mat4b mat(1, (int)numberOfPoints);

  for (int col = 0; col < (int)numberOfPoints; ++col) {
    CGFloat currentPosition = ((CGFloat)col) / (numberOfPoints - 1);
    // Update the interpolation edges, only if currentPosition is passed the right edge and there is
    // a control point on the right that can be used as a new edge.
    if (currentPosition >= p1.position && rightEdgeIndex < self.controlPoints.count - 1) {
      rightEdgeIndex++;
      p0 = p1;
      p1 = self.controlPoints[rightEdgeIndex];
    }
    // Interpolate/extrapolate the control points to get the in-between values.
    LTVector4 color = [LTColorGradient sampleWithPoint0:p0 point1:p1 atPosition:currentPosition];
    mat(0, col) = cv::Vec4b(color.r(), color.g(), color.b(), color.a());
  }

  return mat;
}

- (LTTexture *)textureWithSamplingPoints:(NSUInteger)numberOfPoints {
  cv::Mat4b image([self matWithSamplingPoints:numberOfPoints]);
  return [LTTexture textureWithImage:image];
}

+ (LTColorGradient *)identityGradient {
  LTColorGradientControlPoint *controlPoint0 = [[LTColorGradientControlPoint alloc]
                                                initWithPosition:0.0
                                                color:LTVector3(0.0, 0.0, 0.0)];
  LTColorGradientControlPoint *controlPoint1 = [[LTColorGradientControlPoint alloc]
                                                initWithPosition:1.0
                                                color:LTVector3(1.0, 1.0, 1.0)];
  
  NSArray *controlPoints = @[controlPoint0, controlPoint1];
  return [[LTColorGradient alloc] initWithControlPoints:controlPoints];
}

@end
