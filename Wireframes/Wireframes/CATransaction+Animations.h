// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

NS_ASSUME_NONNULL_BEGIN

/// Utilities over CoreAnimation animation transaction.
@interface CATransaction (Animations)

/// Performs the given block inside a new transaction, configured to disable implicit animations.
+ (void)performWithoutAnimation:(LTVoidBlock)block;

@end

NS_ASSUME_NONNULL_END
