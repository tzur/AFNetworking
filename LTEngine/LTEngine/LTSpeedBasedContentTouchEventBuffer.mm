// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTSpeedBasedContentTouchEventBuffer.h"

#import "LTContentTouchEvent.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTSpeedBasedContentTouchEventBuffer ()

/// Content touch events currently buffered by this instance. Is empty in idle state or if no events
/// are currently buffered.
@property (strong, nonatomic) NSArray<LTContentTouchEvent *> *bufferedEvents;

@end

@implementation LTSpeedBasedContentTouchEventBuffer

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)init {
  if (self = [super init]) {
    _bufferedEvents = @[];
    _maxSpeed = 5000;
    _timeIntervals = lt::Interval<NSTimeInterval>({(NSTimeInterval)1.0 / 120,
                                                   (NSTimeInterval)1.0 / 20});
  }
  return self;
}

#pragma mark -
#pragma mark Public API
#pragma mark -

- (NSArray<LTContentTouchEvent *> *)
    processAndPossiblyBufferContentTouchEvents:(NSArray<LTContentTouchEvent *> *)events
                               returnAllEvents:(BOOL)returnAllEvents {
  if (events.count && !events.firstObject.previousTimestamp) {
    LTAssert(!self.bufferedEvents.count);
  }

  if (returnAllEvents) {
    auto bufferedEvents = self.bufferedEvents;
    [self reset];
    return [bufferedEvents arrayByAddingObjectsFromArray:events];
  }

  if (!events.count) {
    return @[];
  }

  NSMutableArray<LTContentTouchEvent *> *mutableEvents = [self.bufferedEvents mutableCopy];
  [mutableEvents addObjectsFromArray:events];

  BOOL inActiveState = mutableEvents.firstObject.previousTimestamp != nil;

  NSTimeInterval comparisonTimestamp = inActiveState ?
      [mutableEvents.firstObject.previousTimestamp doubleValue] :
      mutableEvents.firstObject.timestamp;

  NSMutableArray<LTContentTouchEvent *> *mutableBufferedEvents = [NSMutableArray array];

  for (NSUInteger i = mutableEvents.count; i > (inActiveState ? 0 : 1); --i) {
    LTContentTouchEvent *event = mutableEvents[i - 1];
    if (!event.speedInViewCoordinates) {
      // No buffering possible since no speed available.
      break;
    }

    CGFloat factor = std::min([event.speedInViewCoordinates CGFloatValue] / self.maxSpeed,
                              (CGFloat)1.0);
    if (event.timestamp - comparisonTimestamp < self.timeIntervals.valueAt(factor)) {
      [mutableEvents removeObject:event];
      [mutableBufferedEvents insertObject:event atIndex:0];
    } else {
      // The currently processed event and the subsequent ones lie too far in the past and should
      // therefore be returned immediately rather than being buffered.
      break;
    }
  }

  self.bufferedEvents = [mutableBufferedEvents copy];
  return [mutableEvents copy];
}

#pragma mark -
#pragma mark Auxiliary Methods
#pragma mark -

- (void)reset {
  self.bufferedEvents = @[];
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (void)setMaxSpeed:(CGFloat)maxSpeed {
  LTParameterAssert(maxSpeed > 0, @"Maxium speed (%g) must be non-negative", maxSpeed);
  _maxSpeed = maxSpeed;
}

@end

NS_ASSUME_NONNULL_END

