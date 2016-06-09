// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTInteractionMode.h"

NS_ASSUME_NONNULL_BEGIN

@protocol LTContentTouchEventDelegate;

/// Protocol to be implemented by objects providing the mode defining the user interaction using
/// gestures and/or content touch events.
@protocol LTInteractionModeProvider <NSObject>

/// Mode defining the interaction. Default value is \c LTInteractionModeAllGestures.
@property (readonly, nonatomic) LTInteractionMode interactionMode;

@end

/// Protocol to be implemented by objects maintaining the mode defining the user interaction via
/// gestures and/or touches on a content view.
@protocol LTInteractionModeDelegate <LTInteractionModeProvider>

/// Mode defining the interaction. See \c LTInteractionModeProvider for more details.
///
/// @important Switching to an interaction mode that flips the \c LTInteractionModeTouchEvents bit
/// while content touch event sequences are currently occurring, causes the currently occurring
/// sequences to be cancelled.
@property (nonatomic) LTInteractionMode interactionMode;

@end

/// Protocol to be implemented by objects managing the user interaction via gestures and/or touches
/// on a content view.
@protocol LTContentInteractionManager <LTInteractionModeDelegate>

/// Ordered collection of custom gesture recognizers to be used to recognize gestures on the view
/// managed by this instance. Upon modificiation of this property, the old gesture recognizers are
/// detached from the view and the new gesture recognizers are attached to it. The object performing
/// the modification of this property is responsible for enabling/disabling the gesture recognizers
/// according to its requirements.
@property (strong, nonatomic, nullable) NSArray<UIGestureRecognizer *> *customGestureRecognizers;

/// Delegate informed about content touch event sequences.
///
/// @important Switching the delegate while content touch event sequences are currently occurring,
/// cancels all currently occurring sequences and triggers a call of the
/// \c contentTouchEventSequencesWithIDs:terminatedWithState: method of the replaced delegate, with
/// the sequence IDs of the all currently occurring content touch event sequences and
/// \c LTTouchEventSequenceStateCancellation as termination state. All content touch event sequences
/// sent to the new delegate are guaranteed to have the initial state
/// \c LTTouchEventSequenceStateStart. In other words, when switching delegates it is guaranteed
/// that content touch event sequences stay exclusive to a single delegate.
@property (weak, nonatomic, nullable) id<LTContentTouchEventDelegate> contentTouchEventDelegate;

@end

NS_ASSUME_NONNULL_END
