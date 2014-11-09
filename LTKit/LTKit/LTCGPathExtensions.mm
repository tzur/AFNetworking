// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTCGPathExtensions.h"

#import <CoreFoundation/CoreFoundation.h>
#import <CoreText/CoreText.h>

#import "LTCFExtensions.h"
#import "LTGLKitExtensions.h"

/// Structure wrapping the data required for computing the modified path.
typedef struct LTPathModificationData {
  CGMutablePathRef path;
  GLKMatrix3 transform;
} LTPathModificationData;

/// Adds the provided \c element to the path wrapped in the given \c data, after multiplying the
/// points of the \c element with the transform wrapped in the given \c data.
static void LTRecomputePoints(void *data, const CGPathElement *element);

/// Returns the result of multiplying the provided \c point with the provided \c transform.
static CGPoint LTCGPointApplyTransform(CGPoint point, GLKMatrix3 &transform);

/// Returns a path connecting the provided points. The path is closed iff \c closed is YES.
static CGMutablePathRef LTCreatePolylinePathWithControlPoints(const LTVector2s &polyline,
                                                              BOOL closed);

/// Auxiliary method inserting the glyphs of a given string into a path.
static void LTCGPathCreateWithStringAuxiliaryMethod(CGRect rect,
                                                    CGMutablePathRef combinedGlyphsPathRef,
                                                    UIFont *font, CGPoint basePoint,
                                                    CTFrameRef frameRef);

/// Computes the additional control points used for a smoothened path. Please refer to the header
/// file for a detailed description of the smoothening mechanism.
/// Example for the added control points used for smoothening in case of four original control
/// points v0, v1, v2, v3:
///
/// v0 - v0next - v1prev - v1
/// |                       |
/// v0prev             v1next
/// |                       |
/// v3next             v2prev
/// |                       |
/// v3 - v3prev - v2next - v2
static void LTComputeSmootheningControlPoints(const LTVector2s &polyline,
                                              LTVector2s *prev,
                                              LTVector2s *next,
                                              CGFloat smootheningRadius);

/// Returns a smoothened path from the provided control points. The path is closed iff \c closed is
/// YES.
static CGMutablePathRef LTCreateSmoothenedPathWithControlPoints(const LTVector2s &points,
                                                                const LTVector2s &prev,
                                                                const LTVector2s &next,
                                                                BOOL closed);

#pragma mark -
#pragma mark - Public methods
#pragma mark -

CGPathRef LTCGPathCreateCopyByTransformingPath(CGPathRef path, GLKMatrix3 &transformation) {
  CGMutablePathRef result = CGPathCreateMutable();

  LTPathModificationData data;
  data.path = result;
  data.transform = transformation;

  CGPathApply(path, &data, &LTRecomputePoints);
  return result;
}

CGPathRef LTCGPathCreateCopyInRect(CGPathRef path, CGRect rect) {
  CGRect boundingBox = CGPathGetBoundingBox(path);
  CGAffineTransform translateToPointZero = CGAffineTransformMakeTranslation(-boundingBox.origin.x,
                                                                            -boundingBox.origin.y);
  CGAffineTransform scaleToDesiredSize =
      CGAffineTransformMakeScale(rect.size.width / boundingBox.size.width,
                                 rect.size.height / boundingBox.size.height);
  CGAffineTransform translateToDesiredOrigin = CGAffineTransformMakeTranslation(rect.origin.x,
                                                                                rect.origin.y);
  CGAffineTransform transformation =
      CGAffineTransformConcat(CGAffineTransformConcat(translateToPointZero, scaleToDesiredSize),
                              translateToDesiredOrigin);

  return CGPathCreateCopyByTransformingPath(path, &transformation);
}

CGMutablePathRef LTCGPathCreateWithControlPoints(const LTVector2s &polyline,
                                                 CGFloat smootheningRadius, BOOL closed) {
  LTParameterAssert(polyline.size() > 1);
  LTParameterAssert(smootheningRadius >= 0);
  const NSUInteger kNumberOfCorners = polyline.size();

  if (smootheningRadius == 0 || kNumberOfCorners == 2) {
    // Unsmoothened polyline.
    return LTCreatePolylinePathWithControlPoints(polyline, closed);
  }

  // Smoothened polyline.
  LTVector2s prev, next;
  prev.reserve(kNumberOfCorners);
  next.reserve(kNumberOfCorners);
  LTComputeSmootheningControlPoints(polyline, &prev, &next, smootheningRadius);
  return LTCreateSmoothenedPathWithControlPoints(polyline, prev, next, closed);
}

