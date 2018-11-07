// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNCacheFakeNSURLCache.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTNCacheFakeNSURLCache ()

/// Mutable mapping of \c NSURLRequest objects to \c NSCachedURLResponse objects.
typedef NSMutableDictionary<NSURLRequest *, NSCachedURLResponse *> PTNMutableURLCacheStorage;

/// Storage simulation mapping \c NSURLRequest objects to the \c NSCachedURLResponse that was stored
/// for them.
@property (readonly, nonatomic) PTNMutableURLCacheStorage *mutableStorage;

@end

@implementation PTNCacheFakeNSURLCache

- (instancetype)init {
  if (self = [super init]) {
    _mutableStorage = [NSMutableDictionary dictionary];
  }
  return self;
}

- (NSDictionary *)storage {
  return [self.mutableStorage copy];
}

#pragma mark -
#pragma mark NSURLCache
#pragma mark -

+ (NSURLCache *)sharedURLCache {
  LTMethodNotImplemented();
}

+ (void)setSharedURLCache:(NSURLCache __unused *)cache {
  LTMethodNotImplemented();
}

- (nullable NSCachedURLResponse *)cachedResponseForRequest:(NSURLRequest *)request {
  return self.mutableStorage[request];
}

- (void)storeCachedResponse:(NSCachedURLResponse *)cachedResponse
                 forRequest:(NSURLRequest *)request {
  self.mutableStorage[request] = cachedResponse;
}

- (void)removeCachedResponseForRequest:(NSURLRequest *)request {
  self.mutableStorage[request] = nil;
}

- (void)removeAllCachedResponses {
  [self.mutableStorage removeAllObjects];
}

- (void)removeCachedResponsesSinceDate:(NSDate __unused *)date {
  LTMethodNotImplemented();
}

- (NSUInteger)memoryCapacity {
  LTMethodNotImplemented();
}

- (NSUInteger)diskCapacity {
  LTMethodNotImplemented();
}

- (NSUInteger)currentMemoryUsage {
  LTMethodNotImplemented();
}

- (NSUInteger)currentDiskUsage {
  LTMethodNotImplemented();
}

@end

NS_ASSUME_NONNULL_END
