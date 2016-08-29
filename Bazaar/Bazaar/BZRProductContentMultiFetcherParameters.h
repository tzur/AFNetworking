// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRContentFetcherParameters.h"

NS_ASSUME_NONNULL_BEGIN

/// Parameters for \c BZRProductContentMultiFetcher containing information information of which
/// underlying content fetcher to use and its parameters.
@interface BZRProductContentMultiFetcherParameters : BZRContentFetcherParameters

/// Key to an entry of a content fetcher in the collection of content fetchers of
/// \c BZRProductContentMultiFetcher class.
@property (readonly, nonatomic) NSString *contentFetcherName;

/// Parameters needed for the contentFetcher specified by \c contentFetcherName. Must be of the
/// correct type as expected by the fetcher specified by \c contentFetcherName.
@property (readonly, nonatomic, nullable) BZRContentFetcherParameters *
    parametersForContentFetcher;

@end

NS_ASSUME_NONNULL_END
