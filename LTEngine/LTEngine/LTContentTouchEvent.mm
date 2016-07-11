// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTContentTouchEvent.h"

#import <LTKit/LTHashExtensions.h>

NS_ASSUME_NONNULL_BEGIN

@interface LTContentTouchEvent ()

/// Underlying touch event.
@property (readonly, nonatomic) id<LTTouchEvent> touchEvent;

@end

@implementation LTContentTouchEvent

@synthesize contentLocation = _contentLocation;
@synthesize previousContentLocation = _previousContentLocation;
@synthesize contentSize = _contentSize;
@synthesize contentZoomScale = _contentZoomScale;
@synthesize majorContentRadius = _majorContentRadius;
@synthesize majorContentRadiusTolerance = _majorContentRadiusTolerance;

@dynamic sequenceID;
@dynamic viewLocation;
@dynamic previousViewLocation;
@dynamic timestamp;
@dynamic view;
@dynamic phase;
@dynamic tapCount;
@dynamic majorRadius;
@dynamic majorRadiusTolerance;
@dynamic type;
@dynamic force;
@dynamic maximumPossibleForce;
@dynamic azimuthAngle;
@dynamic azimuthUnitVector;
@dynamic altitudeAngle;
@dynamic estimationUpdateIndex;
@dynamic estimatedProperties;
@dynamic estimatedPropertiesExpectingUpdates;

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithTouchEvent:(id<LTTouchEvent>)touchEvent contentSize:(CGSize)contentSize
                  contentZoomScale:(CGFloat)contentZoomScale
                         transform:(CGAffineTransform)transform {
  LTParameterAssert(touchEvent);

  if (self = [super init]) {
    _touchEvent = [touchEvent copyWithZone:nil];
    _contentLocation = CGPointApplyAffineTransform(touchEvent.viewLocation, transform);
    _previousContentLocation = CGPointApplyAffineTransform(touchEvent.previousViewLocation,
                                                           transform);
    _contentSize = contentSize;
    _contentZoomScale = contentZoomScale;
    _majorContentRadius =
        [self convertDistanceFromPresentationToContentCoordinates:touchEvent.majorRadius
                                                   usingTransform:transform];
    _majorContentRadiusTolerance =
        [self convertDistanceFromPresentationToContentCoordinates:touchEvent.majorRadiusTolerance
                                                   usingTransform:transform];
  }
  return self;
}

- (CGFloat)convertDistanceFromPresentationToContentCoordinates:(CGFloat)distance
                                                usingTransform:(CGAffineTransform)transform {
  return CGPointDistance(CGPointApplyAffineTransform(CGPointMake(distance, 0), transform),
                         CGPointApplyAffineTransform(CGPointZero, transform));
}

#pragma mark -
#pragma mark Proxying to LTTouchEvent
#pragma mark -

- (BOOL)conformsToProtocol:(Protocol *)protocol {
  return [super conformsToProtocol:protocol] || [self.touchEvent conformsToProtocol:protocol];
}

- (BOOL)respondsToSelector:(SEL)selector {
  return [super respondsToSelector:selector] || [self.touchEvent respondsToSelector:selector];
}

- (id)forwardingTargetForSelector:(SEL)selector {
  return [self.touchEvent respondsToSelector:selector] ? self.touchEvent :
      [super forwardingTargetForSelector:selector];
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (BOOL)isEqual:(LTContentTouchEvent *)contentTouchEvent {
  if (contentTouchEvent == self) {
    return YES;
  }

  if (![contentTouchEvent isKindOfClass:[LTContentTouchEvent class]]) {
    return NO;
  }

  return [self.touchEvent isEqual:contentTouchEvent.touchEvent] &&
      self.contentLocation == contentTouchEvent.contentLocation &&
      self.previousContentLocation == contentTouchEvent.previousContentLocation &&
      self.contentSize == contentTouchEvent.contentSize &&
      self.contentZoomScale == contentTouchEvent.contentZoomScale;
}

- (NSUInteger)hash {
  return self.touchEvent.hash ^ std::hash<CGPoint>()(self.contentLocation) ^
      std::hash<CGPoint>()(self.previousContentLocation) ^ std::hash<CGSize>()(self.contentSize) ^
      std::hash<CGFloat>()(self.contentZoomScale);
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p, touch event: %@, content location: %@, "
          "previous content location: %@, content size: %@, content zoom scale: %g>",
          [self class], self, [self.touchEvent description],
          NSStringFromCGPoint(self.contentLocation),
          NSStringFromCGPoint(self.previousContentLocation), NSStringFromCGSize(self.contentSize),
          self.contentZoomScale];
}

#pragma mark -
#pragma mark NSCopying
#pragma mark -

- (id)copyWithZone:(nullable NSZone __unused *)zone {
  return self;
}

@end

NS_ASSUME_NONNULL_END
