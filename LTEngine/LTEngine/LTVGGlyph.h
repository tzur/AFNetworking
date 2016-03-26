// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

/// Class representing a single glyph.
@interface LTVGGlyph : NSObject

/// Initializes with a copy of the given \c path, the given \c glyphIndex, the given \c font and the
/// given \c baselineOrigin. The given \c font must not be \c nil. The given \c path is supposed to
/// represent the glyph with the given \c glyphIndex, \c font and \c baselineOrigin.
- (instancetype)initWithPath:(CGPathRef)path glyphIndex:(CGGlyph)glyphIndex font:(UIFont *)font
              baselineOrigin:(CGPoint)baselineOrigin;

/// Path representation of this instance. Owned by this instance.
@property (readonly, nonatomic) CGPathRef path;

/// Index of the glyph represented by this instance, according to the internal glyph table for the
/// used \c font.
@property (readonly, nonatomic) CGGlyph glyphIndex;

/// Font of this instance.
@property (readonly, nonatomic) UIFont *font;

/// Origin of baseline of this instance.
@property (readonly, nonatomic) CGPoint baselineOrigin;

@end
