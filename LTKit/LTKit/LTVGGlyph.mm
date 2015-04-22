// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTVGGlyph.h"

#import <CoreText/CTFont.h>

#import "LTVGGlyphRun.h"

@implementation LTVGGlyph

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithPath:(CGPathRef)path glyphIndex:(CGGlyph)glyphIndex font:(UIFont *)font
              baselineOrigin:(CGPoint)baselineOrigin {
  LTParameterAssert(font);

  if (self = [super init]) {
    // Allow empty paths since blank glyphs are considered glyphs, too.
    _path = CGPathCreateCopy(path);
    _glyphIndex = glyphIndex;
    _font = font;
    _baselineOrigin = baselineOrigin;
  }
  return self;
}

- (void)dealloc {
  CGPathRelease(_path);
  _path = NULL;
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (BOOL)isEqual:(id)object {
  if (self == object) {
    return YES;
  }

  if (![object isKindOfClass:[LTVGGlyph class]]) {
    return NO;
  }

  LTVGGlyph *glyph = object;

  return CGPathEqualToPath(glyph.path, self.path) && glyph.glyphIndex == self.glyphIndex &&
      [glyph.font isEqual:self.font] && glyph.baselineOrigin == self.baselineOrigin;
}

@end
