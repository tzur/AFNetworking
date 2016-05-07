// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "NSURL+PTNCache.h"

#import <LTKit/NSURL+Query.h>

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
  if (!self.lt_queryDictionary[kCachePolicy]) {
    return [self lt_URLByAppendingQueryDictionary:@{kCachePolicy: cachePolicy.name}];
  }

  NSURLComponents *components = [[NSURLComponents alloc] initWithURL:self
                                             resolvingAgainstBaseURL:NO];

  components.queryItems = [self.lt_queryItems.rac_sequence
      map:^NSURLQueryItem *(NSURLQueryItem *item) {
        if (![item.name isEqualToString:kCachePolicy]) {
          return item;
        }
        return [[NSURLQueryItem alloc] initWithName:kCachePolicy value:cachePolicy.name];
      }].array;

  return components.URL;
}

- (PTNCachePolicy *)ptn_cacheCachePolicy {
  NSString * _Nullable cachePolicyName = self.lt_queryDictionary[kCachePolicy];
  if (!cachePolicyName) {
    return [PTNCachePolicy enumWithValue:PTNCachePolicyDefault];
  }

  return [PTNCachePolicy enumWithName:cachePolicyName];
}

- (instancetype)ptn_cacheURLByStrippingCachePolicy {
  if (!self.lt_queryDictionary[kCachePolicy]) {
    return self;
  }

  NSURLComponents *components = [[NSURLComponents alloc] initWithURL:self
                                             resolvingAgainstBaseURL:NO];

  NSArray *filteredQueryItems = [self.lt_queryItems.rac_sequence
      filter:^BOOL(NSURLQueryItem *item) {
        return ![item.name isEqualToString:kCachePolicy];
      }].array;

  components.queryItems = filteredQueryItems.count ? filteredQueryItems : nil;
  return components.URL;
}

@end

NS_ASSUME_NONNULL_END
