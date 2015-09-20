// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTCGPathExtensions.h"

#import <CoreFoundation/CoreFoundation.h>
#import <CoreText/CoreText.h>
#import <LTKit/LTCFExtensions.h>

#import "LTGLKitExtensions.h"

/// Structure wrapping the data required for computing the modified path.
typedef struct LTPathModificationData {
  CGMutablePathRef path;
  GLKMatrix3 transform;
} LTPathModificationData;

/// Auxiliary method informing the delegate passed using the given \c delegateInfo about the given
/// path \c element.
static void LTCGPathIteration(void *info, const CGPathElement *element) {
  LTPathInspectionBlock block = (__bridge LTPathInspectionBlock)info;
  CGPoint *points = element->points;

  switch (element->type) {
    case kCGPathElementMoveToPoint:
      block(element->type, {points[0]});
      break;
    case kCGPathElementAddLineToPoint:
      block(element->type, {points[0]});
      break;
    case kCGPathElementAddQuadCurveToPoint:
      block(element->type, {points[0], points[1]});
      break;
    case kCGPathElementAddCurveToPoint:
      block(element->type, {points[0], points[1], points[2]});
      break;
    case kCGPathElementCloseSubpath:
      block(element->type, {});
      break;
    default:
      LTAssert(NO, @"Invalid element type.");
  }
}

/// Adds the provided \c element to the path wrapped in the given \c data, after multiplying the
/// points of the \c element with the transform wrapped in the given \c data.
static void LTRecomputePoints(void *data, const CGPathElement *element);

/// Returns the result of multiplying the provided \c point with the provided \c transform.
static CGPoint LTCGPointApplyTransform(CGPoint point, GLKMatrix3 &transform);

/// Returns a path connecting the provided points. The path is closed iff \c closed is YES.
static CGMutablePathRef LTCreatePolylinePathWithControlPoints(const LTVector2s &polyline,
                                                              BOOL closed);

/// Auxiliary method inserting the glyphs in the provided \c frameRef into the given
/// \c combinedGlyphsPathRef path. The regular line heights are multiplied with the given
/// \c lineHeightFactor. The regular glyph advancement is multiplied with the given
/// \c advancementFactor. The lines are aligned according to the given \c alignment.
static void LTCGPathAppendGlyphsFromFrame(CGMutablePathRef combinedGlyphsPathRef,
                                          CTFrameRef frameRef, CGFloat lineHeightFactor,
                                          CGFloat advancementFactor, NSTextAlignment alignment);

/// Returns the maximum height for all runs in the given \c lineRef.
static CGFloat LTCTLineMaxHeight(CTLineRef lineRef);

/// Appends the glyphs in the given \c lineRef to the given \c combinedGlyphsPathRef path at point
/// \c lineOrigin. The regular glyph advancement is multiplied with the given \c advancementFactor.
static void LTCGPathAppendLine(CGMutablePathRef combinedGlyphsPathRef, CTLineRef lineRef,
                               CGPoint lineOrigin, CGFloat advancementFactor);

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
static void LTComputeSmootheningControlPoints(const LTVector2s &polyline, LTVector2s *prev,
                                              LTVector2s *next, CGFloat smootheningRadius);

/// Computes the additional control points used for a path with gaps. Please refer to the header
/// file for a detailed description of the gap mechanism.
/// Example for the added control points used for gaps in case of four original control points
/// v0, v1, v2, v3:
///
/// v0 - v0start - v1end - v1
/// |                       |
/// v0end             v1start
/// |                       |
/// v3start             v2end
/// |                       |
/// v3 - v3end - v2start - v2
static void LTComputeGapControlPoints(const LTVector2s &polyline, LTVector2s *start,
                                      LTVector2s *end, CGFloat gapSize);

/// Returns a smoothened path from the provided control points. The path is closed iff \c closed is
/// YES.
static CGMutablePathRef LTCreateSmoothenedPathWithControlPoints(const LTVector2s &points,
                                                                const LTVector2s &prev,
                                                                const LTVector2s &next,
                                                                BOOL closed);

#pragma mark -
#pragma mark - Public methods
#pragma mark -

void LTCGPathInspectWithBlock(CGPathRef path, LTPathInspectionBlock block) {
  LTParameterAssert(path);
  LTParameterAssert(block);
  CGPathApply(path, (__bridge void *)block, &LTCGPathIteration);
}

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

static const CGFloat kEpsilon = 1e-8;

