// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTTouchEvent.h"

#import <LTKit/LTHashExtensions.h>

NS_ASSUME_NONNULL_BEGIN

@implementation LTTouchEvent

@synthesize sequenceID = _sequenceID;
@synthesize timestamp = _timestamp;
@synthesize view = _view;
@synthesize viewLocation = _viewLocation;
@synthesize previousViewLocation = _previousViewLocation;
@synthesize previousTimestamp = _previousTimestamp;
@synthesize velocityInViewCoordinates = _velocityInViewCoordinates;
@synthesize speedInViewCoordinates = _speedInViewCoordinates;
@synthesize phase = _phase;
@synthesize tapCount = _tapCount;
@synthesize majorRadius = _majorRadius;
@synthesize majorRadiusTolerance = _majorRadiusTolerance;
@synthesize type = _type;
@synthesize force = _force;
@synthesize maximumPossibleForce = _maximumPossibleForce;
@synthesize azimuthAngle = _azimuthAngle;
@synthesize azimuthUnitVector = _azimuthUnitVector;
@synthesize altitudeAngle = _altitudeAngle;
@synthesize estimationUpdateIndex = _estimationUpdateIndex;
@synthesize estimatedProperties = _estimatedProperties;
@synthesize estimatedPropertiesExpectingUpdates = _estimatedPropertiesExpectingUpdates;

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithSequenceID:(NSUInteger)sequenceID timestamp:(NSTimeInterval)timestamp
                              view:(nullable UIView *)view viewLocation:(CGPoint)viewLocation
              previousViewLocation:(CGPoint)previousViewLocation
                 previousTimestamp:(nullable NSNumber *)previousTimestamp
                             phase:(UITouchPhase)phase tapCount:(NSUInteger)tapCount
                       majorRadius:(CGFloat)majorRadius
              majorRadiusTolerance:(CGFloat)majorRadiusTolerance
                              type:(UITouchType)type
                             force:(nullable NSNumber *)force
              maximumPossibleForce:(nullable NSNumber *)maximumPossibleForce
                      azimuthAngle:(nullable NSNumber *)azimuthAngle
                 azimuthUnitVector:(LTVector2)azimuthUnitVector
                     altitudeAngle:(nullable NSNumber *)altitudeAngle
             estimationUpdateIndex:(nullable NSNumber *)estimationUpdateIndex
               estimatedProperties:(UITouchProperties)estimatedProperties
        propertiesExpectingUpdates:(UITouchProperties)propertiesExpectingUpdates {
  if (previousTimestamp) {
    LTParameterAssert(timestamp >= [previousTimestamp doubleValue], @"Provided invalid "
                      "combination of timestamp %g and previous timestamp (%g)", timestamp,
                      [previousTimestamp doubleValue]);
  }

  if (self = [super init]) {
    _sequenceID = sequenceID;
    _timestamp = timestamp;
    _view = view;
    _viewLocation = viewLocation;
    _previousViewLocation = previousViewLocation;
    _previousTimestamp = previousTimestamp;
    _phase = phase;
    _tapCount = tapCount;
    _majorRadius = majorRadius;
    _majorRadiusTolerance = majorRadiusTolerance;
    _type = type;
    _force = force;
    _maximumPossibleForce = maximumPossibleForce;
    _azimuthAngle = azimuthAngle;
    _azimuthUnitVector = azimuthUnitVector;
    _altitudeAngle = altitudeAngle;
    _estimationUpdateIndex = estimationUpdateIndex;
    _estimatedProperties = estimatedProperties;
    _estimatedPropertiesExpectingUpdates = propertiesExpectingUpdates;

    // Derived properties.
    _velocityInViewCoordinates =
        previousTimestamp && timestamp > [previousTimestamp doubleValue] ?
        LTVector2(viewLocation - previousViewLocation) /
        (timestamp - [previousTimestamp doubleValue]) : LTVector2::null();
    _speedInViewCoordinates = !_velocityInViewCoordinates.isNull() ?
        @(_velocityInViewCoordinates.length()) : nil;
  }
  return self;
}

