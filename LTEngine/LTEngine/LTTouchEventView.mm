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
  }
  return self;
}

#pragma mark -
#pragma mark UIResponder
#pragma mark -

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event {
  [super touchesBegan:touches withEvent:event];
  [self updateMapTableWithBeginningTouches:touches];
  [self delegateTouches:touches event:event sequenceState:LTTouchEventSequenceStateStart];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event {
  [super touchesMoved:touches withEvent:event];
  [self delegateTouches:touches event:event sequenceState:LTTouchEventSequenceStateContinuation];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event {
  [super touchesEnded:touches withEvent:event];
  [self delegateTouches:touches event:event sequenceState:LTTouchEventSequenceStateEnd];
  [self updateMapTableWithTerminatingTouches:touches];
}

- (void)touchesCancelled:(nullable NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event {
  [super touchesCancelled:touches withEvent:event];
  [self delegateTouches:touches event:event sequenceState:LTTouchEventSequenceStateCancellation];
  [self updateMapTableWithTerminatingTouches:touches];
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
#pragma mark LTTouchEventRetrieval
#pragma mark -

- (NSSet<id<LTTouchEvent>> *)stationaryTouchEvents {
  NSMutableSet<id<LTTouchEvent>> *stationaryTouchEvents = [NSMutableSet set];

  NSEnumerator *keyEnumerator = [self.touchToSequenceID keyEnumerator];

  while (UITouch *touch = [keyEnumerator nextObject]) {
    if (touch.phase == UITouchPhaseStationary) {
      NSUInteger sequenceID = [[self.touchToSequenceID objectForKey:touch] unsignedIntegerValue];
      [stationaryTouchEvents addObject:[LTTouchEvent touchEventWithPropertiesOfTouch:touch
                                                                          sequenceID:sequenceID]];
    }
  }
  return [stationaryTouchEvents copy];
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
#pragma mark Auxiliary methods - Delegate Calls
#pragma mark -

- (void)delegateTouches:(NSSet<UITouch *> *)touches event:(nullable UIEvent *)event
          sequenceState:(LTTouchEventSequenceState)state {
  NSArray<UITouch *> *sortedMainTouches = [self sortedTouches:[touches allObjects]];

  for (UITouch *mainTouch in sortedMainTouches) {
    NSNumber *boxedSequenceID = [self.touchToSequenceID objectForKey:mainTouch];
    if (!boxedSequenceID) {
      // The sequenceID does not exist, since it has been removed due to an external termination
      /// request.
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

  // Note that according one is supposed to use either main touches or coalesced touches. Never
  // should one mix them. Hence, the coalesced touches "include the main touch" in the form of a
  // separate instance and the main touch itself can be ignored when working with coalesced touches.
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
