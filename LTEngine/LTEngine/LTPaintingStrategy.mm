// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTPaintingStrategy.h"

#import "LTLinearInterpolant.h"
#import "LTPainterStroke.h"

@interface LTPaintingDirections ()
@property (strong, nonatomic) LTBrush *brush;
@property (strong, nonatomic) LTPainterStroke *stroke;
@end

@implementation LTPaintingDirections

+ (LTPaintingDirections *)directionsWithBrush:(LTBrush *)brush stroke:(LTPainterStroke *)stroke {
  LTParameterAssert(brush);
  LTParameterAssert(stroke);
  LTPaintingDirections *directions = [[LTPaintingDirections alloc] init];
  directions.brush = brush;
  directions.stroke = stroke;
  return directions;
}

+ (LTPaintingDirections *)directionsWithBrush:(LTBrush *)brush
                       linearStrokeStartingAt:(LTPainterPoint *)point {
  LTParameterAssert(brush);
  LTParameterAssert(point);
  LTPaintingDirections *directions = [[LTPaintingDirections alloc] init];
  directions.brush = brush;
  directions.stroke =
      [[LTPainterStroke alloc] initWithInterpolantFactory:[self linearFactory] startingPoint:point];
  return directions;
}

+ (LTLinearInterpolantFactory *)linearFactory {
  static LTLinearInterpolantFactory *linearFactory;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    linearFactory = [[LTLinearInterpolantFactory alloc] init];
  });
  return linearFactory;
}

@end
