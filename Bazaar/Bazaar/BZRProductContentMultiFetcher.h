// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRProductContentFetcher.h"

NS_ASSUME_NONNULL_BEGIN

/// Provides multiple ways to fetch content for products. This class is initialized with a
/// dictionary that specifies the possible \c BZRProductContentFetcher to fetch with.
/// A given \c BZRProduct should specify which \c BZRProductContentFetcher is requested by
/// providing an key in the dictionary, and the parameters to that content fetcher. These are
/// given in \c BZRProductContentMultiFetcherParameters class.
@interface BZRProductContentMultiFetcher : NSObject <BZRProductContentFetcher>

/// Initializes with the default collection of content fetchers.
- (instancetype)init;

/// Initializes with \c contentFetchers, a dictionary mapping content fetcher's names to actual
/// content fetchers.
- (instancetype)initWithContentFetchers:
    (NSDictionary<NSString *, id<BZRProductContentFetcher>> *)contentFetchers
    NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
