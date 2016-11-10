// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTTouchEventDelegate.h"

NS_ASSUME_NONNULL_BEGIN

/// Object forwarding calls to the methods of the \c LTTouchEventDelegate protocol to an
/// \c id<LTTouchEventDelegate> provided upon initialization, ensuring that the timestamps of the
/// forwarded touch events are monotonically increasing (per touch event sequence).
///
/// In particular, calls to a) the \c receivedUpdatesOfTouchEvents: method, b)
/// the \c touchEventSequencesWithIDs:terminatedWithState: method and c)
/// the \c receivedTouchEvents:predictedEvents:touchEventSequenceState: method with state
/// \c LTTouchEventSequenceStateStart are forwarded without any modification of parameters.
///
/// Calls to the \c receivedTouchEvents:predictedEvents:touchEventSequenceState: method with a state
/// different from \c LTTouchEventSequenceStateStart are forwarded with filtered \c touchEvents
/// parameter:
/// The filtering of the given \c touchEvents is performed by removing all touch events having a
/// \c timestamp smaller than the \c timestamp of the most recent (in terms of \c timestamp) touch
/// event of the same touch event sequence.
/// If there is at least one touch event remaining after the filtering, the
/// \c receivedTouchEvents:predictedEvents:touchEventSequenceState: method is called with the
/// filtered touch events. Else, if the sequence state is \c LTTouchEventSequenceStateEnd or
/// \c LTTouchEventSequenceStateCancellation, the \c touchEventSequencesWithIDs:terminatedWithState:
/// method is invoked. Else, i.e. if there is no touch event remaining after the filtering and the
/// state is neither \c LTTouchEventSequenceStateEnd nor \c LTTouchEventSequenceStateCancellation,
/// no delegate method is called.
///
/// @note This class exists solely due to the fact that the timestamps of consecutively received
/// \c UITouch events are not necessarily monotonically increasing (both main and coalesced
/// touches). A radar (29139098) has been submitted. The class will be removed once the bug has been
/// fixed by Apple.
@interface LTTouchEventTimestampFilter : NSObject <LTTouchEventDelegate>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c delegate which is held weakly.
- (instancetype)initWithTouchEventDelegate:(id<LTTouchEventDelegate>)delegate
    NS_DESIGNATED_INITIALIZER;

/// Delegate to which to forward calls.
@property (weak, readonly, nonatomic) id<LTTouchEventDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
