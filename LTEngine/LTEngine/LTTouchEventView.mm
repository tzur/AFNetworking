// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTTouchEventView.h"

#import <LTKit/NSArray+Functional.h>

#import "LTTouchEvent.h"
#import "LTTouchEventDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTTouchEventView ()

/// Delegate to which converted touch events are delegated.
@property (weak, readwrite, nonatomic) id<LTTouchEventDelegate> delegate;

/// Mapping of weakly held \c UITouch objects to its corresponding boxed sequence ID.
///
/// @important The \c UITouch objects are weakly held since the iOS documentation explicitly forbids
/// strongly holding \c UITouch objects.
@property (strong, nonatomic) NSMapTable<UITouch *, NSNumber *> *touchToSequenceID;

/// Mapping of boxed sequence IDs to boxed \c NSTimeInterval representing the \c timestamp of the
/// most recent touch event provided to the \c delegate.
@property (strong, nonatomic, nullable)
    NSMutableDictionary<NSNumber *, NSNumber *> *sequenceIDToMostRecentTimestamp;

/// Number to use as sequence ID of next starting touch event sequence.
@property (nonatomic) NSUInteger sequenceID;

/// Display link used to trigger forwarding of stationary touch events.
@property (readonly, nonatomic) CADisplayLink *displayLink;

/// Object used to retrieve the system uptime.
@property (readonly, nonatomic) NSProcessInfo *processInfo;

@end

@implementation LTTouchEventView

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithFrame:(CGRect)frame delegate:(id<LTTouchEventDelegate>)delegate {
  LTParameterAssert(delegate, @"Provided touch event delegate must not be nil");
  if (self = [super initWithFrame:frame]) {
    self.delegate = delegate;
    self.touchToSequenceID = [NSMapTable weakToStrongObjectsMapTable];
    self.sequenceIDToMostRecentTimestamp = [NSMutableDictionary dictionary];
    self.sequenceID = 0;
    _displayLink = [self displayLinkForStationaryTouchEvents];
    _processInfo = [NSProcessInfo processInfo];
    _forwardStationaryTouchEvents = YES;
  }
  return self;
}

