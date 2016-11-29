// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

NS_ASSUME_NONNULL_BEGIN

/// Protocol for fetching a list of products.
@protocol BZRProductsProvider

/// Returns the list of available products for the application.
///
/// The signal sends an \c NSArray of \c BZRProduct and completes. The signal errs if the fetching
/// has failed.
///
/// @return <tt>RACSignal<NSArray<BZRProduct>></tt>
- (RACSignal *)fetchProductList;

/// Sends messages of important events that occur throughout the receiver. The events can be
/// informational or errors. The signal completes when the receiver is deallocated. The signal
/// doesn't err.
///
/// @return <tt>RACSignal<BZREvent></tt>
@property (readonly, nonatomic) RACSignal *eventsSignal;

@end

NS_ASSUME_NONNULL_END
