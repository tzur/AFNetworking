// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTTouchEvent.h"

NS_ASSUME_NONNULL_BEGIN

/// Protocol to be implemented by objects to which \c id<LTTouchEvent> objects are delegated.
///
/// @important Termination or cancellation of a touch event sequence is solely reported once, either
/// via the \c receivedTouchEvents:predictedEvents:touchEventSequenceState: or the
/// \c terminatedTouchEventSequencesWithIDs: method.
@protocol LTTouchEventDelegate <NSObject>

/// Called to inform the delegate that the given \c touchEvents and \c predictedTouchEvents have
/// been received. The \c touchEvents all belong to the same touch event sequence with the given
/// \c state. The given \c predictedTouchEvents consist of possibly existing predicted touches. Both
/// the \c touchEvents and the \c predictedTouchEvents are ordered according to their timestamps.
///
/// @important A call to this method with state \c LTTouchEventSequenceStateEnd or
/// \c LTTouchEventSequenceStateCancellation is neither followed nor preceeded by a call to the
/// \c terminatedTouchEventSequencesWithIDs: method with the same sequence ID.
- (void)receivedTouchEvents:(LTTouchEvents *)touchEvents
            predictedEvents:(LTTouchEvents *)predictedTouchEvents
    touchEventSequenceState:(LTTouchEventSequenceState)state;

/// Called to delegate the handling of the given updated \c touchEvents. The \c touchEvents are
/// ordered according to their timestamps and belong to touch event sequences that have not ended
/// yet.
- (void)receivedUpdatesOfTouchEvents:(LTTouchEvents *)touchEvents;

/// Called to inform the delegate that all touch event sequences with the given \c sequenceIDs have
/// been terminated with the given \c state. The given \c state is either
/// \c LTTouchEventSequenceStateEnd or \c LTTouchEventSequenceStateCancellation. This call is
/// neither preceeded nor followed by a call to
/// \c receivedTouchEvents:predictedEvents:touchEventSequenceState: with state
/// \c LTTouchEventSequenceStateEnd or \c LTTouchEventSequenceStateCancellation and a sequence ID
/// provided in the given \c sequenceIDs.
- (void)touchEventSequencesWithIDs:(NSSet<NSNumber *> *)sequenceIDs
               terminatedWithState:(LTTouchEventSequenceState)state;

@end

NS_ASSUME_NONNULL_END
