// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

NS_ASSUME_NONNULL_BEGIN

@class LTVGGlyph;

/// Class representing a glyph run (an ordered collection of glyphs sharing the same attributes).
@interface LTVGGlyphRun : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with a copy of the given \c glyphs array which must contain at least contain one
/// element. All elements must be of the same font. The \c baselineOrigin of the returned instance
/// corresponds to the baseline origin of the first element in the given \c glyphs.
- (instancetype)initWithGlyphs:(NSArray<LTVGGlyph *> *)glyphs NS_DESIGNATED_INITIALIZER;

/// Returns a path of the runs (which, in turn, are paths of combined glyph paths) of this instance,
/// s.t. the glyphs of this run are spaced by the product of the given \c trackingFactor and the
/// point size of the font of this run.
- (lt::Ref<CGPathRef>)pathWithTrackingFactor:(CGFloat)trackingFactor;

/// Ordered collection of glyphes constituting this run.
@property (readonly, nonatomic) NSArray<LTVGGlyph *> *glyphs;

/// Font of this instance.
@property (readonly, nonatomic) UIFont *font;

/// Origin of baseline of this instance.
@property (readonly, nonatomic) CGPoint baselineOrigin;

@end

NS_ASSUME_NONNULL_END
