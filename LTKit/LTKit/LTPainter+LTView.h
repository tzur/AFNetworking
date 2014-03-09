// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTPainter.h"

#import "LTTouchCollector.h"

#pragma mark -
#pragma mark LTPainterDelegate
#pragma mark -

/// This protocol is used to receive updates on painting events from the \c LTPainter.
@protocol LTPainterDelegate <NSObject>

/// Called on a painting event, providing an array of normalized \c LTRotatedRects representing all
/// the pixels painted on this event.
- (void)ltPainter:(LTPainter *)painter didPaintInRotatedRects:(NSArray *)rotatedRects;

@optional

/// Called when the painter finished painting a stroke.
- (void)ltPainter:(LTPainter *)painter didFinishStroke:(LTPainterStroke *)stroke;

/// Transformation applied on the content position of every incoming point. Can be used to draw on
/// an alternative coordinate system.
- (CGAffineTransform)alternativeCoordinateSystemTransform;

/// Alternative zoom scale replacing the zoom scale of every incoming point. Can be used when
/// drawing on an alternative coordinate system, to reflect the size differences.
- (CGFloat)alternativeZoomScale;

@end

#pragma mark -
#pragma mark LTPainter (LTView)
#pragma mark -

/// Category providing an interface for drawing using the \c LTPainter using touch gestures on an
/// \c LTView.
@interface LTPainter (LTView) <LTTouchCollectorDelegate>

/// Delegate notified on painter events.
@property (weak, nonatomic) id<LTPainterDelegate> delegate;

/// The painter component acting as \c LTViewTouchDelegate, used for converting the touch events on
/// the \c LTView into painting strokes. the \c LTView's \c touchDelegate property should be set to
/// this object.
@property (readonly, nonatomic) id<LTViewTouchDelegate> touchDelegateForLTView;

@end
