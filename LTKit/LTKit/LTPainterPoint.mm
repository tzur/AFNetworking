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
  return self = [super init];
}

- (instancetype)initWithCurrentTimestamp {
  if (self = [self init]) {
    self.timestamp = CACurrentMediaTime();
  }
  return self;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"screen: (%.4g,%.4g), content: (%.4g,%.4g), zoom: %g, "
          "timestamp: %g, distance: %g, diameter: %g",
          self.screenPosition.x, self.screenPosition.y,
          self.contentPosition.x, self.contentPosition.y,
          self.zoomScale, self.timestamp, self.distanceFromStart, self.diameter];
}

- (NSArray *)propertiesToInterpolate {
  static NSArray *propertiesToInterpolate;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    propertiesToInterpolate = @[@"contentPositionX", @"contentPositionY",
                                @"screenPositionX", @"screenPositionY",
                                @"timestamp", @"zoomScale", @"diameter"];
  });
  return propertiesToInterpolate;
}

- (id)copyWithZone:(NSZone *)zone {
  LTPainterPoint *point = [[[self class] allocWithZone:zone] init];
  point.timestamp = self.timestamp;
  point.screenPosition = self.screenPosition;
  point.contentPosition = self.contentPosition;
  point.zoomScale = self.zoomScale;
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

- (void)setDistanceFromStart:(CGFloat)distanceFromStart {
  _distanceFromStart = MAX(0, distanceFromStart);
}

- (void)setDiameter:(CGFloat)diameter {
  _diameter = MAX(0, diameter);
}

@end
