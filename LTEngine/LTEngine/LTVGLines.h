// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

@class LTVGGlyph, LTVGGlyphRun, LTVGLine, LTVGLines;

/// Callback for returning a possibly transformed glyph for a given \c glyph.
typedef LTVGGlyph *(^LTVGGlyphTransformBlock)(LTVGGlyph *glyph);

/// Class representing a collection of consecutive \c LTVGLine objects along with the
/// \c NSAttributedString which is represented by these lines.
@interface LTVGLines : NSObject

/// Initializes with the given \c lines and the given \c attributedString which is represented by
/// the given \c lines. The given \c lines must contain at least one element and each element must
/// be a \c LTVGLine. The given \c attributedString must not be \c nil.
- (instancetype)initWithLines:(NSArray *)lines
             attributedString:(NSAttributedString *)attributedString;

/// Returns a path of the lines of this instance, s.t. the vertical distance between the subpaths of
/// two consecutive lines corresponds to the product of the given \c leadingFactor and the baseline
/// distance of the involved lines. The glyphs of the runs of each line are spaced by the product of
/// the given \c trackingFactor and the point size of the font of each run.
- (lt::Ref<CGPathRef>)pathWithLeadingFactor:(CGFloat)leadingFactor
                             trackingFactor:(CGFloat)trackingFactor;

/// Returns a new \c LTVGLines object, created by transforming each glyph of this instance using the
/// given \c block.
- (LTVGLines *)linesWithGlyphsTransformedUsingBlock:(LTVGGlyphTransformBlock)block;

/// Ordered collection of \c LTVGLine objects constituting the lines of this instance.
@property (readonly, nonatomic) NSArray *lines;

/// Attributed string whose path information is represented by the \c lines property.
@property (readonly, nonatomic) NSAttributedString *attributedString;

@end
