// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNFakeDataCache.h"

#import "PTNCacheResponse.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTNFakeDataCache ()

/// Mapping of \c NSURL to \c PTNCacheResponse for cached responses.
@property (readonly, nonatomic) NSMutableDictionary<NSURL *, PTNCacheResponse *> *responses;

/// Mapping of \c NSURL to \c NSError for responses with registered errors.
@property (readonly, nonatomic) NSMutableDictionary<NSURL *, NSError *> *errors;

@end

@implementation PTNFakeDataCache

- (instancetype)init {
  if (self = [super init]) {
    _responses = [NSMutableDictionary dictionary];
    _errors = [NSMutableDictionary dictionary];
  }
  return self;
}

- (void)registerError:(NSError *)error forURL:(NSURL *)url {
  self.errors[url] = error;
}

#pragma mark -
#pragma mark PTNDataCache
#pragma mark -

- (void)storeInfo:(NSDictionary *)info forURL:(NSURL *)url {
  [self storeData:[NSData data] withInfo:info forURL:url];
}

- (void)storeData:(NSData *)data withInfo:(nullable NSDictionary *)info forURL:(NSURL *)url {
  self.responses[url] = [[PTNCacheResponse alloc] initWithData:data info:info];
}

- (RACSignal *)cachedDataForURL:(NSURL *)url {
  if (self.errors[url]) {
    return [RACSignal error:self.errors[url]];
  }

  return [RACSignal return:self.responses[url]];
}

- (void)clearCache {
  [self.responses removeAllObjects];
}

@end

NS_ASSUME_NONNULL_END