+ (instancetype)touchEventWithPropertiesOfTouch:(UITouch *)touch
                                     sequenceID:(NSUInteger)sequenceID {
  return [self touchEventWithPropertiesOfTouch:touch previousTimestamp:nil sequenceID:sequenceID];
}

+ (instancetype)touchEventWithPropertiesOfTouch:(UITouch *)touch
                              previousTimestamp:(nullable NSNumber *)previousTimestamp
                                     sequenceID:(NSUInteger)sequenceID {
  return [self touchEventWithPropertiesOfTouch:touch timestamp:touch.timestamp
                             previousTimestamp:previousTimestamp sequenceID:sequenceID];
}

+ (instancetype)touchEventWithPropertiesOfTouch:(UITouch *)touch timestamp:(NSTimeInterval)timestamp
                              previousTimestamp:(nullable NSNumber *)previousTimestamp
                                     sequenceID:(NSUInteger)sequenceID {
  CGPoint viewLocation;
  viewLocation = [touch preciseLocationInView:touch.view];

  CGPoint previousViewLocation;
  previousViewLocation = [touch precisePreviousLocationInView:touch.view];

  return [[LTTouchEvent alloc] initWithSequenceID:sequenceID timestamp:timestamp view:touch.view
                                     viewLocation:viewLocation
                             previousViewLocation:previousViewLocation
                                previousTimestamp:previousTimestamp
                                            phase:touch.phase
                                         tapCount:touch.tapCount
                                      majorRadius:touch.majorRadius
                             majorRadiusTolerance:touch.majorRadiusTolerance
                                             type:[self typeOfTouch:touch]
                                            force:[self forceOfTouch:touch]
                             maximumPossibleForce:[self maximumForceOfTouch:touch]
                                     azimuthAngle:[self azimuthAngleOfTouch:touch]
                                azimuthUnitVector:[self azimuthUnitVectorOfTouch:touch]
                                    altitudeAngle:[self altitudeAngleOfTouch:touch]
                            estimationUpdateIndex:[self estimationUpdateIndexOfTouch:touch]
                              estimatedProperties:[self estimatedPropertiesOfTouch:touch]
                       propertiesExpectingUpdates:[self propertiesExpectingUpdateOfTouch:touch]];
}

#pragma mark -
#pragma mark iOS-dependent Touch Properties
#pragma mark -

+ (UITouchType)typeOfTouch:(UITouch *)touch {
  // Type is available only since iOS 9.0.
  if (![touch respondsToSelector:@selector(type)]) {
    return UITouchTypeDirect;
  }
  return touch.type;
}

+ (nullable NSNumber *)forceOfTouch:(UITouch *)touch {
  // Force is available only since iOS 9.0.
  if (![touch respondsToSelector:@selector(force)]) {
    return nil;
  }
  return @(touch.force);
}

+ (nullable NSNumber *)maximumForceOfTouch:(UITouch *)touch {
  // Maximum force is available only since iOS 9.0.
  if (![touch respondsToSelector:@selector(maximumPossibleForce)]) {
    return nil;
  }
  return @(touch.maximumPossibleForce);
}

+ (nullable NSNumber *)azimuthAngleOfTouch:(UITouch *)touch {
  return touch.type == UITouchTypeStylus ? @([touch azimuthAngleInView:nil]) : nil;
}

+ (LTVector2)azimuthUnitVectorOfTouch:(UITouch *)touch {
  if (touch.type == UITouchTypeStylus) {
    CGVector vector = [touch azimuthUnitVectorInView:nil];
    return LTVector2(vector.dx, vector.dy);
  }
  return LTVector2::null();
}

+ (nullable NSNumber *)altitudeAngleOfTouch:(UITouch *)touch {
  return touch.type == UITouchTypeStylus ? @(touch.altitudeAngle) : nil;
}

+ (nullable NSNumber *)estimationUpdateIndexOfTouch:(UITouch *)touch {
  return touch.estimationUpdateIndex;
}

+ (UITouchProperties)estimatedPropertiesOfTouch:(UITouch *)touch {
  return touch.estimatedProperties;
}