- (CADisplayLink *)displayLinkForStationaryTouchEvents {
  CADisplayLink *displayLink =
      [CADisplayLink displayLinkWithTarget:self
                                  selector:@selector(forwardStationaryTouchEvents:)];
  [displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
  displayLink.paused = YES;
  return displayLink;
}

#pragma mark -
#pragma mark Deallocation
#pragma mark -

- (void)dealloc {
  [self.displayLink invalidate];
}

#pragma mark -
#pragma mark UIResponder
#pragma mark -

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event {
  [super touchesBegan:touches withEvent:event];
  [self updateMapTableWithBeginningTouches:touches];
  [self delegateTouches:touches event:event sequenceState:LTTouchEventSequenceStateStart];
  [self pauseOrResumeDisplayLink];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event {
  [super touchesMoved:touches withEvent:event];
  [self delegateTouches:touches event:event sequenceState:LTTouchEventSequenceStateContinuation];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event {
  [super touchesEnded:touches withEvent:event];
  [self delegateTouches:touches event:event sequenceState:LTTouchEventSequenceStateEnd];
  [self pauseOrResumeDisplayLink];
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event {
#else
- (void)touchesCancelled:(nullable NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event {
#endif
  [super touchesCancelled:touches withEvent:event];
  [self delegateTouches:touches event:event sequenceState:LTTouchEventSequenceStateCancellation];
  [self pauseOrResumeDisplayLink];
}

- (void)touchesEstimatedPropertiesUpdated:(NSSet<UITouch *> *)touches {
  [super touchesEstimatedPropertiesUpdated:touches];

  if (!touches.count) {
    return;
  }

  NSArray<UITouch *> *sortedMainTouches = [self sortedTouches:[touches allObjects]];

  LTMutableTouchEvents *mutableTouchEvents =
      [NSMutableArray arrayWithCapacity:sortedMainTouches.count];

  for (UITouch *touch in sortedMainTouches) {
    NSNumber * _Nullable boxedSequenceID = [self.touchToSequenceID objectForKey:touch];
    if (!boxedSequenceID) {
      continue;
    }
    NSUInteger sequenceID = [boxedSequenceID unsignedIntegerValue];
    [mutableTouchEvents addObject:[LTTouchEvent touchEventWithPropertiesOfTouch:touch
                                                                     sequenceID:sequenceID]];
  }

  if (!mutableTouchEvents.count) {
    return;
  }

  [self.delegate receivedUpdatesOfTouchEvents:[mutableTouchEvents copy]];
}

#pragma mark -
#pragma mark LTTouchEventCancellation
#pragma mark -

- (void)cancelTouchEventSequences {
  NSSet<NSNumber *> *sequenceIDs =
      [NSSet setWithArray:[[self.touchToSequenceID objectEnumerator] allObjects]];
  if (!sequenceIDs.count) {
    return;
  }

  // Clear the map table before(!) calling the delegate in order to keep this object re-entrant,
  // i.e. nested calls to \c cancelTouchEventSequences do not lead to an infinite loop or other
  // degenerate behavior.
  [self.touchToSequenceID removeAllObjects];
  [self.sequenceIDToMostRecentTimestamp removeAllObjects];
  [self.delegate touchEventSequencesWithIDs:sequenceIDs
                        terminatedWithState:LTTouchEventSequenceStateCancellation];
}

#pragma mark -
#pragma mark Forwarding of stationary touches
#pragma mark -

- (void)forwardStationaryTouchEvents:(CADisplayLink __unused *)link {
  NSTimeInterval timestamp = self.processInfo.systemUptime;

  NSEnumerator *keyEnumerator = [self.touchToSequenceID keyEnumerator];
  while (UITouch *touch = [keyEnumerator nextObject]) {
    if (touch.phase != UITouchPhaseStationary) {
      continue;
    }

    NSUInteger sequenceID = [[self.touchToSequenceID objectForKey:touch] unsignedIntegerValue];
    LTTouchEvent *touchEvent =
        [LTTouchEvent touchEventWithPropertiesOfTouch:touch timestamp:timestamp
                                    previousTimestamp:nil sequenceID:sequenceID];
    self.sequenceIDToMostRecentTimestamp[@(sequenceID)] = @(touchEvent.timestamp);
    [self.delegate
     receivedTouchEvents:@[touchEvent]
     predictedEvents:@[]
     touchEventSequenceState:LTTouchEventSequenceStateContinuationStationary];
  }
}

#pragma mark -
#pragma mark Auxiliary methods - Map Table
#pragma mark -

- (void)updateMapTableWithBeginningTouches:(NSSet<UITouch *> *)touches {
  for (UITouch *touch in touches) {
    LTAssert(![self.touchToSequenceID objectForKey:touch],
             @"Touch (%@) belonging to a starting touch event sequence should not exist in the map"
             "table", touch);
    [self.touchToSequenceID setObject:@(self.sequenceID) forKey:touch];
    ++self.sequenceID;
  }
}

#pragma mark -
#pragma mark Auxiliary methods - Display Link
#pragma mark -

- (void)pauseOrResumeDisplayLink {
  self.displayLink.paused = ![self isCurrentlyReceivingTouchEvents] ||
      !self.forwardStationaryTouchEvents;
}

#pragma mark -
#pragma mark Auxiliary methods - Delegate Calls
#pragma mark -

- (void)delegateTouches:(NSSet<UITouch *> *)touches event:(nullable UIEvent *)event
          sequenceState:(LTTouchEventSequenceState)state {
  NSArray<UITouch *> *sortedMainTouches = [self sortedTouches:[touches allObjects]];

  for (UITouch *mainTouch in sortedMainTouches) {
    NSNumber *boxedSequenceID = [self.touchToSequenceID objectForKey:mainTouch];
    if (!boxedSequenceID) {
      // The sequenceID does not exist, since it has been removed due to an external termination
      // request.
      continue;
    }

    BOOL finalState =
        state == LTTouchEventSequenceStateEnd || state == LTTouchEventSequenceStateCancellation;

    if (finalState) {
      // Remove the touch from the map table before(!) calling the delegate, in order to ensure that
      // possible external termination requests performed as a result of the delegate call only
      // trigger the termination of touches that have not been declared as terminated in the
      // aforementioned delegate call.
      [self.touchToSequenceID removeObjectForKey:mainTouch];
    }

    NSUInteger sequenceID = [boxedSequenceID unsignedIntegerValue];
    [self.delegate receivedTouchEvents:[self touchEventsForMainTouch:mainTouch
                                                      withSequenceID:sequenceID inEvent:event]
                       predictedEvents:[self predictedTouchEventsForMainTouch:mainTouch
                                                               withSequenceID:sequenceID
                                                                      inEvent:event]
               touchEventSequenceState:state];

    if (finalState) {
      [self.sequenceIDToMostRecentTimestamp removeObjectForKey:boxedSequenceID];
    }
  }
}

- (NSArray<UITouch *> *)sortedTouches:(NSArray<UITouch *> *)touches {
  return [touches sortedArrayUsingComparator:^NSComparisonResult(UITouch *touch1, UITouch *touch2) {
    if (touch1.timestamp < touch2.timestamp) {
      return NSOrderedAscending;
    } else if (touch1.timestamp == touch2.timestamp) {
      return NSOrderedSame;
    }
    return NSOrderedDescending;
  }];
}

- (LTTouchEvents *)touchEventsForMainTouch:(UITouch *)mainTouch
                            withSequenceID:(NSUInteger)sequenceID
                                   inEvent:(nullable UIEvent *)event {
  if (![event respondsToSelector:@selector(coalescedTouchesForTouch:)]) {
    LTTouchEvents *touchEvents =
        @[[LTTouchEvent
           touchEventWithPropertiesOfTouch:mainTouch
           previousTimestamp:self.sequenceIDToMostRecentTimestamp[@(sequenceID)]
           sequenceID:sequenceID]];
    self.sequenceIDToMostRecentTimestamp[@(sequenceID)] = @(mainTouch.timestamp);
    return touchEvents;
  }

  // Note that, according to Apple's documentation, one is supposed to use either main touches or
  // coalesced touches. Never should one mix them. Hence, the coalesced touches "include the main
  // touch" in the form of a separate instance and the main touch itself can be ignored when working
  // with coalesced touches.
  //
  // @see https://developer.apple.com/videos/play/wwdc2015-233/ for more details.
  //
  // That said, in rare cases, the call to the \c coalescedTouchesForTouch: method returns \c nil,
  // even when both the \c UIEvent on which the method is called and the \c UITouch provided as
  // parameter are not \c nil. Hence, this case is specifically handled by returning an
  // \c LTTouchEvent constructed from the main touch.
  NSArray<UITouch *> * _Nullable coalescedTouches = [event coalescedTouchesForTouch:mainTouch];

  NSNumber * _Nullable mostRecentTimestamp = self.sequenceIDToMostRecentTimestamp[@(sequenceID)];

  if (!coalescedTouches.count) {
    if (mainTouch.phase != UITouchPhaseCancelled) {
      LogDebug(@"No coalesced touches despite valid event (%@) and non-cancelled main touch (%@)",
               event, mainTouch);
    }

    NSTimeInterval timestamp = std::max((NSTimeInterval)[mostRecentTimestamp doubleValue],
                                        mainTouch.timestamp);
    LTTouchEvents *touchEvents =
        @[[LTTouchEvent touchEventWithPropertiesOfTouch:mainTouch timestamp:timestamp
                                      previousTimestamp:mostRecentTimestamp sequenceID:sequenceID]];
    self.sequenceIDToMostRecentTimestamp[@(sequenceID)] = @(mainTouch.timestamp);
    return touchEvents;
  }

  LTTouchEvents *touchEvents =
      [self touchEventsForTouches:[self sortedTouches:coalescedTouches]
                previousTimestamp:self.sequenceIDToMostRecentTimestamp[@(sequenceID)]
                   withSequenceID:sequenceID];
  self.sequenceIDToMostRecentTimestamp[@(sequenceID)] = @(touchEvents.lastObject.timestamp);
  return touchEvents;
}

- (LTTouchEvents *)touchEventsForTouches:(NSArray<UITouch *> *)touches
                       previousTimestamp:(nullable NSNumber *)previousTimestamp
                          withSequenceID:(NSUInteger)sequenceID {
  LTMutableTouchEvents *mutableTouchEvents = [NSMutableArray arrayWithCapacity:touches.count];

  for (UITouch *touch in touches) {
    // Use the maximum of the previously stored timestamp and the current timestamp of the touch
    // since in rare occasions the timestamp of the touch is smaller than the previously stored one.
    NSTimeInterval timestamp = std::max((NSTimeInterval)[previousTimestamp doubleValue],
                                        touch.timestamp);
    LTTouchEvent *touchEvent = [LTTouchEvent touchEventWithPropertiesOfTouch:touch
                                                                   timestamp:timestamp
                                                           previousTimestamp:previousTimestamp
                                                                  sequenceID:sequenceID];
    previousTimestamp = @(touchEvent.timestamp);
    [mutableTouchEvents addObject:touchEvent];
  }

  return [mutableTouchEvents copy];
}

- (LTTouchEvents *)predictedTouchEventsForMainTouch:(UITouch *)mainTouch
                                     withSequenceID:(NSUInteger)sequenceID
                                            inEvent:(nullable UIEvent *)event {
  if (![event respondsToSelector:@selector(predictedTouchesForTouch:)]) {
    return @[];
  }

  NSArray<UITouch *> *sortedPredictedTouches =
      [self sortedTouches:[event predictedTouchesForTouch:mainTouch] ?: @[]];

  return [sortedPredictedTouches lt_map:^LTTouchEvent *(UITouch *touch) {
    return [LTTouchEvent touchEventWithPropertiesOfTouch:touch sequenceID:sequenceID];
  }];
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (void)setForwardStationaryTouchEvents:(BOOL)forwardStationaryTouchEvents {
  _forwardStationaryTouchEvents = forwardStationaryTouchEvents;
  [self pauseOrResumeDisplayLink];
}

- (BOOL)isCurrentlyReceivingTouchEvents {
  return self.touchToSequenceID.count != 0;
}

@end

NS_ASSUME_NONNULL_END
