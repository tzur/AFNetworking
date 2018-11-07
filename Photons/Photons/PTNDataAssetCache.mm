// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNDataAssetCache.h"

#import "PTNAlbum.h"
#import "PTNCacheInfo.h"
#import "PTNCacheProxy.h"
#import "PTNCacheResponse.h"
#import "PTNDataAsset.h"
#import "PTNDataBackedImageAsset.h"
#import "PTNDataCache.h"
#import "PTNDescriptor.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTNDataAssetCache ()

/// Underlying cache.
@property (readonly, nonatomic) id<PTNDataCache> cache;

@end

@implementation PTNDataAssetCache

- (instancetype)initWithCache:(id<PTNDataCache>)cache {
  if (self = [super init]) {
    _cache = cache;
  }
  return self;
}

#pragma mark -
#pragma mark PTNDataAssetCache
#pragma mark -

static NSString const * kCacheInfoKey = @"com.lightricks.Photons.cacheInfo";
static NSString const * kAlbumKey = @"com.lightricks.Photons.album";
static NSString const * kDescriptorKey = @"com.lightricks.Photons.descriptor";

- (void)storeAlbum:(id<PTNAlbum>)album withCacheInfo:(PTNCacheInfo *)cacheInfo forURL:(NSURL *)url {
  NSDictionary *info = @{
    kCacheInfoKey: cacheInfo,
    kAlbumKey: album
  };

  [self.cache storeInfo:info forURL:url];
}

- (RACSignal *)cachedAlbumForURL:(NSURL *)url {
  return [[self.cache cachedDataForURL:url]
      map:^id(PTNCacheResponse<NSData *, NSDictionary *> *response) {
        if (![response.info[kCacheInfoKey] isKindOfClass:[PTNCacheInfo class]] ||
            ![response.info[kAlbumKey] conformsToProtocol:@protocol(PTNAlbum)]) {
          return nil;
        }

        return [[PTNCacheResponse alloc] initWithData:response.info[kAlbumKey]
                                                 info:response.info[kCacheInfoKey]];
      }];
}

- (void)storeDescriptor:(id<PTNDescriptor>)descriptor withCacheInfo:(PTNCacheInfo *)cacheInfo
                 forURL:(NSURL *)url {
  NSDictionary *info = @{
    kCacheInfoKey: cacheInfo,
    kDescriptorKey: descriptor
  };

  [self.cache storeInfo:info forURL:url];
}

- (RACSignal *)cachedDescriptorForURL:(NSURL *)url {
  return [[self.cache cachedDataForURL:url]
      map:^id(PTNCacheResponse<NSData *, NSDictionary *> *response) {
        if (![response.info[kCacheInfoKey] isKindOfClass:[PTNCacheInfo class]] ||
            ![response.info[kDescriptorKey] conformsToProtocol:@protocol(PTNDescriptor)]) {
          return nil;
        }

        return [[PTNCacheResponse alloc] initWithData:response.info[kDescriptorKey]
                                                 info:response.info[kCacheInfoKey]];
      }];
}

- (void)storeImageAsset:(id<PTNDataAsset>)imageAsset withCacheInfo:(PTNCacheInfo *)cacheInfo
                 forURL:(NSURL *)url {
  NSDictionary *info = @{
    kCacheInfoKey: cacheInfo.dictionary
  };

  [[imageAsset fetchData] subscribeNext:^(NSData *data) {
    [self.cache storeData:data withInfo:info forURL:url];
  }];
}

- (RACSignal *)cachedImageAssetForURL:(NSURL *)url
                     resizingStrategy:(id<PTNResizingStrategy>)resizingStrategy {
  return [[self.cache cachedDataForURL:url]
      map:^id(PTNCacheResponse<NSData *, NSDictionary *> *response) {
        if (![response.data length] || !response.info[kCacheInfoKey] ||
            ![response.info[kCacheInfoKey] isKindOfClass:[NSDictionary class]]) {
          return nil;
        }

        PTNCacheInfo *cacheInfo =
            [[PTNCacheInfo alloc] initWithDictionary:response.info[kCacheInfoKey]];
        if (!cacheInfo) {
          return nil;
        }

        PTNDataBackedImageAsset *asset = [[PTNDataBackedImageAsset alloc] initWithData:response.data
            resizingStrategy:resizingStrategy];

        return [[PTNCacheResponse alloc] initWithData:asset info:cacheInfo];
      }];
}

- (void)clearCache {
  [self.cache clearCache];
}

@end

NS_ASSUME_NONNULL_END
