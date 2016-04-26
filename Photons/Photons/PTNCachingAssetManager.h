// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNAssetManager.h"

NS_ASSUME_NONNULL_BEGIN

@protocol PTNCacheAwareAssetManager, PTNDataAssetCache;

/// Asset manager backed by and underlying asset manager and a cache, performing transparent caching
/// of images, assets and albums that support caching. Caching logic is inspired mainly on the HTTP
/// 1.1 RFC ( RFC 2616 - https://www.ietf.org/rfc/rfc2616.txt ). Thus the main requirement is for it
/// to be transparent to both the user and underlying asset managers that do not support caching.
///
/// The following terms will be used to illustrate the caching mechanism -
///   origin server - The underlying asset manager that supplies first hand responses.
///   first hand response - A response is first-hand if it comes directly and without unnecessary
///     delay from the origin server.
///   cache - A program's local store of response messages and the subsystem that controls its
///     message storage, retrieval, and deletion.
///   expiration time - The time at which the origin server intends that an entity should no longer
///     be returned by a cache without further validation.
///   fresh - A response is fresh if its expiration time has not yet arrived.
///   stale - A response is stale if its expiration time has passed.
///
/// The caching flow begins in the URL used to fetch an album or an asset. This URL can have an
/// additional query field representing the caching policy represented by a \c PTNCachePolicy object
/// with which to fetch the album or asset. This policy is intended for the
/// \c PTNCachingAssetManager and is ignored by other asset managers. When fetching an image, no URL
/// is provided, so the caching policy of images is determind by extracting the given
/// \c PTNDescriptor's \c ptn_identifier, and in turn querying the identifier's caching policy. i.e.
/// if fetching of an image without the default caching policy is required, it should be done with a
/// \c PTNDescriptor that will return a \c ptn_identifier with an embedded caching policy.
///
/// The caching asset manager then proceeds to fetch assets in the following manner:
/// 1. The internal cache is queried to check if a cached response exists for the supplied \c NSURL
/// or \c PTNDescriptor, \c PTNResizingStrategy. If no such response exists the manager returns a
/// first hand response with an injected side effect of caching it for future fetches, provided it's
/// a \c PTNCacheProxy object wrapping the original and contains \c PTNCacheInfo. Responses that
/// aren't \c PTNCacheProxy objects and therefore without \c PTNCacheInfo are assumed to not support
/// caching and are ignored by the caching system.
///
/// 2. If a cached response exists, it's checked for valid freshness according to the supplied cache
/// policy. In the default caching policy this means that the expiration time of the response is
/// compared to the current time, and if the response has yet to expire, it is deemed fresh. Note
/// that under some caching policies, the expiration time is ignored. Fresh responses are returned
/// to the caller.
///
/// 3. Stale responses are validated by the underlying asset manager. Validation uses the designated
/// methods of \c PTNCacheAwareAssetManager and it is up to the underlying asset manager to
/// determine whether the asset with the given URL is still fresh or not. To assist with validation,
/// if an entity tag was given with the original, now cached, response, it is sent again to the
/// validation method. The underlying manager can use this information to identify the cached
/// version held by the caching asset manager when deciding on its freshness. If the response is
/// validated, and deemed unchanged the cached object will be used. Otherwise a first hand response
/// will be retuned with an injected side effect of caching it for future fetches. Validated
/// responses are re-cached as well, with their exipration time reset.
///
/// @see NSURL+PTNCache.h
@interface PTNCachingAssetManager : NSObject <PTNAssetManager>

/// Initializes with \c assetManager as the underlying manager to use as the origin server and
/// \c cache as the cache.
- (instancetype)initWithAssetManager:(id<PTNCacheAwareAssetManager>)assetManager
                               cache:(id<PTNDataAssetCache>)cache;

@end

NS_ASSUME_NONNULL_END
