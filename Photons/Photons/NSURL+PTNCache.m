// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "NSURL+PTNCache.h"

#import "NSURL+Photons.h"

NS_ASSUME_NONNULL_BEGIN

/// Possible caching policies to enforce when fetching assets.
LTEnumImplement(NSUInteger, PTNCachePolicy,
  /// Use cache if fresh or validated otherwise use origin-server's response.
  PTNCachePolicyDefault,
  /// Skip cached version and always use origin-server's response.
  PTNCachePolicyReloadIgnoringLocalCacheData,
  /// Use cache if exists, no matter how out of date, and without validation.
  PTNCachePolicyReturnCacheDataElseLoad,
  /// Use cache if exists, no matter how out of date, and without validation; followed by an updated
  /// version if the cached version is invalidated.
  PTNCachePolicyReturnCacheDataThenLoad
);

@implementation NSURL (PTNCache)

static NSString * const kCachePolicy = @"cachepolicy";

- (instancetype)ptn_cacheURLWithCachePolicy:(PTNCachePolicy *)cachePolicy {
  NSMutableDictionary *query = [self.ptn_queryDictionary mutableCopy];
  query[kCachePolicy] = cachePolicy.name;

  NSURLComponents *components = [[NSURLComponents alloc] initWithURL:self
                                             resolvingAgainstBaseURL:NO];
  components.queryItems = [NSURL ptn_queryWithDictionary:query];
  return components.URL;
}

- (PTNCachePolicy *)ptn_cacheCachePolicy {
  NSString * _Nullable cachePolicyName = self.ptn_queryDictionary[kCachePolicy];
  if (!cachePolicyName) {
    return [PTNCachePolicy enumWithValue:PTNCachePolicyDefault];
  }

  return [PTNCachePolicy enumWithName:cachePolicyName];
}

- (instancetype)ptn_cacheURLByStrippingCachePolicy {
  NSMutableDictionary *query = [self.ptn_queryDictionary mutableCopy];
  if (!query[kCachePolicy]) {
    return self;
  }

  NSURLComponents *components = [[NSURLComponents alloc] initWithURL:self
                                             resolvingAgainstBaseURL:NO];
  [query removeObjectForKey:kCachePolicy];
  NSArray *queryItems = [NSURL ptn_queryWithDictionary:query];
  components.queryItems = queryItems.count ? queryItems : nil;

  return components.URL;
}

@end

NS_ASSUME_NONNULL_END
