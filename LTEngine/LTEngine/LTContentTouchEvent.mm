// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTContentTouchEvent.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTContentTouchEvent ()

/// Underlying touch event.
@property (readonly, nonatomic) id<LTTouchEvent> touchEvent;

@end

@implementation LTContentTouchEvent

@synthesize contentLocation = _contentLocation;
@synthesize previousContentLocation = _previousContentLocation;
@synthesize contentZoomScale = _contentZoomScale;

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

- (instancetype)initWithTouchEvent:(id<LTTouchEvent>)touchEvent
                   contentLocation:(CGPoint)contentLocation
           previousContentLocation:(CGPoint)previousContentLocation
                  contentZoomScale:(CGFloat)contentZoomScale {
  LTParameterAssert(touchEvent);

  if (self = [super init]) {
    _touchEvent = [touchEvent copyWithZone:nil];
    _contentLocation = contentLocation;
    _previousContentLocation = previousContentLocation;
    _contentZoomScale = contentZoomScale;
  }
  return self;
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

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p, touch event: %@, content location: (%g, %g), "
          "previous content location: (%g, %g)>", [self class], self, [self.touchEvent description],
          self.contentLocation.x, self.contentLocation.y, self.previousContentLocation.x,
          self.previousContentLocation.y];
}

#pragma mark -
#pragma mark NSCopying
#pragma mark -

- (id)copyWithZone:(nullable NSZone __unused *)zone {
  return self;
}

@end

NS_ASSUME_NONNULL_END
