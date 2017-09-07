// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTVGGlyphRun.h"

#import "LTVGGlyph.h"

NS_ASSUME_NONNULL_BEGIN

@implementation LTVGGlyphRun

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithGlyphs:(NSArray<LTVGGlyph *> *)glyphs {
  if (self = [super init]) {
    [self validateGlyphs:glyphs];
    _glyphs = [glyphs copy];
    _font = self.glyphs.firstObject.font;
    _baselineOrigin = self.glyphs.firstObject.baselineOrigin;
  }
  return self;
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (BOOL)isEqual:(LTVGGlyphRun *)run {
  if (self == run) {
    return YES;
  }

  if (![run isKindOfClass:[LTVGGlyphRun class]]) {
    return NO;
  }

  return [run.glyphs isEqualToArray:self.glyphs];
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

- (void)validateGlyphs:(NSArray<LTVGGlyph *> *)glyphs {
  LTParameterAssert(glyphs.count);
  LTParameterAssert([glyphs.firstObject isKindOfClass:[LTVGGlyph class]],
                    @"Given object %@ must be a glyph", glyphs.firstObject);
  LTVGGlyph *glyph = glyphs.firstObject;

  UIFont *font = glyph.font;
  CGFloat verticalBaselineOrigin = glyph.baselineOrigin.y;

  for (LTVGGlyph *glyph in glyphs) {
    LTParameterAssert([glyph.font isEqual:font],
                      @"Glyph of different fonts (%@ vs. %@) within the same run.",
                      glyph.font.fontName ?: @"<nil>", font.fontName ?: @"<nil>");
    if (verticalBaselineOrigin != glyph.baselineOrigin.y) {
      LogWarning(@"Vertical baseline origin (%g) of glyph with index %d of font %@ does not match "
                 "expected vertical baseline origin (%g)", glyph.baselineOrigin.y,
                 glyph.glyphIndex, glyph.font.fontName, verticalBaselineOrigin);
    }
  }
}

@end

NS_ASSUME_NONNULL_END
