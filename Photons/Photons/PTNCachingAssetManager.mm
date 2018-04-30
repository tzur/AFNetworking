// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNCachingAssetManager.h"

#import "NSURL+PTNCache.h"
#import "NSURL+PTNResizingStrategy.h"
#import "NSURLCache+Photons.h"
#import "PTNAlbum.h"
#import "PTNAlbumChangeset.h"
#import "PTNCacheAwareAssetManager.h"
#import "PTNCacheInfo.h"
#import "PTNCacheProxy.h"
#import "PTNCacheResponse.h"
#import "PTNDataAssetCache.h"
#import "PTNDataCache.h"
#import "PTNDescriptor.h"
#import "PTNImageAsset.h"
#import "PTNProgress.h"

NS_ASSUME_NONNULL_BEGIN

static BOOL PTNIsCacheEqual(id _Nullable lhs, id _Nullable rhs) {
  return [lhs isEqual:rhs] ||
      ([lhs isKindOfClass:[PTNCacheProxy class]] &&
      [((PTNCacheProxy *)lhs).underlyingObject isEqual:rhs]) ||
      ([rhs isKindOfClass:[PTNCacheProxy class]] &&
      [((PTNCacheProxy *)rhs).underlyingObject isEqual:lhs]);
}

@interface PTNCachingAssetManager ()

/// Caching system.
@property (readonly, nonatomic) id<PTNDataAssetCache> cache;

/// Underlying asset manager.
@property (readonly, nonatomic) id<PTNCacheAwareAssetManager> assetManager;

@end

@implementation PTNCachingAssetManager

- (instancetype)initWithAssetManager:(id<PTNCacheAwareAssetManager>)assetManager
                      memoryCapacity:(NSUInteger)memoryCapacity
                        diskCapacity:(NSUInteger)diskCapacity {
  auto cache = [[NSURLCache alloc] initWithMemoryCapacity:memoryCapacity diskCapacity:diskCapacity
                                                 diskPath:nil];
  return [self initWithAssetManager:assetManager
                              cache:[[PTNDataAssetCache alloc] initWithCache:cache]];
}

- (instancetype)initWithAssetManager:(id<PTNCacheAwareAssetManager>)assetManager
                               cache:(id<PTNDataAssetCache>)cache {
  if (self = [super init]) {
    _assetManager = assetManager;
    _cache = cache;
  }
  return self;
}

#pragma mark -
#pragma mark Album fetching
#pragma mark -

/// Block mapping a value, used to convert minimal cached data to the format expected by the
/// \c PTNAssetManager protocol. E.g. converting a cached \c PTNAlbum to a
/// \c PTNAlbumChangeset wrapping it.
typedef id (^PTNCachedValueConversionBlock)(id value);

/// Block caching a value, used to strip any redundant data from it and store it in the cache.
typedef void (^PTNValueCachingBlock)(id value);

/// Block validating a previous response by a given \c entityTag, used to query whether a cached
/// response with \c entityTag is still fresh. The returned signal should send a single boxed
/// boolean value and complete.
typedef RACSignal<NSNumber *> *(^PTNValidationBlock)(NSString *entityTag);

- (RACSignal *)fetchAlbumWithURL:(NSURL *)url {
  return [[[self fetchThroughCache:[self.cache cachedAlbumForURL:url]
      originFetch:[self.assetManager fetchAlbumWithURL:url] cachePolicy:url.ptn_cacheCachePolicy
      validate:^RACSignal *(NSString *etag) {
        return [self.assetManager validateAlbumWithURL:url entityTag:etag];
      }
      mapCachedResult:^id(id<PTNAlbum> album) {
        return [PTNAlbumChangeset changesetWithAfterAlbum:album];
      }
      storeResult:^(PTNAlbumChangeset *changeset) {
        if (![changeset.afterAlbum isKindOfClass:[PTNCacheProxy class]]) {
          return;
        }

        PTNCacheProxy<id<PTNAlbum>> *proxyAlbum = (PTNCacheProxy *)changeset.afterAlbum;
        if (![proxyAlbum conformsToProtocol:@protocol(PTNAlbum)]) {
          return;
        }

        [self.cache storeAlbum:proxyAlbum.underlyingObject withCacheInfo:proxyAlbum.cacheInfo
                        forURL:url];
      }]
      scanWithStart:nil reduce:^id(PTNAlbumChangeset *running, PTNAlbumChangeset *next) {
        if ((running.beforeAlbum == next.beforeAlbum ||
            PTNIsCacheEqual(running.beforeAlbum, next.beforeAlbum)) &&
            PTNIsCacheEqual(running.afterAlbum, next.afterAlbum) &&
            !next.assetChanges && !next.subalbumChanges) {
          return running;
        }
        return next;
      }]
      distinctUntilChanged];
}

