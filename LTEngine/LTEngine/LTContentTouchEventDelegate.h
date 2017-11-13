// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTContentTouchEvent.h"

NS_ASSUME_NONNULL_BEGIN

/// Protocol to be implemented by objects to which \c id<LTContentTouchEvent> objects are delegated.
///
/// @important Termination or cancellation of a touch event sequence is solely reported once, either
/// via the \c receivedContentTouchEvents:predictedEvents:touchEventSequenceState: or the
/// \c terminatedContentTouchEventSequencesWithIDs: method. The first method is called when iOS
/// informs about changes of the currently occurring touch event sequences, while the latter is
/// called as a result of manual termination requests.
@protocol LTContentTouchEventDelegate <NSObject>

/// Called to inform the delegate that the given \c contentTouchEvents and \c predictedTouchEvents
/// have been received. The \c contentTouchEvents all belong to the same touch event sequence with
/// the given \c state. The given \c predictedTouchEvents consist of possibly existing predicted
/// touches. Both the \c touchEvents and the \c predictedTouchEvents are ordered according to their
/// timestamps. The timestamps are monotonically increasing also for consecutive calls to this
/// method. The given \c contentTouchEvents contain at least one content touch event. If the given
/// \c state is LTTouchEventSequenceStateStart, \c LTTouchEventSequenceStateEnd or
/// \c LTTouchEventSequenceStateCancellation, the given \c contentTouchEvents contain exactly one
/// content touch event.
///
/// @note The \c previousTimestamp of the given \c predictedTouchEvents is \c nil.
- (void)receivedContentTouchEvents:(LTContentTouchEvents *)contentTouchEvents
                   predictedEvents:(LTContentTouchEvents *)predictedTouchEvents
           touchEventSequenceState:(LTTouchEventSequenceState)state;

/// Called to delegate the handling of the given updated \c contentTouchEvents. The
/// \c contentTouchEvents contain at least one touch event, are ordered according to their
/// timestamps and belong to touch event sequences that have not ended yet. The timestamps are not
/// necessarily monotonically increasing for consecutive calls to this method.
///
/// @note The \c previousTimestamp of the given \c contentTouchEvents is \c nil.
- (void)receivedUpdatesOfContentTouchEvents:(LTContentTouchEvents *)contentTouchEvents;

/// Called to inform the delegate that all content touch event sequences with the given
/// \c sequenceIDs have been terminated with the given \c state. The \c sequenceIDs contain at least
/// one number. The given \c state is either \c LTTouchEventSequenceStateEnd or
/// \c LTTouchEventSequenceStateCancellation. This call is neither preceeded nor followed by a call
/// to \c receivedTouchEvents:predictedEvents:touchEventSequenceState: with state
/// \c LTTouchEventSequenceStateEnd or \c LTTouchEventSequenceStateCancellation and a sequence ID
/// provided in the given \c sequenceIDs.
- (void)contentTouchEventSequencesWithIDs:(NSSet<NSNumber *> *)sequenceIDs
                      terminatedWithState:(LTTouchEventSequenceState)state;

@end

NS_ASSUME_NONNULL_END