// @see: http://stackoverflow.com/questions/10152574/catextlayer-blurry-text-after-rotation
CGMutablePathRef LTCGPathCreateWithString(NSString *string, UIFont *font) {
  CTFramesetterRef frameSetterRef = NULL;
  CTFrameRef frameRef = NULL;

  @onExit {
    LTCFSafeRelease(frameSetterRef);
    LTCFSafeRelease(frameRef);
  };

  CGRect rect = CGRectMake(0, 0, CGFLOAT_MAX, CGFLOAT_MAX);
  CGMutablePathRef combinedGlyphsPathRef = CGPathCreateMutable();

  // It would be easy to wrap the text into a different shape, including arbitrary bezier paths,
  // if needed.
  UIBezierPath *frameShape = [UIBezierPath bezierPathWithRect:rect];

  CGPoint basePoint = CGPointMake(0, CTFontGetAscent((__bridge CTFontRef)font));
  NSDictionary *attributes = @{NSFontAttributeName: font};

  NSAttributedString *attributedString =
      [[NSAttributedString alloc] initWithString:string attributes:attributes];

  frameSetterRef =
      CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)attributedString);
  if (!frameSetterRef) {
    return NULL;
  }

  frameRef = CTFramesetterCreateFrame(frameSetterRef, CFRangeMake(0,0), [frameShape CGPath], NULL);
  if (!frameRef) {
    return NULL;
  }

  LTCGPathCreateWithStringAuxiliaryMethod(rect, combinedGlyphsPathRef, font, basePoint,
                                          frameRef);

  return combinedGlyphsPathRef;
}

#pragma mark -
#pragma mark - Static methods
#pragma mark -

void LTRecomputePoints(void *data, const CGPathElement *element) {
  LTPathModificationData *modificationData = (LTPathModificationData *)data;

  CGMutablePathRef path = modificationData->path;
  GLKMatrix3 transform = modificationData->transform;

  CGPoint *points = element->points;

  switch (element->type) {
    case kCGPathElementMoveToPoint:
      points[0] = LTCGPointApplyTransform(points[0], transform);
      CGPathMoveToPoint(path, NULL, points[0].x, points[0].y);
      break;
    case kCGPathElementAddLineToPoint:
      points[0] = LTCGPointApplyTransform(points[0], transform);
      CGPathAddLineToPoint(path, NULL, points[0].x, points[0].y);
      break;
    case kCGPathElementAddQuadCurveToPoint:
      points[0] = LTCGPointApplyTransform(points[0], transform);
      points[1] = LTCGPointApplyTransform(points[1], transform);
      CGPathAddQuadCurveToPoint(path, NULL, points[0].x, points[0].y,
                                points[1].x, points[1].y);
      break;
    case kCGPathElementAddCurveToPoint:
      points[0] = LTCGPointApplyTransform(points[0], transform);
      points[1] = LTCGPointApplyTransform(points[1], transform);
      points[2] = LTCGPointApplyTransform(points[2], transform);
      CGPathAddCurveToPoint(path, NULL, points[0].x, points[0].y,
                            points[1].x, points[1].y,
                            points[2].x, points[2].y);
      break;
    case kCGPathElementCloseSubpath:
      CGPathCloseSubpath(path);
      break;
    default:
      LTAssert(NO, @"Invalid element type.");
  }
}

static CGPoint LTCGPointApplyTransform(CGPoint point, GLKMatrix3 &transform) {
  GLKVector3 vector = GLKVector3Make(point.x, point.y, 1);
  vector = GLKMatrix3MultiplyVector3(transform, vector);
  return CGPointMake(vector.x / vector.z, vector.y / vector.z);
}

static CGMutablePathRef LTCreatePolylinePathWithControlPoints(const LTVector2s &polyline,
                                                              BOOL closed) {
  CGMutablePathRef path = CGPathCreateMutable();
  const NSUInteger kNumberOfCorners = polyline.size();

  CGPathMoveToPoint(path, NULL, polyline[0].x, polyline[0].y);
  for (NSUInteger i = 1; i < kNumberOfCorners; ++i) {
    CGPathAddLineToPoint(path, NULL, polyline[i].x, polyline[i].y);
  }
  if (closed) {
    CGPathCloseSubpath(path);
  }
  return path;
}

static void LTComputeSmootheningControlPoints(const LTVector2s &polyline,
                                              LTVector2s *prev,
                                              LTVector2s *next,
                                              CGFloat smootheningRadius) {
  const NSUInteger kNumberOfCorners = polyline.size();
  LTParameterAssert(!prev->size());
  LTParameterAssert(!next->size());
  NSUInteger prevIndex = kNumberOfCorners - 1;
  LTVector2 prevDirection = polyline[0] - polyline[prevIndex];
  LTVector2 normalizedPrevDirection = (polyline[0] - polyline[prevIndex]).normalized();

  for (NSUInteger i = 0; i < kNumberOfCorners; ++i) {
    NSUInteger nextIndex = (i + 1) % kNumberOfCorners;
    LTVector2 currentDirection = polyline[nextIndex] - polyline[i];
    CGFloat minRadius = MIN(MIN(prevDirection.length(), currentDirection.length()) / 2,
                            smootheningRadius);
    LTVector2 normalizedCurrentDirection = (currentDirection).normalized();
    prev->push_back(polyline[i] - (minRadius * normalizedPrevDirection));
    next->push_back(polyline[i] + (minRadius * normalizedCurrentDirection));
    prevDirection = currentDirection;
    normalizedPrevDirection = normalizedCurrentDirection;
  }

  LTAssert(prev->size() == kNumberOfCorners);
  LTAssert(next->size() == kNumberOfCorners);
}

