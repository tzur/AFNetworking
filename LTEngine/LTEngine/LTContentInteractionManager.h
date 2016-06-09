// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTContentInteraction.h"
#import "LTContentTouchEventDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@protocol LTTouchEventCancellation;

/// Tuple of gesture recognizers used by \c LTContentInteractionManager objects.
@interface LTInteractionGestureRecognizers : NSObject

/// Initializes with \c nil values.
- (instancetype)init;

/// Initializes with the given \c tapRecognizer, \c panRecognizer, and \c pinchRecognizer.
- (instancetype)initWithTapRecognizer:(nullable UITapGestureRecognizer *)tapRecognizer
                        panRecognizer:(nullable UIPanGestureRecognizer *)panRecognizer
                      pinchRecognizer:(nullable UIPinchGestureRecognizer *)pinchRecognizer
    NS_DESIGNATED_INITIALIZER;

/// Tap gesture recognizer.
@property (readonly, nonatomic, nullable) UITapGestureRecognizer *tapGestureRecognizer;

/// Pan gesture recognizer.
@property (readonly, nonatomic, nullable) UIPanGestureRecognizer *panGestureRecognizer;

/// Pinch gesture recognizer.
@property (readonly, nonatomic, nullable) UIPinchGestureRecognizer *pinchGestureRecognizer;

@end

/// Object managing the content interaction mode.
///
/// Content touch events are forwarded by objects of this class if and only if the
/// \c LTInteractionModeTouchEvents bit flag is enabled in the \c interactionMode of the object.
/// No gesture recognizers existing in the \c defaultGestureRecognizers property must exist in the
/// \c customGestureRecognizers property and vice versa.
@interface LTContentInteractionManager : NSObject <LTContentInteractionManager,
    LTContentTouchEventDelegate>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c view. Upon modification of the \c defaultGestureRecognizers or
/// \c customGestureRecognizers managed by the returned instance, the gesture recognizers are
/// attached to/removed from the given \c view. The given \c view is held strongly and must not have
/// any gesture recognizers attached to it. Both attachment and removal of gesture recognizers from
/// the given \c view must only be performed via the \c defaultGestureRecognizers and
/// \c customGestureRecognizers recognizers.
- (instancetype)initWithView:(UIView *)view;

/// Object used for cancellation of incoming content touch event sequences.
@property (weak, nonatomic) id<LTTouchEventCancellation> touchEventCanceller;

/// Default gesture recognizers. Each gesture recognizer is enabled/disabled according to the
/// corresponding bit flag in the \c interactionMode.
@property (strong, nonatomic) LTInteractionGestureRecognizers *defaultGestureRecognizers;

@end

NS_ASSUME_NONNULL_END
