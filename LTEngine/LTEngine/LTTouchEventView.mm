// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTTouchEventView.h"

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
    self.sequenceID = 0;
    _displayLink = [self displayLinkForStationaryTouchEvents];
    _processInfo = [NSProcessInfo processInfo];
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
  [self updateDisplayLink];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event {
  [super touchesMoved:touches withEvent:event];
  [self delegateTouches:touches event:event sequenceState:LTTouchEventSequenceStateContinuation];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event {
  [super touchesEnded:touches withEvent:event];
  [self delegateTouches:touches event:event sequenceState:LTTouchEventSequenceStateEnd];
  [self updateDisplayLink];
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event {
#else
- (void)touchesCancelled:(nullable NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event {
#endif
  [super touchesCancelled:touches withEvent:event];
  [self delegateTouches:touches event:event sequenceState:LTTouchEventSequenceStateCancellation];
  [self updateDisplayLink];
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
    LTTouchEvent *touchEvent = [LTTouchEvent touchEventWithPropertiesOfTouch:touch
                                                                   timestamp:timestamp
                                                                  sequenceID:sequenceID];
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

- (void)updateDisplayLink {
  self.displayLink.paused = self.touchToSequenceID.count == 0 ||
      !self.displayLink.preferredFramesPerSecond;
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

    if (state == LTTouchEventSequenceStateEnd || state == LTTouchEventSequenceStateCancellation) {
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
    return @[[LTTouchEvent touchEventWithPropertiesOfTouch:mainTouch sequenceID:sequenceID]];
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

  if (!coalescedTouches.count) {
    LogDebug(@"No coalesced touches despite valid event (%@) and main touch (%@)", event,
             mainTouch);
    return @[[LTTouchEvent touchEventWithPropertiesOfTouch:mainTouch sequenceID:sequenceID]];
  }

  return [self touchEventsForTouches:[self sortedTouches:coalescedTouches]
                      withSequenceID:sequenceID];
}

- (LTTouchEvents *)touchEventsForTouches:(NSArray<UITouch *> *)touches
                          withSequenceID:(NSUInteger)sequenceID {
  LTMutableTouchEvents *mutableTouchEvents = [NSMutableArray arrayWithCapacity:touches.count];

  for (UITouch *touch in touches) {
    [mutableTouchEvents addObject:[LTTouchEvent touchEventWithPropertiesOfTouch:touch
                                                                     sequenceID:sequenceID]];
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
      [self sortedTouches:[event predictedTouchesForTouch:mainTouch]];
  return [self touchEventsForTouches:sortedPredictedTouches withSequenceID:sequenceID];
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (NSUInteger)desiredRateForStationaryTouchEventForwarding {
  return self.displayLink.preferredFramesPerSecond;
}

- (void)setDesiredRateForStationaryTouchEventForwarding:(NSUInteger)rate {
  static const NSUInteger kMaximumFrameRate = 60;
  LTParameterAssert(rate <= kMaximumFrameRate, @"Rate (%lu) must not be greater than %lu",
                    (unsigned long)rate, (unsigned long)kMaximumFrameRate);
  self.displayLink.preferredFramesPerSecond = rate;
  [self updateDisplayLink];
}

@end

NS_ASSUME_NONNULL_END
