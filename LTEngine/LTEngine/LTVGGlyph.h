// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

NS_ASSUME_NONNULL_BEGIN

/// Class representing a single glyph.
@interface LTVGGlyph : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with a copy of the given \c path, the given \c glyphIndex, the given \c font and the
/// given \c baselineOrigin. The given \c font must not be \c nil. The given \c path is supposed to
/// represent the glyph with the given \c glyphIndex, \c font and \c baselineOrigin.
- (instancetype)initWithPath:(nullable CGPathRef)path glyphIndex:(CGGlyph)glyphIndex
                        font:(UIFont *)font baselineOrigin:(CGPoint)baselineOrigin
    NS_DESIGNATED_INITIALIZER;

/// Path representation of this instance. Owned by this instance.
@property (readonly, nonatomic, nullable) CGPathRef path NS_RETURNS_INNER_POINTER
    CF_RETURNS_NOT_RETAINED;

/// Index of the glyph represented by this instance, according to the internal glyph table for the
/// used \c font.
@property (readonly, nonatomic) CGGlyph glyphIndex;

/// Font of this instance.
@property (readonly, nonatomic) UIFont *font;

/// Origin of baseline of this instance.
@property (readonly, nonatomic) CGPoint baselineOrigin;

@end

NS_ASSUME_NONNULL_END
