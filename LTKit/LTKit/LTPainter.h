// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

@class LTBrush, LTPainterStroke, LTTexture;
@protocol LTInterpolationRoutineFactory;

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
#pragma mark LTPainter
#pragma mark -

/// The \c LTPainter class is used to provide a highly-customizable platform for painting over an
/// \c LTTexture.
@interface LTPainter : NSObject

/// Initializes the painter of the given mode with the given canvas texture.
///
/// @note Texture must be compatible as a rendering target for the current device.
- (instancetype)initWithMode:(LTPainterTargetMode)mode canvasTexture:(LTTexture *)canvasTexture;

/// Clears the canvas texture with the given color, and removes all strokes from the \c strokes
/// array.
- (void)clearWithColor:(LTVector4)color;

/// Paints the given stroke.
- (void)paintStroke:(LTPainterStroke *)stroke;

/// Removes all strokes from the \c strokes array.
- (void)clearStrokes;

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

/// The last stroke that was completed by the painter. If there's a currently active stroke, the one
/// prior to it will be returned.
@property (readonly, nonatomic) LTPainterStroke *lastStroke;

#pragma mark -
#pragma mark Painter Customization Properties
#pragma mark -

/// Brush used for painting. Default is \c LTBrush with its default configuration.
@property (strong, nonatomic) LTBrush *brush;

/// Spline factory used for generating segments. Default is \c LTCatmullRomInterpolationFactory.
@property (strong, nonatomic) id<LTInterpolationRoutineFactory> splineFactory;

/// When set to \c YES, airbrush-style build-up effects are enabled, meaning that long presses over
/// an area will continuously paint over it.
@property (nonatomic) BOOL airbrush;

@end
