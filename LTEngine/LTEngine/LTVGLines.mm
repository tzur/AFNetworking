// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTVGLines.h"

#import "LTVGGlyphRun.h"
#import "LTVGLine.h"

NS_ASSUME_NONNULL_BEGIN

@implementation LTVGLines

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithLines:(NSArray<LTVGLine *> *)lines
             attributedString:(NSAttributedString *)attributedString {
  LTParameterAssert(attributedString);

  if (self = [super init]) {
    LTParameterAssert(lines.count);
    _lines = [lines copy];
    _attributedString = [attributedString copy];
  }
  return self;
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (BOOL)isEqual:(LTVGLines *)lines {
  if (self == lines) {
    return YES;
  }

  if (![lines isKindOfClass:[LTVGLines class]]) {
    return NO;
  }

  return [lines.lines isEqualToArray:self.lines] &&
      [lines.attributedString isEqualToAttributedString:self.attributedString];
}

#pragma mark -
#pragma mark Public methods
#pragma mark -

- (lt::Ref<CGPathRef>)pathWithLeadingFactor:(CGFloat)leadingFactor
                             trackingFactor:(CGFloat)trackingFactor {
  NSParagraphStyle *paragraphStyle = [self.attributedString attribute:NSParagraphStyleAttributeName
                                                              atIndex:0 effectiveRange:NULL];
  NSTextAlignment alignment = paragraphStyle ? paragraphStyle.alignment : NSTextAlignmentLeft;

  return [self pathWithLeadingFactor:leadingFactor trackingFactor:trackingFactor
                           alignment:alignment];
}

- (lt::Ref<CGPathRef>)pathWithLeadingFactor:(CGFloat)leadingFactor
                             trackingFactor:(CGFloat)trackingFactor
                                  alignment:(NSTextAlignment)alignment {
  CGMutablePathRef path = CGPathCreateMutable();

  CGFloat leading = 0;

  for (LTVGLine *line in self.lines) {
    lt::Ref<CGPathRef> linePath = [line pathWithTrackingFactor:trackingFactor];
    CGAffineTransform alignmentTransformation = [self transformationForPath:linePath.get()
                                                               andAlignment:alignment];
    CGAffineTransform finalTransformation =
        CGAffineTransformConcat(CGAffineTransformMakeTranslation(0, leading),
                                alignmentTransformation);
    CGPathAddPath(path, &finalTransformation, linePath.get());

    leading += leadingFactor * line.lineHeight;
  }
  return lt::Ref<CGPathRef>(path);
}

- (LTVGLines *)linesWithGlyphsTransformedUsingBlock:(LTVGGlyph *(^)(LTVGGlyph *glyph))block {
  LTParameterAssert(block);
  NSMutableArray *correctedLines = [NSMutableArray array];

  for (LTVGLine *line in self.lines) {
    NSMutableArray *updatedRuns = [NSMutableArray array];
    for (LTVGGlyphRun *run in line.glyphRuns) {
      NSMutableArray *updatedGlyphs = [NSMutableArray array];
      for (LTVGGlyph *glyph in run.glyphs) {
        [updatedGlyphs addObject:block(glyph)];
      }
      [updatedRuns addObject:[[LTVGGlyphRun alloc] initWithGlyphs:updatedGlyphs]];
    }
    [correctedLines addObject:[[LTVGLine alloc] initWithGlyphRuns:updatedRuns]];
  }

  return [[LTVGLines alloc] initWithLines:correctedLines attributedString:self.attributedString];
}

#pragma mark -
#pragma mark Auxiliary methods
#pragma mark -

/// Returns the transformation required to align the given \c path according to the given
/// \c aligment.
- (CGAffineTransform)transformationForPath:(CGPathRef)path andAlignment:(NSTextAlignment)alignment {
  CGRect pathBoundingBox = CGPathGetBoundingBox(path);

  if (alignment == NSTextAlignmentCenter) {
    return CGAffineTransformMakeTranslation(-pathBoundingBox.size.width / 2, 0);
  } else if (alignment == NSTextAlignmentRight) {
    return CGAffineTransformMakeTranslation(-pathBoundingBox.size.width, 0);
  } else {
    return CGAffineTransformIdentity;
  }
}

@end

NS_ASSUME_NONNULL_END
