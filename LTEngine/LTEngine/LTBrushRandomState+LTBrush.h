// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTBrushRandomState.h"

NS_ASSUME_NONNULL_BEGIN

@class LTBrush;

/// Category adding functionality to conveniently create required brush random states for given
/// brushes.
@interface LTBrushRandomState (LTBrush)

/// Returns an instance whose \c states are all initialized with the given \c seed, ready to be
/// applied to the given \c brush.
+ (instancetype)randomStateWithSeed:(NSUInteger)seed forBrush:(LTBrush *)brush;

@end

NS_ASSUME_NONNULL_END
