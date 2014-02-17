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
  }
  return self;
}

- (instancetype)initWithScreenPosition:(CGPoint)screenPosition
                       contentPosition:(CGPoint)contentPosition
                           atZoomScale:(CGFloat)zoomScale {
  return [self initWithScreenPosition:screenPosition contentPosition:contentPosition
                          atZoomScale:zoomScale withTimestamp:CACurrentMediaTime()];
}

- (instancetype)initWithScreenPosition:(CGPoint)screenPosition
                       contentPosition:(CGPoint)contentPosition
                           atZoomScale:(CGFloat)zoomScale
                         withTimestamp:(CFTimeInterval)timestamp {
  if (self = [self init]) {
    self.screenPosition = screenPosition;
    self.contentPosition = contentPosition;
    self.zoomScale = zoomScale;
    self.timestamp = timestamp;
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

@end