#pragma mark -
#pragma mark Asset fetching
#pragma mark -

- (RACSignal *)fetchDescriptorWithURL:(NSURL *)url {
  return [[[self fetchThroughCache:[self.cache cachedDescriptorForURL:url]
      originFetch:[self.assetManager fetchDescriptorWithURL:url]
      cachePolicy:url.ptn_cacheCachePolicy
      validate:^RACSignal *(NSString * _Nonnull entityTag) {
        return [self.assetManager validateDescriptorWithURL:url entityTag:entityTag];
      }
      mapCachedResult:^id(id<PTNDescriptor> descriptor) {
        return descriptor;
      }
      storeResult:^(id<PTNDescriptor> descriptor) {
        if (![descriptor isKindOfClass:[PTNCacheProxy class]]) {
          return;
        }

        PTNCacheProxy<id<PTNDescriptor>> *proxyDescriptor = (PTNCacheProxy *)descriptor;
        if (![proxyDescriptor conformsToProtocol:@protocol(PTNDescriptor)]) {
          return;
        }

        [self.cache storeDescriptor:proxyDescriptor.underlyingObject
                      withCacheInfo:proxyDescriptor.cacheInfo forURL:url];
      }]
      scanWithStart:nil reduce:^id(id running, id next) {
        if (PTNIsCacheEqual(running, next)) {
          return running;
        }
        return next;
      }]
      distinctUntilChanged];
}

#pragma mark -
#pragma mark Image fetching
#pragma mark -

- (RACSignal *)fetchImageWithDescriptor:(id<PTNDescriptor>)descriptor
                       resizingStrategy:(id<PTNResizingStrategy>)resizingStrategy
                                options:(PTNImageFetchOptions *)options {
  NSURL *url = [self urlForDescriptor:descriptor resizingStrategy:resizingStrategy options:options];
  RACSignal *cacheFetch = [self.cache cachedImageAssetForURL:url
                                            resizingStrategy:resizingStrategy];
  RACSignal *originFetch = [self.assetManager fetchImageWithDescriptor:descriptor
                                                      resizingStrategy:resizingStrategy
                                                               options:options];

  return [[[self fetchThroughCache:cacheFetch originFetch:originFetch
      cachePolicy:descriptor.ptn_identifier.ptn_cacheCachePolicy
      validate:^RACSignal *(NSString *etag) {
        return [self.assetManager validateImageWithDescriptor:descriptor
                                             resizingStrategy:resizingStrategy options:options
                                                    entityTag:etag];
      }
      mapCachedResult:^id(id<PTNDataAsset> result) {
        return [[PTNProgress alloc] initWithResult:result];
      }
      storeResult:^(PTNProgress *progress) {
        if (![progress.result isKindOfClass:[PTNCacheProxy class]]) {
          return;
        }

        PTNCacheProxy<id<PTNDataAsset>> *proxyImageAsset = (PTNCacheProxy *)progress.result;
        if (![proxyImageAsset conformsToProtocol:@protocol(PTNDataAsset)]) {
          return;
        }

        [self.cache storeImageAsset:proxyImageAsset.underlyingObject
                      withCacheInfo:proxyImageAsset.cacheInfo
                             forURL:url];
      }]
      scanWithStart:nil reduce:^id(PTNProgress *running, PTNProgress *next) {
        if (running.result && PTNIsCacheEqual(running.result, next.result)) {
          return running;
        }
        return next;
      }]
      distinctUntilChanged];;
}

#pragma mark -
#pragma mark Audiovisual fetching
#pragma mark -

- (RACSignal *)fetchAVAssetWithDescriptor:(id<PTNDescriptor>)descriptor
                                  options:(PTNAVAssetFetchOptions *)options {
  return [self.assetManager fetchAVAssetWithDescriptor:descriptor options:options];
}

#pragma mark -
#pragma mark Data fetching
#pragma mark -

- (RACSignal *)fetchImageDataWithDescriptor:(id<PTNDescriptor>)descriptor {
  return [self.assetManager fetchImageDataWithDescriptor:descriptor];
}

#pragma mark -
#pragma mark AV preview fetching
#pragma mark -

- (RACSignal *)fetchAVPreviewWithDescriptor:(id<PTNDescriptor>)descriptor
                                    options:(PTNAVAssetFetchOptions *)options {
  return [self.assetManager fetchAVPreviewWithDescriptor:descriptor options:options];
}

#pragma mark -
#pragma mark AV data fetching
#pragma mark -

