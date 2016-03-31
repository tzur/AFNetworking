// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

NS_ASSUME_NONNULL_BEGIN

/// Possible caching policies to enforce when fetching assets.
LTEnumDeclare(NSUInteger, PTNCachePolicy,
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

/// Category over \c NSURL that injects an additional query field representing the cache policy used
/// by the caching system. This URL has no specific scheme and is supposed to be used on top of an
/// existing Photons source URL.
@interface NSURL (PTNCache)

/// Returns the receiver with \c cachePolicy as an additional query field. If the receiver already
/// has a cache policy query field it will be overwritten by \c cachePolicy.
- (instancetype)ptn_cacheURLWithCachePolicy:(PTNCachePolicy *)cachePolicy;

/// Caching policy to use when fetching objects associated with this URL. If this URL has no cache
/// policy set, \c PTNCachePolicyDefault will be returned.
@property (readonly, nonatomic) PTNCachePolicy *ptn_cacheCachePolicy;

@end

NS_ASSUME_NONNULL_END
