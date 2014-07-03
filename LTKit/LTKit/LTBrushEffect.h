// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

@class LTRandom;

/// @class LTBrushEffect
///
/// Abstract class implementing shared functionality of the different \c LTBrushXXXEffects.
@interface LTBrushEffect : NSObject

/// Initializes the brush effect with its own random generator.
- (instancetype)init;

/// Designated initializer: initializes the brush effect with the given random generator.
- (instancetype)initWithRandom:(LTRandom *)random;

/// The random generator used by the effect.
@property (readonly, nonatomic) LTRandom *random;

@end
