// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import <ReactiveObjC/RACStream.h>

NS_ASSUME_NONNULL_BEGIN

@interface RACStream<__covariant ValueType> (Photons)

/// Returns a stream of values for which the pointer comparison returns NO when compared to the
/// previous value.
///
/// @note this operator is similar to the \c distinctUntilChanged operator, but the equality is
/// determined by pointer comparison only and not by calling \c isEqual:.
- (__kindof RACStream<ValueType> *)ptn_identicallyDistinctUntilChanged;

@end

NS_ASSUME_NONNULL_END
