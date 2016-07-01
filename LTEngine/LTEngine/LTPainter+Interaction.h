// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTPainter.h"

#import "LTTouchCollector.h"

@protocol LTInteractionModeDelegate;

#pragma mark -
#pragma mark LTPainterDelegate
#pragma mark -

/// This protocol is used to receive updates on painting events from the \c LTPainter.
@protocol LTPainterDelegate <NSObject>

/// Called on a painting event, providing an array of normalized \c LTRotatedRects representing all
/// the pixels painted on this event.
- (void)ltPainter:(LTPainter *)painter didPaintInRotatedRects:(NSArray *)rotatedRects;

@optional

/// Called when the painer is about to start a new stroke.
- (void)ltPainterWillBeginStroke:(LTPainter *)painter;

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
#pragma mark LTPainter (Interaction)
#pragma mark -

/// Category augmenting the \c LTPainter class with functionality to draw according to incoming
/// touch events of a single touch event sequence and update the interaction mode during the
/// processed touch event sequence.
@interface LTPainter (Interaction) <LTTouchCollectorDelegate>

/// Delegate notified on painter events.
@property (weak, nonatomic) id<LTPainterDelegate> delegate;

/// Delegate used to update the content interaction mode.
@property (weak, nonatomic) id<LTInteractionModeDelegate> interactionModeDelegate;

/// Painter component acting as \c LTContentTouchEventDelegate, used for converting incoming touch
/// events into corresponding painting strokes.
@property (readonly, nonatomic) id<LTContentTouchEventDelegate> touchDelegateForLTView;

@end
