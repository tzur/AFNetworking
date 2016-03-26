// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTVGGlyphRun.h"

#import "LTVGGlyph.h"

@implementation LTVGGlyphRun

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithGlyphs:(NSArray *)glyphs {
  if (self = [super init]) {
    [self validateGlyphs:glyphs];
    _glyphs = [glyphs copy];
    _font = ((LTVGGlyph *)self.glyphs.firstObject).font;
    _baselineOrigin = ((LTVGGlyph *)self.glyphs.firstObject).baselineOrigin;
  }
  return self;
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (BOOL)isEqual:(id)object {
  if (self == object) {
    return YES;
  }

  if (![object isKindOfClass:[LTVGGlyphRun class]]) {
    return NO;
  }

  return [((LTVGGlyphRun *)object).glyphs isEqualToArray:self.glyphs];
}

#pragma mark -
#pragma mark Public methods
#pragma mark -

- (lt::Ref<CGPathRef>)pathWithTrackingFactor:(CGFloat)trackingFactor {
  CGMutablePathRef path = CGPathCreateMutable();

  [self.glyphs enumerateObjectsUsingBlock:^(LTVGGlyph *glyph, NSUInteger i, BOOL *) {
    CGFloat tracking = i * trackingFactor * self.font.pointSize;
    CGAffineTransform transformation = CGAffineTransformMakeTranslation(tracking, 0);
    CGPathAddPath(path, &transformation, glyph.path);
  }];

  return lt::Ref<CGPathRef>(path);
}

#pragma mark -
#pragma mark Auxiliary methods
#pragma mark -

- (void)validateGlyphs:(NSArray *)glyphs {
  LTParameterAssert(glyphs.count);
  LTParameterAssert([glyphs.firstObject isKindOfClass:[LTVGGlyph class]]);
  LTVGGlyph *glyph = glyphs.firstObject;

  UIFont *font = glyph.font;
  CGFloat verticalBaselineOrigin = glyph.baselineOrigin.y;

  for (glyph in glyphs) {
    LTParameterAssert([glyph isKindOfClass:[LTVGGlyph class]]);
    LTParameterAssert([glyph.font isEqual:font],
                      @"Glyph of different fonts (%@ vs. %@) within the same run.",
                      glyph.font.fontName ?: @"<nil>", font.fontName ?: @"<nil>");
    LTParameterAssert(verticalBaselineOrigin == glyph.baselineOrigin.y,
                      @"Vertical baseline origin (%g) of glyph with index %d of font %@ does not "
                      "match required vertical baseline origin (%g).",
                      glyph.baselineOrigin.y, glyph.glyphIndex, glyph.font.fontName ?: @"<nil>",
                      verticalBaselineOrigin);
  }
}

@end
