// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTTouchEvent.h"

@protocol LTContentTouchEvent;

/// Ordered collection of \c id<LTContentTouchEvent> objects.
typedef NSArray<id<LTContentTouchEvent>> LTContentTouchEvents;

/// Mutable ordered collection of \c id<LTContentTouchEvent> objects.
typedef NSMutableArray<id<LTContentTouchEvent>> LTMutableContentTouchEvents;

/// Protocol to be implemented by objects representing touch events occurring on the content
/// view.
@protocol LTContentTouchEvent <LTTouchEvent>

/// Location of the touch during the touch event, in floating-point pixel units of the content
/// coordinate system.
@property (readonly, nonatomic) CGPoint contentLocation;

/// Location of the touch during the previous touch event, in floating-point pixel units of the
/// content coordinate system.
@property (readonly, nonatomic) CGPoint previousContentLocation;

/// Size, in integer pixel units, of the content rectangle when the touch event occurred.
@property (readonly, nonatomic) CGSize contentSize;

/// Zoom scale of the content rectangle in relation to the content view when the touch event
/// occurred. In particular, the zoom scale is defined as the ratio between the width of the view
/// and the corresponding dimension of the content rectangle.
@property (readonly, nonatomic) CGFloat contentZoomScale;

@end

NS_ASSUME_NONNULL_BEGIN

/// Immmutable value object representing the discrete state of a touch (event) sequence occurring on
/// a content view.
@interface LTContentTouchEvent : NSObject <LTContentTouchEvent>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with a copy of the given \c touchEvent, the given \c contentLocation,
/// \c previousContentLocation, and \c contentZoomScale. The given \c contentLocation represents the
/// location of the touch in the content view, in floating-point pixel units of the content
/// coordinate system. The \c previousContentLocation represents the location of the previous touch
/// in the content view, in floating-point pixel units of the content coordinate system. The
/// \c contentZoomScale represents the zoom scale of the content view at the moment the touch was
/// received.
- (instancetype)initWithTouchEvent:(id<LTTouchEvent>)touchEvent
                   contentLocation:(CGPoint)contentLocation
           previousContentLocation:(CGPoint)previousContentLocation
                       contentSize:(CGSize)contentSize
                  contentZoomScale:(CGFloat)contentZoomScale;

@end

NS_ASSUME_NONNULL_END