CGPathRef LTCGPathCreateWithControlPointsAndGapsAroundVertices(const LTVector2s &polyline,
                                                               CGFloat gapSize, BOOL closed) {
  LTParameterAssert(polyline.size() > 1);
  LTParameterAssert(gapSize >= 0);
  const NSUInteger kNumberOfCorners = polyline.size();
  const NSUInteger kNumberOfEdges = closed ? kNumberOfCorners : kNumberOfCorners - 1;

  if (gapSize == 0) {
    return LTCreatePolylinePathWithControlPoints(polyline, closed);
  }

  LTVector2s start(kNumberOfCorners);
  LTVector2s end(kNumberOfCorners);
  LTComputeGapControlPoints(polyline, &start, &end, gapSize);

  CGMutablePathRef path = CGPathCreateMutable();
  for (NSUInteger i = 0; i < kNumberOfEdges; ++i) {
    if ((start[i] - end[i]).length() < kEpsilon) {
      continue;
    }
    CGPathMoveToPoint(path, NULL, start[i].x, start[i].y);
    CGPathAddLineToPoint(path, NULL, end[i].x, end[i].y);
    CGPathCloseSubpath(path);
  }
  return path;
}

CGPathRef LTCGPathCreateWithControlPointsAndCirclesAroundVertices(const LTVector2s &polyline,
                                                                  CGFloat circleRadius,
                                                                  BOOL closed) {
  LTParameterAssert(polyline.size() > 1);
  LTParameterAssert(circleRadius >= 0);

  if (circleRadius == 0) {
    return LTCreatePolylinePathWithControlPoints(polyline, closed);
  }

  CGPathRef pathWithGaps =
      LTCGPathCreateWithControlPointsAndGapsAroundVertices(polyline, circleRadius, closed);
  CGMutablePathRef mutablePathWithGaps = CGPathCreateMutableCopy(pathWithGaps);
  CGPathRelease(pathWithGaps);

  for (NSUInteger i = 0; i < polyline.size(); ++i) {
    CGPathAddEllipseInRect(mutablePathWithGaps, NULL,
                           CGRectCenteredAt((CGPoint)polyline[i],
                                            CGSizeMakeUniform(2 * circleRadius)));
  }
  return mutablePathWithGaps;
}

// @see: http://stackoverflow.com/questions/10152574/catextlayer-blurry-text-after-rotation
CGMutablePathRef LTCGPathCreateWithString(NSString *string, UIFont *font) {
  NSAttributedString *attributedString =
      [[NSAttributedString alloc] initWithString:string attributes:@{NSFontAttributeName: font}];
  CGPathRef immutableResult = LTCGPathCreateWithAttributedString(attributedString);
  CGMutablePathRef mutableResult = CGPathCreateMutableCopy(immutableResult);
  CGPathRelease(immutableResult);
  return mutableResult;
}

CGPathRef LTCGPathCreateWithAttributedString(NSAttributedString *attributedString,
                                             CGFloat lineHeightFactor,
                                             CGFloat advancementFactor) {
  __block CTFramesetterRef frameSetterRef = NULL;
  __block CTFrameRef frameRef = NULL;

  CGMutablePathRef combinedGlyphsPathRef = CGPathCreateMutable();

  @onExit {
    if (combinedGlyphsPathRef) {
      CGPathRelease(combinedGlyphsPathRef);
    }
  };

  if (!combinedGlyphsPathRef) {
    return NULL;
  }

  // It would be easy to wrap the text into a different shape, including arbitrary bezier paths,
  // if needed.
  UIBezierPath *frameShape =
      [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, CGFLOAT_MAX, CGFLOAT_MAX)];

  frameSetterRef =
      CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)attributedString);

  @onExit {
    LTCFSafeRelease(frameSetterRef);
  };

  if (!frameSetterRef) {
    return NULL;
  }

  frameRef = CTFramesetterCreateFrame(frameSetterRef, CFRangeMake(0,0), [frameShape CGPath], NULL);

  @onExit {
    LTCFSafeRelease(frameRef);
  };

  if (!frameRef) {
    return NULL;
  }

  NSParagraphStyle *paragraphStyle = [attributedString attribute:NSParagraphStyleAttributeName
                                                         atIndex:0 effectiveRange:NULL];
  NSTextAlignment alignment = paragraphStyle ? paragraphStyle.alignment : NSTextAlignmentLeft;
  LTCGPathAppendGlyphsFromFrame(combinedGlyphsPathRef, frameRef, lineHeightFactor,
                                advancementFactor, alignment);

  // Mirror the path around the y-axis and translate it such that the top left bounding box corner
  // of the path corresponds to \c CGPointZero.
  CGRect boundingBox = CGPathGetBoundingBox(combinedGlyphsPathRef);

  if (std::min(boundingBox.size) == 0) {
    return NULL;
  }

  CGAffineTransform translateToPointZero = CGAffineTransformMakeTranslation(-boundingBox.origin.x,
                                                                            -boundingBox.origin.y);
  CGAffineTransform mirrorAroundYAxis = CGAffineTransformMakeScale(1, -1);
  CGAffineTransform translateTopLeftCornerToPointZero =
      CGAffineTransformMakeTranslation(0, boundingBox.size.height);

  CGAffineTransform transform =
      CGAffineTransformConcat(translateToPointZero,
                              CGAffineTransformConcat(mirrorAroundYAxis,
                                                      translateTopLeftCornerToPointZero));
  CGPathRef result = CGPathCreateCopyByTransformingPath(combinedGlyphsPathRef, &transform);
  return result;
}

