// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "BZRContentFetcherParameters.h"
#import "BZRProductContentFetcher.h"

NS_ASSUME_NONNULL_BEGIN

/// Dummy concrete implementation of \c BZRProductContentFetcher used for testing.
@interface BZRDummyContentFetcher : NSObject <BZRProductContentFetcher>
@end

/// Dummy concrete implementation of \c BZRContentFetcherParameters used for testing.
@interface BZRDummyContentFetcherParameters : BZRContentFetcherParameters

/// Initializes with value to be passed to content fetcher.
- (instancetype)initWithValue:(NSString *)value;

/// Value to be passed to content fetcher.
@property (readonly, nonatomic) NSString *value;

@end

NS_ASSUME_NONNULL_END
