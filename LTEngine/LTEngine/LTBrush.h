// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#define LTPropertyUpdatingProgram(type, name, Name, minValue, maxValue, defaultValue) \
  LTPropertyWithoutSetter(type, name, Name, minValue, maxValue, defaultValue); \
  - (void)set##Name:(type)name { \
    [self _verifyAndSet##Name:name]; \
    [self updateProgramForCurrentProperties]; \
  }

@protocol LTInterpolationRoutineFactory;
@class LTBrushColorDynamicsEffect, LTBrushRandomState, LTBrushScatterEffect, LTBrushShapeDynamicsEffect,
    LTFbo, LTPainterPoint, LTPainterStrokeSegment, LTRandom, LTRotatedRect;

/// Protocol for mapping \c touchRadius and \c touchRadiusTolerance into a scale that should be
/// applied on the brush.
///
/// @see The \c majorRadius and \c majorRadiusTolerance properties of \c UITouch.
@protocol LTBrushTouchRadiusMapper <NSObject>

/// Returns the scale that should be applied for the given touch radius and tolerance.
- (CGFloat)scaleForTouchRadius:(CGFloat)radius tolerance:(CGFloat)tolerance;

@end

/// A class representing a brush used by the \c LTPainter. This class (or its subclasses) can be
/// used to draw a point or a stroke segment on a target framebuffer, and contain adjustable
/// properties controlling the behavior and appearance of the painted areas.
/// This basic brush class simply draws a texture according to its properties.
///
/// @see http://www.smashingmagazine.com/2009/11/16/brushing-up-on-photoshops-brush-tool/
@interface LTBrush : NSObject

/// Initializes the brush with its own random generator.
- (instancetype)init;

/// Designated initializer: initializes the brush with the given random generator.
- (instancetype)initWithRandom:(LTRandom *)random;

/// Does the necessary preparations for drawing a new stroke (without drawing anything).
- (void)startNewStrokeAtPoint:(LTPainterPoint *)point;

/// Draws a single point in the given framebuffer. This ignores the brush spacing settings.
///
/// @return Array of the \c LTRotatedRects that were used for drawing the point (can contain
/// multiple points, generated by an effect such as \c LTBrushScatterEffect).
- (NSArray *)drawPoint:(LTPainterPoint *)point inFramebuffer:(LTFbo *)fbo;

/// Draws the given stroke segment in the given framebuffer.
///
/// @param previousPoint the last point that was previously drawn on the segment, used for accurate
/// spacing calculation, as the next point should be spaced from the last drawn point and not from
/// the start of the segment. in case this argument is nil, the first point will be drawn on the
/// beginning of the segment.
/// @param lastDrawnPoint will store the last point that is actually drawn on the segment by this
/// method.
/// @return array of the \c LTRotatedRects that were used for drawing the segment (after applying
/// the current brush effects).
- (NSArray *)drawStrokeSegment:(LTPainterStrokeSegment *)segment
             fromPreviousPoint:(LTPainterPoint *)previousPoint
                 inFramebuffer:(LTFbo *)fbo
          saveLastDrawnPointTo:(LTPainterPoint **)lastDrawnPoint;

/// Returns the list of points that should be painted for the given stroke segment, spaced with
/// respect of the given previous point. The default behavior returns a list of equally spaced
/// points on the segment.
///
/// @note Subclasses may override this method in case a different spacing mechanism is used, for
/// example in case the points diameter or density varies throughout the segment.
- (NSArray *)pointsForStrokeSegment:(LTPainterStrokeSegment *)segment
                  fromPreviousPoint:(LTPainterPoint *)previousPoint;

/// Returns an array of property names (\c NSString) that can be adjusted for the brush.
- (NSArray *)adjustableProperties;

/// The random generator used by the brush.
@property (readonly, nonatomic) LTRandom *random;

/// The random states of the random generators of this brush and its elements exhibiting random
/// behavior. Setting this property updates the state of the relevant random generators.
@property (nonatomic) LTBrushRandomState *randomState;

/// Controls the base size of the brush, in pixels. The default value for iOS is the average finger
/// size on the device.
@property (nonatomic) NSUInteger baseDiameter;

/// Spline factory that should be used for generating segments when using the brush.
@property (strong, nonatomic) id<LTInterpolationRoutineFactory> splineFactory;

/// Scattering effect applied during the brush strokes.
@property (strong, nonatomic) LTBrushScatterEffect *scatterEffect;

/// Shape dynamics effect applied during the brush strokes.
@property (strong, nonatomic) LTBrushShapeDynamicsEffect *shapeDynamicsEffect;

/// Color dynamics effect applied during the brush strokes.
@property (strong, nonatomic) LTBrushColorDynamicsEffect *colorDynamicsEffect;

/// Used for mapping the touch radius and tolerance of points to a scale applied on the drawn tip
/// (stacked with the \c scale property and the scale applied due to the \c zoomScale of points).
/// When set to \c nil (default), the touch radius will not affect the size of the drawn tip.
@property (strong, nonatomic) id<LTBrushTouchRadiusMapper> touchRadiusMapper;

/// Controls the size of the brush with respect to the base size.
/// Must be in range [0.1,3], default is \c 1.
@property (nonatomic) CGFloat scale;
LTPropertyDeclare(CGFloat, scale, Scale)

/// Rotation angle around the brush center, in radians. Automatically converted to the corresponding
/// angle in range [0,2*PI). Default is \c 0.
@property (nonatomic) CGFloat angle;
LTPropertyDeclare(CGFloat, angle, Angle)

/// Spacing (in percentage) between the brush placements.
/// Must be in range [0.01,10], default is \c 0.05.
/// \c 1 will place the next brush exactly adjacent to the previous one, with no overlap (assuming
/// the brush is round).
/// Values smaller than \c 1 will place the brush closer to the previous brush, creating an overlap.
@property (nonatomic) CGFloat spacing;
LTPropertyDeclare(CGFloat, spacing, Spacing)

/// Maximal opacity value for the stroke. Must be in range [0,1], default is \c 1.
@property (nonatomic) CGFloat opacity;
LTPropertyDeclare(CGFloat, opacity, Opacity)

/// Rate at which color is applied as the brush paints over an area.
/// Must be in range [0.01,1], default is \c 1.
@property (nonatomic) CGFloat flow;
LTPropertyDeclare(CGFloat, flow, Flow)

/// Per-channel intensity. Each channel must be in range [0,1], default is \c 1.
@property (nonatomic) LTVector4 intensity;
LTPropertyDeclare(LTVector4, intensity, Intensity);

/// If set to \c YES, the brush angle will be set to a random angle whenever a stroke starts.
@property (nonatomic) BOOL randomAnglePerStroke;

/// When set to \c YES, the brush will use a single scale throughout a stroke, ignoring changes to
/// the touch radius and the zoom scale. This only affects the base scale, so any effects that alter
/// the scale of the drawn tips can still lead to non uniform scale throughout the stroke. Default
/// is \c NO.
@property (nonatomic) BOOL forceConsistentScaleDuringStroke;

@end