CGPathRef LTCGPathCreateWithCircularSector(LTVector2 center, CGFloat radius, CGFloat startAngle,
                                           CGFloat endAngle, BOOL clockwise) {
  CGMutablePathRef path = CGPathCreateMutable();
  CGPathMoveToPoint(path, NULL, center.x, center.y);
  CGPathAddArc(path, NULL, center.x, center.y, radius, startAngle, endAngle, clockwise);
  CGPathCloseSubpath(path);
  return path;
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

static void LTComputeSmootheningControlPoints(const LTVector2s &polyline, LTVector2s *prev,
                                              LTVector2s *next, CGFloat smootheningRadius) {
  const NSUInteger kNumberOfCorners = polyline.size();
  LTParameterAssert(!prev->size());
  LTParameterAssert(!next->size());
  NSUInteger prevIndex = kNumberOfCorners - 1;
  LTVector2 prevDirection = polyline[0] - polyline[prevIndex];
  LTVector2 normalizedPrevDirection =
      prevDirection.length() < kEpsilon ? LTVector2Zero : prevDirection.normalized();

  for (NSUInteger i = 0; i < kNumberOfCorners; ++i) {
    NSUInteger nextIndex = (i + 1) % kNumberOfCorners;
    LTVector2 currentDirection = polyline[nextIndex] - polyline[i];
    CGFloat minRadius = MIN(MIN(prevDirection.length(), currentDirection.length()) / 2,
                            smootheningRadius);
    prev->push_back(polyline[i] - (minRadius * normalizedPrevDirection));
    LTVector2 normalizedCurrentDirection =
        currentDirection.length() < kEpsilon ? LTVector2Zero : currentDirection.normalized();
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

static void LTComputeGapControlPoints(const LTVector2s &polyline, LTVector2s *start,
                                      LTVector2s *end, CGFloat gapSize) {
  const NSUInteger kNumberOfCorners = polyline.size();
  LTParameterAssert(start->size() == kNumberOfCorners);
  LTParameterAssert(end->size() == kNumberOfCorners);

  for (NSUInteger i = 0; i < kNumberOfCorners; ++i) {
    NSUInteger nextIndex = (i + 1) % kNumberOfCorners;
    LTVector2 currentDirection = polyline[nextIndex] - polyline[i];
    CGFloat minGapSize = MIN(currentDirection.length() / 2, gapSize);
    LTVector2 normalizedCurrentDirection = (currentDirection).normalized();
    start->at(i) = polyline[i] + (minGapSize * normalizedCurrentDirection);
    end->at(i) = polyline[nextIndex] - (minGapSize * normalizedCurrentDirection);
  }
}

// @see: http://stackoverflow.com/questions/10152574/catextlayer-blurry-text-after-rotation
static void LTCGPathAppendGlyphsFromFrame(CGMutablePathRef combinedGlyphsPathRef,
                                          CTFrameRef frameRef, CGFloat lineHeightFactor,
                                          CGFloat advancementFactor, NSTextAlignment alignment) {
  // From the documentation of \c CTFramesetterSuggestFrameSizeWithConstraints:
  // A value of CGFLOAT_MAX for either dimension [of the frame size] indicates that it should be
  // treated as unconstrained.
  CGRect rect = CGPathGetBoundingBox(CTFrameGetPath(frameRef));
  BOOL framePathHasInfiniteWidth = rect.size.width == CGFLOAT_MAX;
  BOOL framePathHasInfiniteHeight = rect.size.height == CGFLOAT_MAX;
  CGFloat currentLineOriginY = 0;

  CFArrayRef lines = CTFrameGetLines(frameRef);
  CFIndex lineCount = CFArrayGetCount(lines);
  CGPoint lineOrigins[lineCount];
  CTFrameGetLineOrigins(frameRef, CFRangeMake(0, lineCount), lineOrigins);

  for (CFIndex lineIndex = 0; lineIndex < lineCount; ++lineIndex) {
    CTLineRef lineRef = (CTLineRef)CFArrayGetValueAtIndex(lines, lineIndex);
    CGPoint lineOrigin = lineOrigins[lineIndex];

    if (framePathHasInfiniteWidth) {
      lineOrigin.x = 0;
    }
    if (framePathHasInfiniteHeight) {
      lineOrigin.y = currentLineOriginY;
      currentLineOriginY -= LTCTLineMaxHeight(lineRef);
    }

    lineOrigin.y *= lineHeightFactor;

    CGMutablePathRef linePathRef = CGPathCreateMutable();
    @onExit {
      if (linePathRef) {
        CGPathRelease(linePathRef);
      }
    };
    LTCGPathAppendLine(linePathRef, lineRef, lineOrigin, advancementFactor);
    CGRect linePathBoundingBox = CGPathGetBoundingBox(linePathRef);

    // Align text.
    CGAffineTransform transform;
    if (alignment == NSTextAlignmentCenter) {
      transform = CGAffineTransformMakeTranslation(-linePathBoundingBox.size.width / 2, 0);
    } else if (alignment == NSTextAlignmentRight) {
      transform = CGAffineTransformMakeTranslation(-linePathBoundingBox.size.width, 0);
    } else {
      transform = CGAffineTransformIdentity;
    }
    CGPathRef alignedLinePathRef = CGPathCreateCopyByTransformingPath(linePathRef, &transform);
    @onExit {
      if (alignedLinePathRef) {
        CGPathRelease(alignedLinePathRef);
      }
    };
    CGPathAddPath(combinedGlyphsPathRef, NULL, alignedLinePathRef);
  }
}

static CGFloat LTCTLineMaxHeight(CTLineRef lineRef) {
  CGFloat maxLineHeight = 0;
  CFArrayRef runs = CTLineGetGlyphRuns(lineRef);
  CFIndex runCount = CFArrayGetCount(runs);

  for (CFIndex runIndex = 0; runIndex < runCount; ++runIndex) {
    CTRunRef runRef = (CTRunRef)CFArrayGetValueAtIndex(runs, runIndex);
    CTFontRef runFontRef =
        (CTFontRef)CFDictionaryGetValue(CTRunGetAttributes(runRef), kCTFontAttributeName);
    maxLineHeight = MAX(maxLineHeight, std::abs(CTFontGetAscent(runFontRef)) +
                        std::abs(CTFontGetDescent(runFontRef)) +
                        std::abs(CTFontGetLeading(runFontRef)));
  }
  return maxLineHeight;
}

static void LTCGPathAppendLine(CGMutablePathRef combinedGlyphsPathRef, CTLineRef lineRef,
                               CGPoint lineOrigin, CGFloat advancementFactor) {
  CFArrayRef runs = CTLineGetGlyphRuns(lineRef);
  CFIndex runCount = CFArrayGetCount(runs);
  CFIndex glyphIndex = 0;

  for (CFIndex runIndex = 0; runIndex < runCount; ++runIndex) {
    CTRunRef runRef = (CTRunRef)CFArrayGetValueAtIndex(runs, runIndex);
    CTFontRef runFontRef =
        (CTFontRef)CFDictionaryGetValue(CTRunGetAttributes(runRef), kCTFontAttributeName);

    CFIndex glyphCount = CTRunGetGlyphCount(runRef);
    std::vector<CGGlyph> glyphs(glyphCount);
    CGPoints glyphPositions(glyphCount);

    CFRange runRange = CFRangeMake(0, glyphCount);
    CTRunGetGlyphs(runRef, CFRangeMake(0, glyphCount), glyphs.data());
    CTRunGetPositions(runRef, runRange, glyphPositions.data());

    for (CFIndex glyphPerRunIndex = 0; glyphPerRunIndex < glyphCount; ++glyphPerRunIndex) {
      CGGlyph glyph = glyphs[glyphPerRunIndex];

      CGAffineTransform glyphTransform =
          CGAffineTransformMakeTranslation(lineOrigin.x +
                                           glyphPositions[glyphPerRunIndex].x * advancementFactor,
                                           lineOrigin.y + glyphPositions[glyphPerRunIndex].y);
      CGPathRef glyphPathRef = CTFontCreatePathForGlyph(runFontRef, glyph, &glyphTransform);
      @onExit {
        if (glyphPathRef) {
          CGPathRelease(glyphPathRef);
        }
      };

      // Carry out the appending.
      CGPathAddPath(combinedGlyphsPathRef, NULL, glyphPathRef);
      ++glyphIndex;
    }
  }
}
