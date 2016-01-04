// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

NS_ASSUME_NONNULL_BEGIN

@class LTTouchEvent;

/// Possible states of a touch event sequence.
typedef NS_ENUM(NSUInteger, LTTouchEventSequenceState) {
  /// Indicates that the touch event sequences has just started.
  LTTouchEventSequenceStateStart,
  /// Indicates that the touch event sequence is currently being continued.
  LTTouchEventSequenceStateContinuation,
  /// Indicates that the touch event sequence has just ended.
  LTTouchEventSequenceStateEnd,
  /// Indicates that the touch event sequence has just been cancelled.
  LTTouchEventSequenceStateCancellation
};

/// Protocol to be implemented by objects to which \c LTTouchEvent objects are delegated.
@protocol LTTouchEventDelegate <NSObject>

/// Called to inform the delegate that the given \c touchEvents and \c predictedTouchEvents have
/// been provided by the given \c touchEventProvider. The \c touchEvents belong to a touch event
/// sequence with the given \c state. The given \c predictedTouchEvents consist of possibly existing
/// predicted touches. Both the \c touchEvents and the \c predictedTouchEvents are ordered according
/// to their timestamps.
- (void)receivedTouchEvents:(NSArray<LTTouchEvent *> *)touchEvents
            predictedEvents:(NSArray<LTTouchEvent *> *)predictedTouchEvents
    touchEventSequenceState:(LTTouchEventSequenceState)state;

/// Called to delegate the handling of the given updated \c touchEvents provided by the given
/// \c touchEventProvider. The \c touchEvents are ordered according to their timestamps and belong
/// to touch event sequences that have not ended yet.
- (void)receivedUpdatesOfTouchEvents:(NSArray<LTTouchEvent *> *)touchEvents;

@end

NS_ASSUME_NONNULL_END
