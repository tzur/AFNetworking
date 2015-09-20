// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

/// Class representing a glyph run (an ordered collection of glyphs sharing the same attributes).
@interface LTVGGlyphRun : NSObject

/// Initializes with a copy of the given \c glyphs array. The given \c glyphs array must at least
/// contain one element and each element is required to be a \c LTVGGlyph. All elements must be of
/// the same font and their baseline origin must have the same y-coordinate.
- (instancetype)initWithGlyphs:(NSArray *)glyphs;

/// Returns a path of the runs (which, in turn, are paths of combined glyph paths) of this instance,
/// s.t. the glyphs of this run are spaced by the product of the given \c trackingFactor and the
/// point size of the font of this run. It is the responsibility of the caller to release the
/// returned path.
- (CGPathRef)newPathWithTrackingFactor:(CGFloat)trackingFactor;

/// Ordered collection of \c LTVGGlyph constituting this run.
@property (readonly, nonatomic) NSArray *glyphs;

/// Font of this instance.
@property (readonly, nonatomic) UIFont *font;

/// Origin of baseline of this instance.
@property (readonly, nonatomic) CGPoint baselineOrigin;

@end
