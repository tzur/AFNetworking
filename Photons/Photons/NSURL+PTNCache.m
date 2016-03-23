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
  /// Use cache if exists, no matter how out of date without validation.
  PTNCachePolicyReturnCacheDataElseLoad
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

@end

NS_ASSUME_NONNULL_END
