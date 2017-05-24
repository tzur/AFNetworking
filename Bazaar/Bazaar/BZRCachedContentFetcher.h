// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRProductContentFetcher.h"

NS_ASSUME_NONNULL_BEGIN

/// Fetcher used to fetch products content only if the content is not available on the device
/// already. If it is available, the resource is sent on the signal.
@interface BZRCachedContentFetcher : NSObject <BZRProductContentFetcher>

/// Initializes with \c underlyingContentFetcher set to
/// \c [[BZRCompositeContentFetcher alloc] init].
- (instancetype)init;

/// Initializes with \c underlyingContentFetcher that is used to fetch the content.
- (instancetype)initWithUnderlyingContentFetcher:
    (id<BZRProductContentFetcher>)underlyingContentFetcher NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