- (RACSignal<PTNProgress<id<PTNAVDataAsset>> *>*)
    fetchAVDataWithDescriptor:(id<PTNDescriptor>)descriptor {
  return [self.assetManager fetchAVDataWithDescriptor:descriptor];
}

#pragma mark -
#pragma mark Caching
#pragma mark -

- (NSURL *)urlForDescriptor:(id<PTNDescriptor>)descriptor
           resizingStrategy:(id<PTNResizingStrategy>)resizingStrategy
                    options:(PTNImageFetchOptions *)options {
  NSURL *cannonicURL = [self.assetManager canonicalURLForDescriptor:descriptor
                                                   resizingStrategy:resizingStrategy
                                                            options:options];
  return cannonicURL ?: [descriptor.ptn_identifier ptn_URLWithResizingStrategy:resizingStrategy];
}

// Plug-in method applying shared cache logic:
//   - Checks the cache for a stored result using given \c cacheFetch. If no response is found,
//     returns \c originFetch with a \c storeResult side effect.
//   - Checks the cached response's freshness based on \c cachePolicy. If fresh, the cached
//     response is returned.
//   - Validates whether the stale response is still valid using \c validate. If valid, the cached
//     resonse's age is refreshed and its returned, caching it using \c storeResult.
//   - If all else fails, return \c originFetch and cache it using \c storeResult.
//
// \c cacheFetch is a signal returning the cached response or \c nil if no cached response is
// available, \c originFetch is a signal sending the first hand response from the origin server.
// \c mapCachedResult is used to convert minimal cached data to what's expected from the
// corresponding method to return. E.g. Wrapping a \c PTNImageAsset with a \c PTNProgress object
// wrapping it.
- (RACSignal *)fetchThroughCache:(RACSignal<PTNCacheResponse *> *)cacheFetch
                     originFetch:(RACSignal *)originFetch
                     cachePolicy:(PTNCachePolicy *)cachePolicy
                        validate:(PTNValidationBlock)validate
                 mapCachedResult:(PTNCachedValueConversionBlock)mapCachedResult
                     storeResult:(PTNValueCachingBlock)storeResult {
  return [[cacheFetch
      catch:^RACSignal *(NSError *error) {
        LogError(@"PTNCachingAssetManager cache fetch error: %@", error);
        return [RACSignal return:nil];
      }]
      flattenMap:^id(PTNCacheResponse<NSObject *, PTNCacheInfo *> *response) {
        // Cache miss, return origin.
        if (!response.data) {
          return [originFetch doNext:storeResult];
        }

        // Cache hit, check freshness.
        if ([self shouldUseCache:response.info policy:cachePolicy] &&
            ![cachePolicy isEqual:$(PTNCachePolicyReturnCacheDataThenLoad)]) {
          return [RACSignal return:mapCachedResult(response.data)];
        }

        // Stale or needs load, validate and load if invalid.
        RACSignal *validationSignal = [validate(response.info.entityTag)
            catch:^RACSignal *(NSError *error) {
              LogError(@"PTNCachingAssetManager Cache validation error: %@", error);
              return [RACSignal return:@NO];
            }];

        RACSignal *loadAndStore = [[RACSignal
            if:validationSignal
            then:[self refreshedResultFromCacheResponse:response mapCachedResult:mapCachedResult]
            else:originFetch]
            doNext:storeResult];

        if ([self shouldUseCache:response.info policy:cachePolicy]) {
          return [[RACSignal return:mapCachedResult(response.data)] concat:loadAndStore];
        }

        return loadAndStore;
      }];
}

- (BOOL)shouldUseCache:(nullable PTNCacheInfo *)info policy:(PTNCachePolicy *)policy {
  switch (policy.value) {
    case PTNCachePolicyDefault:
      return [info isFreshComparedTo:[NSDate date]];
    case PTNCachePolicyReloadIgnoringLocalCacheData:
      return NO;
    case PTNCachePolicyReturnCacheDataElseLoad:
    case PTNCachePolicyReturnCacheDataThenLoad:
      return YES;
  }
}

- (RACSignal *)refreshedResultFromCacheResponse:(PTNCacheResponse *)response
                                mapCachedResult:(PTNCachedValueConversionBlock)mapCachedResult {
  return [[RACSignal return:response] map:^id(PTNCacheResponse *cacheResponse) {
    PTNCacheProxy *refreshedResult =
        [[PTNCacheProxy alloc] initWithUnderlyingObject:cacheResponse.data
                                              cacheInfo:[cacheResponse.info refreshedCacheInfo]];
    return mapCachedResult(refreshedResult);
  }];
}

@end

NS_ASSUME_NONNULL_END
