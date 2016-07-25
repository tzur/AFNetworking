// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

NS_ASSUME_NONNULL_BEGIN

/// Protocol for fetching a JSON list that represents a list of products.
@protocol BZRJSONProductsProvider <NSObject>

/// Returns a JSON-serialized \c BZRProduct list.
///
/// The signal sends an \c NSArray of \c NSDictionary and completes. The signal errs if the fetching
/// has failed.
///
/// @return <tt>RACSignal<NSArray<NSDictionary>></tt>
- (RACSignal *)fetchJSONProductList;

@end

NS_ASSUME_NONNULL_END
