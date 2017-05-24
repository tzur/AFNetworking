// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "BZRProductContentFetcher.h"

NS_ASSUME_NONNULL_BEGIN

/// Dictionary that maps content fetcher name to content fetcher class.
typedef NSDictionary<NSString *, id<BZRProductContentFetcher>> BZRContentFetchersDictionary;

/// Fetcher that allows fetching using several different underlying fetchers. The content fetcher is
/// chosen by checking \c product.contentFetcherParameters.type.
@interface BZRCompositeContentFetcher : NSObject <BZRProductContentFetcher>

/// Initializes with the default collection of content fetchers.
- (instancetype)init;

/// Initializes with \c contentFetchers, a dictionary that maps content fetcher name to content
/// fetcher class.
- (instancetype)initWithContentFetchers:(BZRContentFetchersDictionary *)contentFetchers
    NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
