// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTVGTypesetter.h"

#import <CoreGraphics/CGFont.h>
#import <CoreText/CoreText.h>
#import <LTKit/LTCFExtensions.h>

#import "LTVGGlyph.h"
#import "LTVGGlyphRun.h"
#import "LTVGLine.h"
#import "LTVGLines.h"

@implementation LTVGTypesetter

#pragma mark -
#pragma mark Public methods
#pragma mark -

+ (LTVGLines *)linesFromAttributedString:(NSAttributedString *)attributedString {
  LTParameterAssert(attributedString);

  if ([attributedString.string isEqualToString:@""]) {
    return [[LTVGLines alloc] initWithLines:@[[[LTVGLine alloc] initWithGlyphRuns:@[]]]
                           attributedString:attributedString];
  }

  lt::Ref<CTFrameRef> frame = [self newFrameForAttributedString:attributedString];
  LTAssert(frame, @"frameForAttributedString returned nil CTFrameRef");

  CGPoints lineOrigins = [self originsOfLinesInFrame:frame.get()];
  return [self linesInFrame:frame.get() lineOrigins:lineOrigins attributedString:attributedString];
}

+ (LTVGGlyph *)glyphWithIndex:(CGGlyph)index font:(UIFont *)font
               baselineOrigin:(CGPoint)baselineOrigin {
  LTParameterAssert(font);

  CGAffineTransform mirrorAroundXAxis = CGAffineTransformMakeScale(1, -1);
  CGAffineTransform transformation =
      CGAffineTransformConcat(mirrorAroundXAxis,
                              CGAffineTransformMakeTranslation(baselineOrigin.x, baselineOrigin.y));
  lt::Ref<CTFontRef> fontForPath(CTFontCreateWithName((CFStringRef)font.fontName,
                                                                   font.pointSize, NULL));
  lt::Ref<CGPathRef> path(CTFontCreatePathForGlyph(fontForPath.get(), index, &transformation));

  return [[LTVGGlyph alloc] initWithPath:path.get() glyphIndex:index font:font
                          baselineOrigin:baselineOrigin];
}

#pragma mark -
#pragma mark Auxiliary methods
#pragma mark -

+ (lt::Ref<CTFrameRef>)newFrameForAttributedString:(NSAttributedString *)attributedString {
  lt::Ref<CTFramesetterRef> frameSetter(
    CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)attributedString)
  );

  if (!frameSetter) {
    return lt::Ref<CTFrameRef>();
  }

  lt::Ref<CGPathRef> path(CGPathCreateWithRect(CGRectMake(0, 0, CGFLOAT_MAX, CGFLOAT_MAX), NULL));

  return lt::Ref<CTFrameRef>(CTFramesetterCreateFrame(frameSetter.get(), CFRangeMake(0,0),
                                                      path.get(), NULL));
}

+ (CGPoints)originsOfLinesInFrame:(CTFrameRef)frameRef {
  // From the documentation of \c CTFramesetterSuggestFrameSizeWithConstraints:
  // A value of CGFLOAT_MAX for either dimension [of the frame size] indicates that it should be
  // treated as unconstrained.
  CGRect rect = CGPathGetBoundingBox(CTFrameGetPath(frameRef));
  BOOL framePathHasInfiniteWidth = rect.size.width == CGFLOAT_MAX;
  BOOL framePathHasInfiniteHeight = rect.size.height == CGFLOAT_MAX;

  CFArrayRef linesRef = CTFrameGetLines(frameRef);
  CFIndex lineCount = CFArrayGetCount(linesRef);
  CGPoint lineOrigins[lineCount];
  CTFrameGetLineOrigins(frameRef, CFRangeMake(0, lineCount), lineOrigins);

  CGPoints result(lineCount);
  CGFloat currentLineOriginY = 0;
  for (CFIndex lineIndex = 0; lineIndex < lineCount; ++lineIndex) {
    CTLineRef lineRef = (CTLineRef)CFArrayGetValueAtIndex(linesRef, lineIndex);
    CGPoint lineOrigin = lineOrigins[lineIndex];

    if (framePathHasInfiniteWidth) {
      lineOrigin.x = 0;
    }

    if (framePathHasInfiniteHeight) {
      lineOrigin.y = currentLineOriginY;
      currentLineOriginY += LTCTLineMaxHeight(lineRef);
    }

    result[lineIndex] = lineOrigin;
  }

  return result;
}

+ (LTVGLines *)linesInFrame:(CTFrameRef)frameRef lineOrigins:(const CGPoints &)lineOrigins
           attributedString:(NSAttributedString *)attributedString {
  NSMutableArray *lines = [NSMutableArray array];
  CFArrayRef linesRef = CTFrameGetLines(frameRef);

  for (NSUInteger i = 0; i < lineOrigins.size(); ++i) {
    CGPoint lineOrigin = lineOrigins[i];
    CTLineRef lineRef = (CTLineRef)CFArrayGetValueAtIndex(linesRef, i);
    CFArrayRef runsRef = CTLineGetGlyphRuns(lineRef);
    CFIndex runCount = CFArrayGetCount(runsRef);

    NSMutableArray *runs = [NSMutableArray array];

    for (CFIndex runIndex = 0; runIndex < runCount; ++runIndex) {
      CTRunRef runRef = (CTRunRef)CFArrayGetValueAtIndex(runsRef, runIndex);
      [runs addObject:[self runForRunRef:runRef withOrigin:lineOrigin]];
    }

    LTVGLine *line = [[LTVGLine alloc] initWithGlyphRuns:runs];
    [lines addObject:line];
  }

  return [[LTVGLines alloc] initWithLines:lines attributedString:attributedString];
}

+ (LTVGGlyphRun *)runForRunRef:(CTRunRef)runRef withOrigin:(CGPoint)origin {
  NSMutableArray *glyphs = [NSMutableArray array];
  UIFont *font = [self fontForRunRef:runRef];

  CFIndex glyphCount = CTRunGetGlyphCount(runRef);
  std::vector<CGGlyph> glyphIndices(glyphCount);
  CGPoints glyphPositions(glyphCount);

  CFRange runRange = CFRangeMake(0, glyphCount);
  CTRunGetGlyphs(runRef, CFRangeMake(0, glyphCount), glyphIndices.data());
  CTRunGetPositions(runRef, runRange, glyphPositions.data());

  for (CFIndex glyphInRunIndex = 0; glyphInRunIndex < glyphCount; ++glyphInRunIndex) {
    CGGlyph glyphIndex = glyphIndices[glyphInRunIndex];

    CGPoint baselineOrigin = origin + glyphPositions[glyphInRunIndex];

    [glyphs addObject:[self glyphWithIndex:glyphIndex font:font baselineOrigin:baselineOrigin]];
  }

  return [[LTVGGlyphRun alloc] initWithGlyphs:glyphs];
}

+ (UIFont *)fontForRunRef:(CTRunRef)runRef {
  CTFontRef runFontRef = (CTFontRef)CFDictionaryGetValue(CTRunGetAttributes(runRef),
                                                         kCTFontAttributeName);
  NSString *fontName = (__bridge_transfer NSString *)CTFontCopyName(runFontRef,
                                                                    kCTFontPostScriptNameKey);

  return [UIFont fontWithName:fontName size:CTFontGetSize(runFontRef)];
}

#pragma mark -
#pragma mark Static auxiliary functions
#pragma mark -

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

@end
