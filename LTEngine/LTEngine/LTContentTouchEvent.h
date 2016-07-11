// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTTouchEvent.h"

@protocol LTContentTouchEvent;

/// Ordered collection of \c id<LTContentTouchEvent> objects.
typedef NSArray<id<LTContentTouchEvent>> LTContentTouchEvents;

/// Mutable ordered collection of \c id<LTContentTouchEvent> objects.
typedef NSMutableArray<id<LTContentTouchEvent>> LTMutableContentTouchEvents;

/// Protocol to be implemented by objects representing touch events occurring in the content
/// coordinate system.
@protocol LTContentTouchEvent <LTTouchEvent>

/// Location of the touch during the touch event, in floating-point pixel units of the content
/// coordinate system.
@property (readonly, nonatomic) CGPoint contentLocation;

/// Location of the touch during the previous touch event, in floating-point pixel units of the
/// content coordinate system.
@property (readonly, nonatomic) CGPoint previousContentLocation;

/// Size, in integer pixel units, of the content rectangle when the touch event occurred.
@property (readonly, nonatomic) CGSize contentSize;

/// Zoom scale of the content rectangle in relation to the presentation rectangle when the touch
/// event occurred. In particular, the zoom scale is defined as the ratio between the width of the
/// presentation rectangle and the corresponding dimension of the content rectangle.
@property (readonly, nonatomic) CGFloat contentZoomScale;

/// Radius, in floating-point pixel units of the content coordinate system, of the touch during the
/// event.
///
/// @see Homonymous property of \c UITouch.
@property (readonly, nonatomic) CGFloat majorContentRadius;

/// Tolerance, in floating-point pixel units of the content coordinate system, of the radius of this
/// touch event.
///
/// @see Homonymous property of \c UITouch.
@property (readonly, nonatomic) CGFloat majorContentRadiusTolerance;

@end

NS_ASSUME_NONNULL_BEGIN

/// Immmutable value object representing the discrete state of a touch (event) sequence occurring in
/// the content coordinate system.
@interface LTContentTouchEvent : NSObject <LTContentTouchEvent>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with a copy of the given \c touchEvent, the given \c contentSize,
/// \c contentZoomScale, and \c transform. The \c transform constitutes the affine transform
/// converting a \c CGPoint, given in point units of the presentation coordinate system, into the
/// corresponding \c CGPoint, in floating-point pixel units of the content coordinate system. The
/// \c transform is used to compute the \c contentLocation, \c previousContentLocation,
/// \c majorContentRadius, and \c majorContentRadiusTolerance of the returned instance.
- (instancetype)initWithTouchEvent:(id<LTTouchEvent>)touchEvent contentSize:(CGSize)contentSize
                  contentZoomScale:(CGFloat)contentZoomScale transform:(CGAffineTransform)transform;

@end

NS_ASSUME_NONNULL_END
