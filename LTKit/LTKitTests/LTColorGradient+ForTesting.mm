// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTColorGradient+ForTesting.h"

@implementation LTColorGradient (ForTesting)

+ (LTColorGradient *)colderThanNeutralGradient {
  // Scale the red channel slightly to create a "colder-than-neutral" gradient.
  CGFloat redScale = 0.95;
  LTColorGradientControlPoint *controlPoint0 = [[LTColorGradientControlPoint alloc]
      initWithPosition:0.0 color:GLKVector3Make(0.0, 0.0, 0.0)];
  LTColorGradientControlPoint *controlPoint1 = [[LTColorGradientControlPoint alloc]
      initWithPosition:0.25 color:GLKVector3Make(0.25 * redScale, 0.25, 0.25)];
  LTColorGradientControlPoint *controlPoint2 = [[LTColorGradientControlPoint alloc]
      initWithPosition:0.5 color:GLKVector3Make(0.5 * redScale, 0.5, 0.5)];
  LTColorGradientControlPoint *controlPoint3 = [[LTColorGradientControlPoint alloc]
      initWithPosition:0.75 color:GLKVector3Make(0.75 * redScale, 0.75, 0.75)];
  LTColorGradientControlPoint *controlPoint4 = [[LTColorGradientControlPoint alloc]
      initWithPosition:1.0 color:GLKVector3Make(1.0 * redScale, 1.0, 1.0)];
  
  NSArray *controlPoints = @[controlPoint0, controlPoint1, controlPoint2, controlPoint3,
                             controlPoint4];
  return [[LTColorGradient alloc] initWithControlPoints:controlPoints];
}

+ (LTColorGradient *)magentaYellowGradient {
  LTColorGradientControlPoint *controlPoint0 = [[LTColorGradientControlPoint alloc]
      initWithPosition:0.0 color:GLKVector3Make(0.75, 0.18, 0.57)];
  LTColorGradientControlPoint *controlPoint1 = [[LTColorGradientControlPoint alloc]
      initWithPosition:0.2 color:GLKVector3Make(0.83, 0.49, 0.55)];
  LTColorGradientControlPoint *controlPoint2 = [[LTColorGradientControlPoint alloc]
      initWithPosition:0.4 color:GLKVector3Make(0.86, 0.59, 0.53)];
  LTColorGradientControlPoint *controlPoint3 = [[LTColorGradientControlPoint alloc]
      initWithPosition:0.6 color:GLKVector3Make(0.87, 0.65, 0.49)];
  LTColorGradientControlPoint *controlPoint4 = [[LTColorGradientControlPoint alloc]
      initWithPosition:0.8 color:GLKVector3Make(0.92, 0.77, 0.39)];
  LTColorGradientControlPoint *controlPoint5 = [[LTColorGradientControlPoint alloc]
      initWithPosition:1.0 color:GLKVector3Make(1.00, 0.95, 0.23)];
  
  NSArray *controlPoints = @[controlPoint0, controlPoint1, controlPoint2, controlPoint3,
                             controlPoint4, controlPoint5];
  return [[LTColorGradient alloc] initWithControlPoints:controlPoints];
}

@end
