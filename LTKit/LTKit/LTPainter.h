// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

@class LTBrush, LTPainter, LTPainterStroke, LTTexture, LTView;
@protocol LTInterpolationRoutineFactory, LTTouchCollectorFilter, LTViewTouchDelegate;

#pragma mark -
#pragma mark Painter Enums
#pragma mark -

// Type of buffer to create.
typedef NS_ENUM(NSUInteger, LTPainterTargetMode) {
  /// When using this painting mode, each stroke is drawn on a sandboxed texture, merged with the
  /// canvas only when the stroke is finished. This allows the opacity to be limited on a per stroke
  /// basis, but stacking between strokes.
  LTPainterTargetModeSandboxedStroke = 0,
  /// When using this painting mode, each stroke is drawn directly on the canvas. This makes the
  /// brush opacity behave like a clamping boundary, which does not stack between strokes.
  LTPainterTargetModeDirectStroke
};

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

/// Transofmration applied on the content position of every incoming point. Can be used to draw on
/// an alternative coordinate system.
- (CGAffineTransform)alternativeCoordinateSystemTransform;

/// Alternative zoom scale replacing the zoom scale of every incoming point. Can be used when
/// drawing on an alternative coordinate system, to reflect the size differences.
- (CGFloat)alternativeZoomScale;

@end

#pragma mark -
#pragma mark LTPainter
#pragma mark -

/// The \c LTPainter class is used to provide a highly-customizable platform for painting over an
/// \c LTTexture using touch gestures on an \c LTView.
@interface LTPainter : NSObject

/// Initializes the painter of the given mode with the given canvas texture.
///
/// @note Texture must be compatible as a rendering target for the current device.
- (instancetype)initWithMode:(LTPainterTargetMode)mode canvas:(LTTexture *)canvas;

/// Clears the canvas texture with the given color.
- (void)clearWithColor:(GLKVector4)color;

/// Paints the given stroke.
- (void)paintStroke:(LTPainterStroke *)stroke;

/// Delegate notified on painter events.
@property (weak, nonatomic) id<LTPainterDelegate> delegate;

/// The painter component acting as \c LTViewTouchDelegate, used for converting the touch events on
/// the \c LTView into painting strokes. the \c LTView's \c touchDelegate property should be set to
/// this object.
@property (readonly, nonatomic) id<LTViewTouchDelegate> touchDelegateForLTView;

/// Target mode for the painter, see \c LTPainterTargetMode.
@property (readonly, nonatomic) LTPainterTargetMode mode;

/// The canvas texture holding the completed strokes.
@property (readonly, nonatomic) LTTexture *canvasTexture;

/// Temporary texture holding the currently active storke, Used only when the target mode is
/// \c LTPainterTargetModeSandboxedStroke. Otherwise, a 1x1 zero texture is returned.
@property (readonly, nonatomic) LTTexture *strokeTexture;

/// Array of the painter strokes since the last clear, excluding a currently active stroke, if
/// exists.
@property (readonly, nonatomic) NSArray *strokes;

#pragma mark -
#pragma mark Painter Customization Properties
#pragma mark -

/// Brush used for painting.
@property (strong, nonatomic) LTBrush *brush;

/// Spline factory used for generating segments.
@property (strong, nonatomic) id<LTInterpolationRoutineFactory> splineFactory;

/// When set to \c YES, airbrush-style build-up effects are enabled, meaning that long presses over
/// an area will continuously paint over it.
@property (nonatomic) BOOL airbrush;

@end
