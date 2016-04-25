// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNDataCache.h"

NS_ASSUME_NONNULL_BEGIN

@class PTNCacheResponse;

/// Fake \c PTNDataCache implementation over \c NSDictionary used for testing. Cached data will be
/// stored and returned as protocol declares. Simulating errors is possible through the
/// \c -registerError:forURL: method.
@interface PTNFakeDataCache : NSObject <PTNDataCache>

/// Registers \c error to be returned by the returned signal when requesting cached data for \c url.
/// This will override any responses previously cached for \c url.
- (void)registerError:(NSError *)error forURL:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END
