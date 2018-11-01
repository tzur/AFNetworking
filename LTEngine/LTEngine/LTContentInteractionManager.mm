// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTContentInteractionManager.h"

#import "LTContentTouchEventDelegate.h"
#import "LTTouchEventCancellation.h"
#import "LTTouchEventView.h"

NS_ASSUME_NONNULL_BEGIN

@implementation LTInteractionGestureRecognizers

- (instancetype)init {
  return [self initWithTapRecognizer:nil panRecognizer:nil pinchRecognizer:nil];
}

- (instancetype)initWithTapRecognizer:(nullable UITapGestureRecognizer *)tapRecognizer
                        panRecognizer:(nullable UIPanGestureRecognizer *)panRecognizer
                      pinchRecognizer:(nullable UIPinchGestureRecognizer *)pinchRecognizer {
  if (self = [super init]) {
    _tapGestureRecognizer = tapRecognizer;
    _panGestureRecognizer = panRecognizer;
    _pinchGestureRecognizer = pinchRecognizer;
  }
  return self;
}

@end

@interface LTContentInteractionManager ()

/// View holding the gesture recognizers managed by this instance.
@property (readonly, nonatomic) LTTouchEventView *touchEventView;

@end

@implementation LTContentInteractionManager

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithView:(LTTouchEventView *)view {
  LTParameterAssert(view);
  LTParameterAssert(!view.gestureRecognizers.count, @"Given view has gesture recognizers (%@)",
                    view.gestureRecognizers);

  if (self = [super init]) {
    _touchEventView = view;
    self.interactionMode = LTInteractionModeAllGestures;
    self.defaultGestureRecognizers = [[LTInteractionGestureRecognizers alloc] init];
  }
  return self;
}

#pragma mark -
#pragma mark LTContentInteractionManager
#pragma mark -

@synthesize interactionMode = _interactionMode;
@synthesize contentTouchEventDelegate = _contentTouchEventDelegate;

- (void)setInteractionMode:(LTInteractionMode)interactionMode {
  if ([self forwardTouchEventsForMode:_interactionMode] !=
      [self forwardTouchEventsForMode:interactionMode]) {
    [self.touchEventView cancelTouchEventSequences];
  }

  _interactionMode = interactionMode;
  [self setupGestureRecognizers];
}

- (void)setupGestureRecognizers {
  if (self.defaultGestureRecognizers.tapGestureRecognizer) {
    [self enableRecognizer:self.defaultGestureRecognizers.tapGestureRecognizer
                   forMode:LTInteractionModeTap];
  }
  if (self.defaultGestureRecognizers.panGestureRecognizer) {
    [self enableRecognizer:self.defaultGestureRecognizers.panGestureRecognizer
                   forMode:LTInteractionModePanOneTouch | LTInteractionModePanTwoTouches];
  }
  if (self.defaultGestureRecognizers.pinchGestureRecognizer) {
    [self enableRecognizer:self.defaultGestureRecognizers.pinchGestureRecognizer
                   forMode:LTInteractionModePinch];
  }

  if (!self.defaultGestureRecognizers.panGestureRecognizer ||
      !(self.interactionMode & (LTInteractionModePanOneTouch | LTInteractionModePanTwoTouches))) {
    return;
  }

  self.defaultGestureRecognizers.panGestureRecognizer.minimumNumberOfTouches =
      (self.interactionMode & LTInteractionModePanOneTouch) ? 1 : 2;
  self.defaultGestureRecognizers.panGestureRecognizer.maximumNumberOfTouches =
      (self.interactionMode & LTInteractionModePanTwoTouches) ? 2 : 1;
}

- (void)enableRecognizer:(UIGestureRecognizer *)recognizer forMode:(LTInteractionMode)mode {
  recognizer.enabled = self.interactionMode & mode ? YES : NO;
}

- (BOOL)isCurrentlyReceivingContentTouchEvents {
  return self.touchEventView.isCurrentlyReceivingTouchEvents;
}

- (BOOL)forwardStationaryContentTouchEvents {
  return self.touchEventView.forwardStationaryTouchEvents;
}

- (void)setForwardStationaryContentTouchEvents:(BOOL)forwardStationaryContentTouchEvents {
  self.touchEventView.forwardStationaryTouchEvents = forwardStationaryContentTouchEvents;
}

#pragma mark -
#pragma mark LTContentTouchEventDelegate
#pragma mark -

- (void)receivedContentTouchEvents:(LTContentTouchEvents *)contentTouchEvents
                   predictedEvents:(LTContentTouchEvents *)predictedTouchEvents
           touchEventSequenceState:(LTTouchEventSequenceState)state {
  if (state == LTTouchEventSequenceStateStart) {
    [self cancelBogusPanGestureRecognition];
  }

  if (self.forwardTouchEvents) {
    [self.contentTouchEventDelegate receivedContentTouchEvents:contentTouchEvents
                                               predictedEvents:predictedTouchEvents
                                       touchEventSequenceState:state];
  }
}

