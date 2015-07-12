// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTPropertyMacros.h"

#import "LTBrushEffect.h"

/// A class representing a dynamic brush effect used by the \c LTBrush.
/// This class implements the scattering effect, allowing to scatter multiple copies of the brush
/// tip along each brush strokes. This creates the illusion that we're "spraying" the brush.
///
/// @see http://www.photoshopessentials.com/basics/photoshop-brushes/brush-dynamics/
@interface LTBrushScatterEffect : LTBrushEffect

/// Returns an array of scattered \c LTRotatedRects based on the given array of \c LTRotatedRects
/// which represents the original locations of the brush tips.
- (NSMutableArray *)scatteredRectsFromRects:(NSArray *)rects;

/// Controls how far apart the individual brush tips will appear. The maximum distance in each
/// direction will be \c scatter * size of the brush. When set to \c 0, no scattering is applied.
/// Must be in range [0,10], Default is \c 0.
@property (nonatomic) CGFloat scatter;
LTPropertyDeclare(CGFloat, scatter, Scatter);

/// Controls how many copies of the brush tip will appear. Must be in range [1,16], default is \c 1.
@property (nonatomic) NSUInteger count;
LTPropertyDeclare(NSUInteger, count, Count);

/// Control the randomness of the number of additional brush tips (up to \c count, of course).
/// The higher this value, the less likely that exactly \c count brush tips will appear.
/// Must be in range [0,1], deafult is \c 0.
@property (nonatomic) CGFloat countJitter;
LTPropertyDeclare(CGFloat, countJitter, CountJitter);

@end
