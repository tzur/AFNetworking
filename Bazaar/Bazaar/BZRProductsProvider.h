// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZREventEmitter.h"
#import "BZRTypedefs.h"

NS_ASSUME_NONNULL_BEGIN

/// Protocol for fetching a list of products.
@protocol BZRProductsProvider <BZREventEmitter>

/// Returns the list of available products for the application.
///
/// The signal sends an \c NSArray of \c BZRProduct and completes. The signal errs if the fetching
/// has failed.
- (RACSignal<BZRProductList *> *)fetchProductList;

@end

NS_ASSUME_NONNULL_END
