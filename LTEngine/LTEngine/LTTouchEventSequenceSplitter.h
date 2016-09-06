// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTTouchEventDelegate.h"

NS_ASSUME_NONNULL_BEGIN

/// Object forwarding calls to the \c receivedTouchEvents:predictedEvents:touchEventSequenceState:
/// method to an \c id<LTTouchEventDelegate> provided upon initialization, in the following way:
/// 
/// If the touch events belong to a non-terminating touch event sequence (i.e. the state of the
/// sequence is neither \c LTTouchEventSequenceStateEnd nor
/// \c LTTouchEventSequenceStateCancellation), the call is forwarded to the delegate without any
/// modification of parameters.
/// Otherwise, if the number of touch events is smaller than \c 2, the call is forwarded to the
/// delegate without any predicted touch events, but otherwise unchanged parameters.
/// Finally, if the touch events belong to a non-terminating touch event sequence and there are at
/// least two touch events, the call is split into two calls to the delegate, in the following way:
///
/// The first call to the delegate is performed with all but the last touch event, without predicted
/// touch events, and \c LTTouchEventSequenceStateContinuation as state.
/// The second call to the delegate is performed with the last touch event, without predicted touch
/// events, and the original state.
@interface LTTouchEventSequenceSplitter : NSObject <LTTouchEventDelegate>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c delegate. The given \c delegate is held weakly.
- (instancetype)initWithTouchEventDelegate:(id<LTTouchEventDelegate>)delegate
    NS_DESIGNATED_INITIALIZER;

/// Delegate to which to forward calls.
@property (weak, readonly, nonatomic) id<LTTouchEventDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
