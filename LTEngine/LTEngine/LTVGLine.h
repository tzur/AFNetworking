// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

NS_ASSUME_NONNULL_BEGIN

@class LTVGGlyphRun;

/// Class representing a line consisting of \c LTVGGlyphRun.
@interface LTVGLine : NSObject

/// Initializes with a copy of the given \c runs array. The given \c runs array must not be \c nil
/// and each element must be a \c LTVGGlyphRun. The y-coordinate of the baselines must be the same
/// for all given \c runs.
- (instancetype)initWithGlyphRuns:(NSArray<LTVGGlyphRun *> *)runs;

/// Returns a path of the runs of this instance, s.t. the glyphs of the runs are spaced by the
/// product of the given \c trackingFactor and the point size of the font of the corresponding run.
- (lt::Ref<CGPathRef>)pathWithTrackingFactor:(CGFloat)trackingFactor;

/// Ordered collection of runs constituting this line.
@property (readonly, nonatomic) NSArray<LTVGGlyphRun *> *glyphRuns;

/// Origin of baseline of this instance. Is \c CGPointNull if this instance does not consist of any
/// glyph runs.
@property (readonly, nonatomic) CGPoint baselineOrigin;

/// Height of this line. Is \c 0 if this instance does not consist of any glyph runs.
@property (readonly, nonatomic) CGFloat lineHeight;

@end

NS_ASSUME_NONNULL_END
