// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "BZRProductContentFetcher.h"

NS_ASSUME_NONNULL_BEGIN

/// Decorator fetcher that retries to fetch the content upon failure of the underlying fetcher,
/// using an exponential backoff algorithm.
@interface BZRRetryContentFetcher : NSObject <BZRProductContentFetcher>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c underlyingContentFetcher that is used to fetch the content, with
/// \c numberOfRetries set to \c 4 and \c initialDelay \c set to \c 5.
- (instancetype)initWithUnderlyingContentFetcher:
    (id<BZRProductContentFetcher>)underlyingContentFetcher;

/// Initializes with \c underlyingContentFetcher that is used to fetch the content, with \c
/// that specifies the number of additional retries after the first fetching failure.
/// \c initialDelay specifies the delay between the first and second tries in seconds.
- (instancetype)initWithUnderlyingContentFetcher:
    (id<BZRProductContentFetcher>)underlyingContentFetcher
    numberOfRetries:(NSUInteger)numberOfRetries initialDelay:(NSTimeInterval)initialDelay
    NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