+ (UITouchProperties)propertiesExpectingUpdateOfTouch:(UITouch *)touch {
  return touch.estimatedPropertiesExpectingUpdates;
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (BOOL)isEqual:(LTTouchEvent *)touchEvent {
  if (touchEvent == self) {
    return YES;
  }

  if (![touchEvent isKindOfClass:[LTTouchEvent class]]) {
    return NO;
  }

  return self.sequenceID == touchEvent.sequenceID &&
      self.timestamp == touchEvent.timestamp &&
      self.view == touchEvent.view &&
      self.viewLocation == touchEvent.viewLocation &&
      self.previousViewLocation == touchEvent.previousViewLocation &&
      self.phase == touchEvent.phase &&
      self.tapCount == touchEvent.tapCount &&
      self.majorRadius == touchEvent.majorRadius &&
      self.majorRadiusTolerance == touchEvent.majorRadiusTolerance &&
      self.type == touchEvent.type &&
      (self.force == touchEvent.force || [self.force isEqual:touchEvent.force]) &&
      (self.maximumPossibleForce == touchEvent.maximumPossibleForce ||
       [self.maximumPossibleForce isEqual:touchEvent.maximumPossibleForce]) &&
      (self.azimuthAngle == touchEvent.azimuthAngle ||
       [self.azimuthAngle isEqual:touchEvent.azimuthAngle]) &&
      ((self.azimuthUnitVector.isNull() && touchEvent.azimuthUnitVector.isNull()) ||
       self.azimuthUnitVector == touchEvent.azimuthUnitVector) &&
      (self.altitudeAngle == touchEvent.altitudeAngle ||
       [self.altitudeAngle isEqual:touchEvent.altitudeAngle]) &&
      [self.estimationUpdateIndex isEqual:touchEvent.estimationUpdateIndex] &&
      self.estimatedProperties == touchEvent.estimatedProperties &&
      self.estimatedPropertiesExpectingUpdates == touchEvent.estimatedPropertiesExpectingUpdates;
}

- (NSUInteger)hash {
  return self.sequenceID ^
      std::hash<NSTimeInterval>()(self.timestamp) ^
      self.view.hash ^
      std::hash<CGPoint>()(self.viewLocation) ^
      std::hash<CGPoint>()(self.previousViewLocation) ^
      self.phase ^
      self.tapCount ^
      std::hash<CGFloat>()(self.majorRadius) ^
      std::hash<CGFloat>()(self.majorRadiusTolerance) ^
      self.type ^
      self.force.hash ^
      self.maximumPossibleForce.hash ^
      self.azimuthAngle.hash ^
      std::hash<CGPoint>()((CGPoint)self.azimuthUnitVector) ^
      self.altitudeAngle.hash ^
      self.estimationUpdateIndex.hash ^
      self.estimatedProperties ^
      self.estimatedPropertiesExpectingUpdates;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p, sequence ID: %lu, timestamp: %g, view: %@, "
          @"view location: (%g, %g), previous view location: (%g, %g), phase: %ld, tap count: %lu, "
          @"radius: %g, radius tolerance: %g, type: %ld, force: %g, maximum possible force: %g, "
          @"azimuth angle: %g, azimuth unit vector: (%g, %g), altitude angle: %g, "
          @"estimation update index: %lu, estimated properties: %ld, "
          @"estimated properties expecting updates: %ld>",
          [self class], self, (unsigned long)self.sequenceID, self.timestamp, self.view,
          self.viewLocation.x, self.viewLocation.y, self.previousViewLocation.x,
          self.previousViewLocation.y, (long)self.phase, (unsigned long)self.tapCount,
          self.majorRadius, self.majorRadiusTolerance, (long)self.type,
          [self.force CGFloatValue], [self.maximumPossibleForce CGFloatValue],
          [self.azimuthAngle CGFloatValue], self.azimuthUnitVector.x, self.azimuthUnitVector.y,
          [self.altitudeAngle CGFloatValue],
          (unsigned long)[self.estimationUpdateIndex unsignedIntegerValue],
          (long)self.estimatedProperties, (long)self.estimatedPropertiesExpectingUpdates];
}

#pragma mark -
#pragma mark NSCopying
#pragma mark -

- (id)copyWithZone:(nullable NSZone __unused *)zone {
  return self;
}

@end

NS_ASSUME_NONNULL_END