static CGMutablePathRef LTCreateSmoothenedPathWithControlPoints(const LTVector2s &points,
                                                                const LTVector2s &prev,
                                                                const LTVector2s &next,
                                                                BOOL closed) {
  const NSUInteger kNumberOfCorners = points.size();
  CGMutablePathRef path = CGPathCreateMutable();

  if (closed) {
    CGPathMoveToPoint(path, NULL, next[0].x, next[0].y);
  } else {
    CGPathMoveToPoint(path, NULL, points[0].x, points[0].y);
  }

  for (NSUInteger i = 0; i < kNumberOfCorners; ++i) {
    if (i < kNumberOfCorners - 2 || closed) {
      NSUInteger nextIndex = (i + 1 ) % kNumberOfCorners;
      CGPathAddLineToPoint(path, NULL, prev[nextIndex].x, prev[nextIndex].y);
      CGPathAddQuadCurveToPoint(path, NULL, points[nextIndex].x, points[nextIndex].y,
                                next[nextIndex].x, next[nextIndex].y);
    }
  }

  if (closed) {
    CGPathCloseSubpath(path);
  } else {
    CGPathAddLineToPoint(path, NULL, points[kNumberOfCorners - 1].x,
                         points[kNumberOfCorners - 1].y);
  }

  return path;
}

// @see: http://stackoverflow.com/questions/10152574/catextlayer-blurry-text-after-rotation
static void LTCGPathCreateWithStringAuxiliaryMethod(CGRect rect,
                                                    CGMutablePathRef combinedGlyphsPathRef,
                                                    UIFont *font, CGPoint basePoint,
                                                    CTFrameRef frameRef) {
  CFArrayRef lines = CTFrameGetLines(frameRef);
  CFIndex lineCount = CFArrayGetCount(lines);
  CGPoint lineOrigins[lineCount];
  CTFrameGetLineOrigins(frameRef, CFRangeMake(0, lineCount), lineOrigins);

  for (CFIndex lineIndex = 0; lineIndex < lineCount; ++lineIndex) {
    CTLineRef lineRef = (CTLineRef)CFArrayGetValueAtIndex(lines, lineIndex);
    CGPoint lineOrigin = lineOrigins[lineIndex];

    CFArrayRef runs = CTLineGetGlyphRuns(lineRef);

    CFIndex runCount = CFArrayGetCount(runs);
    for (CFIndex runIndex = 0; runIndex < runCount; ++runIndex) {
      CTRunRef runRef = (CTRunRef)CFArrayGetValueAtIndex(runs, runIndex);

      CFIndex glyphCount = CTRunGetGlyphCount(runRef);
      CGGlyph glyphs[glyphCount];
      CGSize glyphAdvances[glyphCount];
      CGPoint glyphPositions[glyphCount];

      CFRange runRange = CFRangeMake(0, glyphCount);
      CTRunGetGlyphs(runRef, CFRangeMake(0, glyphCount), glyphs);
      CTRunGetPositions(runRef, runRange, glyphPositions);

      CTFontGetAdvancesForGlyphs((__bridge CTFontRef)font, kCTFontDefaultOrientation, glyphs,
                                 glyphAdvances, glyphCount);

      for (CFIndex glyphIndex = 0; glyphIndex < glyphCount; ++glyphIndex) {
        CGGlyph glyph = glyphs[glyphIndex];

        // For regular UIBezierPath drawing, we need to invert around the y axis.
        CGAffineTransform glyphTransform =
            CGAffineTransformMakeTranslation(lineOrigin.x + glyphPositions[glyphIndex].x,
                                             rect.size.height - lineOrigin.y -
                                             glyphPositions[glyphIndex].y);
        glyphTransform = CGAffineTransformScale(glyphTransform, 1, -1);

        CGPathRef glyphPathRef = CTFontCreatePathForGlyph((__bridge CTFontRef)font, glyph, &glyphTransform);
        // Carry out the appending.
        CGPathAddPath(combinedGlyphsPathRef, NULL, glyphPathRef);
        @onExit {
          if (glyphPathRef) {
            CGPathRelease(glyphPathRef);
          }
        };

        basePoint.x += glyphAdvances[glyphIndex].width;
        basePoint.y += glyphAdvances[glyphIndex].height;
      }
    }
    basePoint.x = 0;
    basePoint.y += CTFontGetAscent((__bridge CTFontRef)font) +
        CTFontGetDescent((__bridge CTFontRef)font) + CTFontGetLeading((__bridge CTFontRef)font);
  }
}
