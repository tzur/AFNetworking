// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTPaintingStrategy.h"

@class LTBrush, LTRandom;

/// Abstract class defining a strategy for painting using a single \c LTBrush on an
/// \c LTPaintingImageProcessor. Subclasses must implement the methods required by the
/// \c LTPaintingStrategy protocol.
///
/// @see LTPaintingStrategy
@interface LTSingleBrushPaintingStrategy : NSObject <LTPaintingStrategy>

/// Initializes the strategy with the given brush.
- (instancetype)initWithBrush:(LTBrush *)brush;

/// Brush used for painting.
@property (readonly, nonatomic) LTBrush *brush;

/// Random generator used by the strategy.
@property (readonly, nonatomic) LTRandom *random;

@end
