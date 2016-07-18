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

/// Lock used used to prevent potential race conditions where a beginning or terminating touch event
/// sequence is currently being handled on a thread \c A and the \c displayLink triggers the
/// forwarding of stationary touch events on a different thread \c B, causing an interleaved
/// execution pattern of the two relevant methods.
@property (readonly, nonatomic) NSLock *lock;

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
    _lock = [[NSLock alloc] init];
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
  [self lockAndExecute:^{
    [super touchesBegan:touches withEvent:event];
    [self updateMapTableWithBeginningTouches:touches];
    [self updateDisplayLink];
    [self delegateTouches:touches event:event sequenceState:LTTouchEventSequenceStateStart];
  }];
}

- (void)lockAndExecute:(void(^)())block {
  [self.lock lock];
  block();
  [self.lock unlock];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event {
  [super touchesMoved:touches withEvent:event];
  [self delegateTouches:touches event:event sequenceState:LTTouchEventSequenceStateContinuation];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event {
  [self lockAndExecute:^{
    [super touchesEnded:touches withEvent:event];
    [self delegateTouches:touches event:event sequenceState:LTTouchEventSequenceStateEnd];
    [self updateMapTableWithTerminatingTouches:touches];
    [self updateDisplayLink];
  }];
}

- (void)touchesCancelled:(nullable NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event {
  [self lockAndExecute:^{
    [super touchesCancelled:touches withEvent:event];
    [self delegateTouches:touches event:event sequenceState:LTTouchEventSequenceStateCancellation];
    [self updateMapTableWithTerminatingTouches:touches];
    [self updateDisplayLink];
  }];
}

- (void)touchesEstimatedPropertiesUpdated:(NSSet<UITouch *> *)touches {
  [super touchesEstimatedPropertiesUpdated:touches];

  NSArray<UITouch *> *sortedMainTouches = [self sortedTouches:[touches allObjects]];

  LTMutableTouchEvents *mutableTouchEvents =
      [NSMutableArray arrayWithCapacity:sortedMainTouches.count];

  for (UITouch *touch in sortedMainTouches) {
    NSNumber *boxedSequenceID = [self.touchToSequenceID objectForKey:touch];
    LTAssert(boxedSequenceID,
             @"Touch (%@) belonging to a currently occurring touch sequence should exist in the "
             "map table", touch);
    NSUInteger sequenceID = [boxedSequenceID unsignedIntegerValue];
    [mutableTouchEvents addObject:[LTTouchEvent touchEventWithPropertiesOfTouch:touch
                                                                     sequenceID:sequenceID]];
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

  [self.delegate touchEventSequencesWithIDs:sequenceIDs
                        terminatedWithState:LTTouchEventSequenceStateCancellation];
  [self.touchToSequenceID removeAllObjects];
}

#pragma mark -
#pragma mark Forwarding of stationary touches
#pragma mark -

- (void)forwardStationaryTouchEvents:(CADisplayLink __unused *)link {
  if (![self.lock tryLock]) {
    return;
  }

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
  [self.lock unlock];
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

- (void)updateMapTableWithTerminatingTouches:(NSSet<UITouch *> *)touches {
  for (UITouch *touch in touches) {
    [self.touchToSequenceID removeObjectForKey:touch];
  }
}

#pragma mark -
#pragma mark Auxiliary methods - Display Link
#pragma mark -

- (void)updateDisplayLink {
  self.displayLink.paused = self.touchToSequenceID.count == 0;
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
                            withSequenceID:(NSUInteger)sequenceID inEvent:(UIEvent *)event {
  if (![event respondsToSelector:@selector(coalescedTouchesForTouch:)]) {
    return @[[LTTouchEvent touchEventWithPropertiesOfTouch:mainTouch sequenceID:sequenceID]];
  }

  // Note that, according to Apple's documentation, one is supposed to use either main touches or
  // coalesced touches. Never should one mix them. Hence, the coalesced touches "include the main
  // touch" in the form of a separate instance and the main touch itself can be ignored when working
  // with coalesced touches.
  //
  // @see https://developer.apple.com/videos/play/wwdc2015-233/ for more details.

  NSArray<UITouch *> *sortedCoalescedTouches =
      [self sortedTouches:[event coalescedTouchesForTouch:mainTouch]];
  return [self touchEventsForTouches:sortedCoalescedTouches withSequenceID:sequenceID];
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
                                            inEvent:(UIEvent *)event {
  if (![event respondsToSelector:@selector(predictedTouchesForTouch:)]) {
    return @[];
  }

  NSArray<UITouch *> *sortedPredictedTouches =
      [self sortedTouches:[event predictedTouchesForTouch:mainTouch]];
  return [self touchEventsForTouches:sortedPredictedTouches withSequenceID:sequenceID];
}

@end

NS_ASSUME_NONNULL_END
