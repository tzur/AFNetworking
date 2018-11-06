// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNAlbum.h"
#import "PTNCacheInfo.h"
#import "PTNCacheResponse.h"
#import "PTNDataBackedImageAsset.h"
#import "PTNDescriptor.h"

NS_ASSUME_NONNULL_BEGIN

@protocol PTNDataAsset, PTNDataCache, PTNResizingStrategy;

/// Protocol representing a cache made for the Photons framework, capable of storing and fetching
/// Photons entities with associated information as an \c PTNCacheInfo in a thread safe manner.
/// Storing is made if the size of the data requested for storing is small enough to reasonably fit
/// within the cache. Reasonably fitting within the cache is an implementation specific detail and
/// therefore it's possible to store an object, immediately fetch it back and get a cache miss.
@protocol PTNDataAssetCache <NSObject>

/// Stores \c album and \c cacheInfo under \c url as the key. This method is non blocking.
///
/// @note Storage is taking place in memory. Therefore the album and it's cache information may be
/// unserializable, but are assumed to be immutable.
- (void)storeAlbum:(id<PTNAlbum>)album withCacheInfo:(PTNCacheInfo *)cacheInfo forURL:(NSURL *)url;

/// Retrieves \c PTNAlbum and \c PTNCacheInfo previously stored with \c url. The returned signal
/// will send a single \c PTNCacheResponse and complete if album and its cache information were
/// found for \c url or send a single \c nil and complete if album and its cache information stored
/// for \c url could not be found. An album and its cache information will not be found if they were
/// not stored in the cache or if they were purged by the caching system to make room for other
/// objects. The returned signal will err if an error occurred while fetching the album and its
/// information.
- (RACSignal<PTNCacheResponse<id<PTNAlbum>, PTNCacheInfo *> *> *)cachedAlbumForURL:(NSURL *)url;

/// Stores \c descriptor and \c cacheInfo under \c url as the key. This method is non blocking.
///
/// @note Storage is taking place in memory. Therefore the descriptor and it's cache information may
/// be unserializable, but are assumed to be immutable.
- (void)storeDescriptor:(id<PTNDescriptor>)descriptor withCacheInfo:(PTNCacheInfo *)cacheInfo
                 forURL:(NSURL *)url;

/// Retrieves \c PTNDescriptor and \c PTNCacheInfo previously stored with \c url. The returned
/// signal will send a single \c PTNCacheResponse and complete if descriptor and its cache
/// information were found for \c url or send a single \c nil and complete if descriptor and its
/// cache information stored for \c url could not be found. A descriptor and its cache information
/// will not be found if they were not stored in the cache or if they were purged by the caching
/// system to make room for other objects. The returned signal will err if an error occurred while
/// fetching the descriptor and its information.
- (RACSignal<PTNCacheResponse<id<PTNDescriptor>, PTNCacheInfo *> *> *)
    cachedDescriptorForURL:(NSURL *)url;

/// Stores \c imageAsset and \c cacheInfo under \c url as the key. This method is non blocking.
///
/// @note Storage is taking place in memory or in disk as determined by the underlying caching
/// system.
- (void)storeImageAsset:(id<PTNDataAsset>)imageAsset withCacheInfo:(PTNCacheInfo *)cacheInfo
                 forURL:(NSURL *)url;

/// Retrieves \c PTNDataBackedAsset constructed from \c resizingStrategy and image data previously
/// stored with \c url along with \c PTNCacheInfo also stored for \c url. The returned signal will
/// send a single \c PTNCacheResponse and complete if image data and its cache information were
/// found for \c url or send a single \c nil and complete if image data and its cache information
/// stored for \c url could not be found. Image data and its cache information will not be found if
/// they were not stored in the cache or if they were purged by the caching system to make room for
/// other objects. The returned signal will err if an error occurred while fetching the descriptor
/// and its information.
- (RACSignal<PTNCacheResponse<PTNDataBackedImageAsset *, PTNCacheInfo *> *> *)
    cachedImageAssetForURL:(NSURL *)url resizingStrategy:(id<PTNResizingStrategy>)resizingStrategy;

/// Clears the cache from all stored data.
- (void)clearCache;

@end

/// Implementation of \c PTNDataAssetCache using a \c PTNDataCache as its underlying caching system.
@interface PTNDataAssetCache : NSObject <PTNDataAssetCache>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c cache as underlying caching system.
- (instancetype)initWithCache:(id<PTNDataCache>)cache NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
