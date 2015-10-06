// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTPainterPoint.h"

@interface LTPainterPoint ()

// Helper methods allowing interpolation of the screenPosition and contentPosition properties.
@property (nonatomic) CGFloat screenPositionX;
@property (nonatomic) CGFloat screenPositionY;
@property (nonatomic) CGFloat contentPositionX;
@property (nonatomic) CGFloat contentPositionY;

@end

@implementation LTPainterPoint

- (instancetype)init {
  if (self = [super init]) {
    self.zoomScale = 1;
    self.touchRadius = 1;
    self.touchRadiusTolerance = 1;
  }
  return self;
}

- (instancetype)initWithCurrentTimestamp {
  if (self = [self init]) {
    self.timestamp = CACurrentMediaTime();
  }
  return self;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p, screen: %@, content: %@, zoomScale: %g, "
          "touch radius: %g, timestamp: %g, distance: %g, diameter: %g>", [self class], self,
          NSStringFromCGPoint(self.screenPosition), NSStringFromCGPoint(self.contentPosition),
          self.zoomScale, self.touchRadius, self.timestamp, self.distanceFromStart, self.diameter];
}

- (NSArray *)propertiesToInterpolate {
  static NSArray *propertiesToInterpolate;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    propertiesToInterpolate = @[
      @keypath(self, contentPositionX),
      @keypath(self, contentPositionY),
      @keypath(self, screenPositionX),
      @keypath(self, screenPositionY),
      @keypath(self, timestamp),
      @keypath(self, zoomScale),
      @keypath(self, touchRadius),
      @keypath(self, touchRadiusTolerance),
      @keypath(self, diameter)
    ];
  });
  return propertiesToInterpolate;
}

- (id)copyWithZone:(NSZone *)zone {
  LTPainterPoint *point = [[[self class] allocWithZone:zone] init];
  point.timestamp = self.timestamp;
  point.screenPosition = self.screenPosition;
  point.contentPosition = self.contentPosition;
  point.zoomScale = self.zoomScale;
  point.touchRadius = self.touchRadius;
  point.touchRadiusTolerance = self.touchRadiusTolerance;
  point.diameter = self.diameter;
  point.distanceFromStart = self.distanceFromStart;
  return point;
}

#pragma mark -
#pragma mark Setters/Getters for CGPoint interpolated properties
#pragma mark -

- (void)setContentPositionX:(CGFloat)contentPositionX {
  _contentPosition.x = contentPositionX;
}

- (void)setContentPositionY:(CGFloat)contentPositionY {
  _contentPosition.y = contentPositionY;
}

- (void)setScreenPositionX:(CGFloat)screenPositionX {
  _screenPosition.x = screenPositionX;
}

- (void)setScreenPositionY:(CGFloat)screenPositionY {
  _screenPosition.y = screenPositionY;
}

- (CGFloat)contentPositionX {
  return self.contentPosition.x;
}

- (CGFloat)contentPositionY {
  return self.contentPosition.y;
}

- (CGFloat)screenPositionX {
  return self.screenPosition.x;
}

- (CGFloat)screenPositionY {
  return self.screenPosition.y;
}

#pragma mark -
#pragma mark Clamped Properties
#pragma mark -

- (void)setTimestamp:(CFTimeInterval)timestamp {
  _timestamp = MAX(0, timestamp);
}

- (void)setZoomScale:(CGFloat)zoomScale {
  _zoomScale = MAX(0, zoomScale);
}

- (void)setTouchRadius:(CGFloat)touchRadius {
  _touchRadius = MAX(0, touchRadius);
}

- (void)setTouchRadiusTolerance:(CGFloat)touchRadiusTolerance {
  _touchRadiusTolerance = MAX(0, touchRadiusTolerance);
}

- (void)setDistanceFromStart:(CGFloat)distanceFromStart {
  _distanceFromStart = MAX(0, distanceFromStart);
}

- (void)setDiameter:(CGFloat)diameter {
  _diameter = MAX(0, diameter);
}

@end