- (void)receivedUpdatesOfContentTouchEvents:(LTContentTouchEvents *)contentTouchEvents {
  if (self.forwardTouchEvents) {
    [self.contentTouchEventDelegate receivedUpdatesOfContentTouchEvents:contentTouchEvents];
  }
}

- (void)contentTouchEventSequencesWithIDs:(NSSet<NSNumber *> *)sequenceIDs
                      terminatedWithState:(LTTouchEventSequenceState)state {
  if (self.forwardTouchEvents) {
    [self.contentTouchEventDelegate contentTouchEventSequencesWithIDs:sequenceIDs
                                                  terminatedWithState:state];
  }
}

#pragma mark -
#pragma mark Auxiliary methods
#pragma mark -

/// For some reason on the iPhone 6 Plus (and possibly on the iPhone 6) certain pan gesture
/// recognizers (such as the one provided by \c UIScrollview objects) trigger even while the value
/// of their \c numberOfTouches property is less than the \c minimumNumberOfTouches. This triggers a
/// call to the \c touchesCancelled:withEvent: method, which prevents any touch functionality from
/// happening. This hack detects this scenario, when in pinch interaction mode, and cancels the pan
/// gesture by disabling and re-enabling the recognizer.
- (void)cancelBogusPanGestureRecognition {
  UIPanGestureRecognizer *panGestureRecognizer =
      self.defaultGestureRecognizers.panGestureRecognizer;

  if (panGestureRecognizer.state == UIGestureRecognizerStateBegan &&
      panGestureRecognizer.numberOfTouches == 1 &&
      panGestureRecognizer.minimumNumberOfTouches == 2 &&
      self.interactionMode & LTInteractionModePinch) {
    LogDebug(@"Detected a bogus iphone 6 plus scrolling gesture, discarding it");
    panGestureRecognizer.enabled = NO;
    panGestureRecognizer.enabled = YES;
  }
}

- (BOOL)forwardTouchEvents {
  return [self forwardTouchEventsForMode:self.interactionMode];
}

- (BOOL)forwardTouchEventsForMode:(LTInteractionMode)mode {
  return mode & LTInteractionModeTouchEvents ? YES : NO;
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (void)setDefaultGestureRecognizers:(LTInteractionGestureRecognizers *)defaultGestureRecognizers {
  [self removeDefaultGestureRecognizers];
  _defaultGestureRecognizers = defaultGestureRecognizers;
  [self addDefaultGestureRecognizers];
}

- (void)removeDefaultGestureRecognizers {
  [self safelyRemoveGestureRecognizer:self.defaultGestureRecognizers.tapGestureRecognizer];
  [self safelyRemoveGestureRecognizer:self.defaultGestureRecognizers.panGestureRecognizer];
  [self safelyRemoveGestureRecognizer:self.defaultGestureRecognizers.pinchGestureRecognizer];
}

- (void)addDefaultGestureRecognizers {
  [self safelyAddDefaultGestureRecognizer:self.defaultGestureRecognizers.tapGestureRecognizer];
  [self safelyAddDefaultGestureRecognizer:self.defaultGestureRecognizers.panGestureRecognizer];
  [self safelyAddDefaultGestureRecognizer:self.defaultGestureRecognizers.pinchGestureRecognizer];
  [self setupGestureRecognizers];
}

- (void)setContentTouchEventDelegate:(nullable id<LTContentTouchEventDelegate>)delegate {
  if (_contentTouchEventDelegate == delegate) {
    return;
  }

  [self.touchEventView cancelTouchEventSequences];
  _contentTouchEventDelegate = delegate;
}

- (void)safelyRemoveGestureRecognizer:(nullable UIGestureRecognizer *)recognizer {
  if (recognizer) {
    [self.touchEventView removeGestureRecognizer:recognizer];
  }
}

- (void)safelyAddDefaultGestureRecognizer:(nullable UIGestureRecognizer *)recognizer {
  if (recognizer) {
    LTParameterAssert(![self.customGestureRecognizers containsObject:recognizer],
                      @"Custom gesture recognizers (%@) contain given recognizer (%@)",
                      self.customGestureRecognizers, recognizer);
    [self.touchEventView addGestureRecognizer:recognizer];
  }
}

@synthesize customGestureRecognizers = _customGestureRecognizers;

- (void)setCustomGestureRecognizers:(nullable NSArray<UIGestureRecognizer *> *)customRecognizers {
  if ([_customGestureRecognizers isEqual:customRecognizers]) {
    return;
  }

  for (UIGestureRecognizer *gestureRecognizer in _customGestureRecognizers) {
    [self.touchEventView removeGestureRecognizer:gestureRecognizer];
  }
  _customGestureRecognizers = customRecognizers;
  for (UIGestureRecognizer *gestureRecognizer in customRecognizers) {
    LTParameterAssert(![self.touchEventView.gestureRecognizers containsObject:gestureRecognizer],
                      @"Gesture recognizer has already been added as default gesture recognizer.");
    [self.touchEventView addGestureRecognizer:gestureRecognizer];
  }
}

@end

NS_ASSUME_NONNULL_END
