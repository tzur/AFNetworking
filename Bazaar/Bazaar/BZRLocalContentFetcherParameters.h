// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRContentFetcherParameters.h"

NS_ASSUME_NONNULL_BEGIN

/// Additional parameters required for fetching content with \c BZRLocalContentFetcher.
@interface BZRLocalContentFetcherParameters : BZRContentFetcherParameters

/// Local path to the content file.
@property (readonly, nonatomic) NSURL *URL;

@end

NS_ASSUME_NONNULL_END
