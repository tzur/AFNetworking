// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTPropertyMacros.h"

#define LTBoundedPrimitivePropertyImplementAndUpdateProgram(type, name, Name, minValue, maxValue, \
    defaultValue) \
  LTBoundedPrimitivePropertyImplementWithCustomSetter(type, name, Name, minValue, maxValue, \
    defaultValue, ^{ \
    [self updateProgramForCurrentProperties]; \
  });

@class LTFbo, LTPainterPoint, LTPainterStrokeSegment, LTRotatedRect;

/// @class LTBrush
///
/// A class representing a brush used by the \c LTPainter. This class (or its subclasses) can be
/// used to draw a point or a stroke segment on a target framebuffer, and contain adjustable
/// properties controlling the behavior and appearance of the painted areas.
/// This basic brush class simply draws a texture according to its properties.
///
/// @see http://www.smashingmagazine.com/2009/11/16/brushing-up-on-photoshops-brush-tool/
@interface LTBrush : NSObject

/// Does the necessary preparations for drawing a new stroke (without drawing anything).
- (void)startNewStrokeAtPoint:(LTPainterPoint *)point;

/// Draws a single point in the given framebuffer. This ignores the brush spacing settings.
///
/// @return the \c LTRotatedRect used for drawing the point.
- (LTRotatedRect *)drawPoint:(LTPainterPoint *)point inFramebuffer:(LTFbo *)fbo;

/// Draws the given stroke segment in the given framebuffer.
///
/// @param previousPoint the last point that was previously drawn on the segment, used for accurate
/// spacing calculation, as the next point should be spaced from the last drawn point and not from
/// the start of the segment. In case this argument is nil, the first point will be drawn on the
/// beginning of the segment.
/// @param lastDrawnPoint will store the last point that is actually drawn on the segment by this
/// method. In case 
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

/// Controls the base size of the brush, in pixels. The default value for iOS is the average finger
/// size on the device.
@property (nonatomic) NSUInteger baseDiameter;

/// Controls the size of the brush with respect to the base size.
/// Must be in range [0.1,3], default is \c 1.
LTBoundedPrimitiveProperty(CGFloat, scale, Scale)

/// Rotation angle around the brush center, in radians. Automatically converted to the corresponding
/// angle in range [0,2*PI). Default is \c 0.
LTBoundedPrimitiveProperty(CGFloat, angle, Angle)

/// Spacing (in percentage) between the brush placements.
/// Must be in range [0.01,10], default is \c 0.05.
/// \c 1 will place the next brush exactly adjacent to the previous one, with no overlap (assuming
/// the brush is round).
/// Values smaller than \c 1 will place the brush closer to the previous brush, creating an overlap.
LTBoundedPrimitiveProperty(CGFloat, spacing, Spacing)

/// Maximal opacity value for the stroke. Must be in range [0,1], default is \c 1.
LTBoundedPrimitiveProperty(CGFloat, opacity, Opacity)

/// Rate at which color is applied as the brush paints over an area.
/// Must be in range [0.01,1], default is \c 1.
LTBoundedPrimitiveProperty(CGFloat, flow, Flow)

/// Per-channel intensity. Each channel must be in range [0,1], default is \c 1.
LTBoundedPrimitiveProperty(GLKVector4, intensity, Intensity);

@end
