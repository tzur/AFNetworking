// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Amit Goldstein.

NS_ASSUME_NONNULL_BEGIN

/// Implementation of a sliding window filter with a fixed size. The size of the window is
/// determined according to the size of the \c kernel provided upon initialization. Filtering is
/// done by calculating the convolution of the window with the reversed kernel, or in other words,
/// the weighted sum of all the elements in the window, where the weight of the first element is the
/// first element of the \c kernel, and so on. When the number of elements in the window is smaller
/// than its size the clamp boundary condition is used, using the value of the first element in the
/// window for all missing values.
@interface LTSlidingWindowFilter : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes sliding window filter with the given \c kernel, where the first element is the
/// weight of the oldest value in the sliding window, and the last element is the weight of the most
/// recent value in the window.
- (instancetype)initWithKernel:(const std::vector<CGFloat> &)kernel NS_DESIGNATED_INITIALIZER;

/// Removes all elements currently in the window. Subsequent filter operations will use the first
/// inserted element instead of missing values (clamp boundary condition).
- (void)clear;

/// Pushes the given \c value into the sliding window and returns the filtered result: the weighted
/// average of the values currently in the window. In case this is the first value pushed into the
/// window, the entire window will be filled with it.
- (CGFloat)pushValueAndFilter:(CGFloat)value;

@end

NS_ASSUME_NONNULL_END
