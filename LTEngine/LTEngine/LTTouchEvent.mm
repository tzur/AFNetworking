// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTTouchEvent.h"

NS_ASSUME_NONNULL_BEGIN

@implementation LTTouchEvent

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithSequenceID:(NSUInteger)sequenceID timeStamp:(NSTimeInterval)timeStamp
                              view:(nullable UIView *)view viewLocation:(CGPoint)viewLocation
              previousViewLocation:(CGPoint)previousViewLocation
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
  if (self = [super init]) {
    _sequenceID = sequenceID;
    _timestamp = timeStamp;
    _view = view;
    _viewLocation = viewLocation;
    _previousViewLocation = previousViewLocation;
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
  }
  return self;
}

+ (instancetype)touchEventWithPropertiesOfTouch:(UITouch *)touch sequenceID:(NSUInteger)sequenceID {
  return [[LTTouchEvent alloc] initWithSequenceID:sequenceID timeStamp:touch.timestamp
                                             view:touch.view
                                     viewLocation:[touch locationInView:touch.view]
                             previousViewLocation:[touch previousLocationInView:touch.view]
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
  // Type is available only since iOS 9.0. Azimuth angle is available only since iOS 9.1.
  if (![touch respondsToSelector:@selector(type)] || touch.type != UITouchTypeStylus ||
      ![touch respondsToSelector:@selector(azimuthAngleInView:)]) {
    return nil;
  }
  return @([touch azimuthAngleInView:nil]);
}

+ (LTVector2)azimuthUnitVectorOfTouch:(UITouch *)touch {
  // Type is available only since iOS 9.0. Azimuth unit vector is available only since iOS 9.1.
  if (![touch respondsToSelector:@selector(type)] || touch.type != UITouchTypeStylus ||
      ![touch respondsToSelector:@selector(azimuthUnitVectorInView:)]) {
    return LTVector2::null();
  }

  CGVector vector = [touch azimuthUnitVectorInView:nil];
  return LTVector2(vector.dx, vector.dy);
}

+ (nullable NSNumber *)altitudeAngleOfTouch:(UITouch *)touch {
  // Type is available only since iOS 9.0. Altitude angle is available only since iOS 9.1.
  if (![touch respondsToSelector:@selector(type)] || touch.type != UITouchTypeStylus ||
      ![touch respondsToSelector:@selector(altitudeAngle)]) {
    return nil;
  }
  return @(touch.altitudeAngle);
}

+ (nullable NSNumber *)estimationUpdateIndexOfTouch:(UITouch *)touch {
  // Estimation update index is available only since iOS 9.1.
  return [touch respondsToSelector:@selector(estimationUpdateIndex)] ?
      touch.estimationUpdateIndex : nil;
}

+ (UITouchProperties)estimatedPropertiesOfTouch:(UITouch *)touch {
  // Estimated properties are available only since iOS 9.1.
  if (![touch respondsToSelector:@selector(estimatedProperties)]) {
    return 0;
  }
  return touch.estimatedProperties;
}

+ (UITouchProperties)propertiesExpectingUpdateOfTouch:(UITouch *)touch {
  // Estimated properties expecting updates are available only since iOS 9.1.
  if (![touch respondsToSelector:@selector(estimatedPropertiesExpectingUpdates)]) {
    return 0;
  }
  return touch.estimatedPropertiesExpectingUpdates;
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

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
