// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "NSURLCache+Photons.h"

#import "NSURL+PTNCache.h"
#import "PTNAlbum.h"
#import "PTNCacheInfo.h"
#import "PTNDataAsset.h"
#import "PTNDataBackedImageAsset.h"
#import "PTNImageResizer.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSURLCache (Photons)

#pragma mark -
#pragma mark PTNDataCache
#pragma mark -

- (void)storeData:(NSData *)data withInfo:(nullable NSDictionary *)info
           forURL:(NSURL *)url {
  LTParameterAssert(!info || [self isPropertyList:info], @"Given info is not a valid "
                    "property list: %@", info);

  [self storeData:data withInfo:info forURL:url withStoragePolicy:NSURLCacheStorageAllowed];
}

- (BOOL)isPropertyList:(id)object {
  return [NSPropertyListSerialization propertyList:object
                                  isValidForFormat:NSPropertyListBinaryFormat_v1_0];
}

- (void)storeInfo:(NSDictionary *)info forURL:(NSURL *)url {
  [self storeData:[NSData data] withInfo:info forURL:url
      withStoragePolicy:NSURLCacheStorageAllowedInMemoryOnly];
}

- (void)storeData:(NSData *)data withInfo:(nullable NSDictionary *)info
           forURL:(NSURL *)url withStoragePolicy:(NSURLCacheStoragePolicy)storagePolicy {
  NSCachedURLResponse *cachedResponse = [self responseFromData:data withUserInfo:info url:url
                                                 storagePolicy:storagePolicy];
  NSURLRequest *request = [self requestFromURL:url];
  [self storeCachedResponse:cachedResponse forRequest:request];
}

- (RACSignal *)cachedDataForURL:(NSURL *)url {
  NSCachedURLResponse *response = [self cachedResponseForRequest:[self requestFromURL:url]];
  if (!response) {
    return [RACSignal return:nil];
  }

  PTNCacheResponse *cachedResponse =
      [[PTNCacheResponse alloc] initWithData:response.data info:response.userInfo];
  return [RACSignal return:cachedResponse];
}

- (void)clearCache {
  [self removeAllCachedResponses];
}

#pragma mark -
#pragma mark Mapping
#pragma mark -

- (NSCachedURLResponse *)responseFromData:(NSData *)data withUserInfo:(nullable NSDictionary *)info
                                      url:(NSURL *)url
                            storagePolicy:(NSURLCacheStoragePolicy)storagePolicy {
  NSURLResponse *internalResponse = [[NSURLResponse alloc] initWithURL:url MIMEType:nil
                                                 expectedContentLength:0
                                                      textEncodingName:nil];

  return [[NSCachedURLResponse alloc] initWithResponse:internalResponse data:data
                                              userInfo:info
                                         storagePolicy:storagePolicy];
}

- (NSURLRequest *)requestFromURL:(NSURL *)url {
  return [[NSURLRequest alloc] initWithURL:url];
}

@end

NS_ASSUME_NONNULL_END
