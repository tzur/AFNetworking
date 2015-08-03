// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

NS_ASSUME_NONNULL_BEGIN

@class LTRandomState;

/// Representation of the states of the random generators of an \c LTBrush and its elements
/// exhibiting random behavior.
@interface LTBrushRandomState : MTLModel

/// Initializes with a copy of the given \c states.
- (instancetype)initWithStates:(NSDictionary *)states;

/// Random states of the random generators of a brush and its elements exhibiting random behavior
/// (e.g. brush effects). The keys of the dictionary must correctly map to keypaths of the brush
/// from which this instance is retrieved or to which it is applied.
@property (readonly, nonatomic, nullable) NSDictionary *states;

@end

NS_ASSUME_NONNULL_END
