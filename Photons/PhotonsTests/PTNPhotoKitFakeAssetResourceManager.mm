// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNPhotoKitFakeAssetResourceManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface NSMapTable (ResourceMap)

/// Creates a map from a strong object that is compared via pointer equality to another strong
/// object.
+ (instancetype)ptn_resourceMap;

@end

@implementation NSMapTable (ResourceMap)

+ (instancetype)ptn_resourceMap {
  return [NSMapTable mapTableWithKeyOptions:NSMapTableStrongMemory |
          NSMapTableObjectPointerPersonality valueOptions:NSMapTableStrongMemory];
}

@end

@interface PTNPhotoKitFakeAssetResourceManager ()

/// Maps asset resource to progress values.
@property (readonly, nonatomic)
    NSMapTable<PHAssetResource *, NSArray<NSNumber *> *> *resourceToProgress;

/// Maps asset resource to image.
@property (readonly, nonatomic) NSMapTable<PHAssetResource *, NSData *> *resourceToData;

/// Maps asset resource to error.
@property (readonly, nonatomic) NSMapTable<PHAssetResource *, NSError *> *resourceToError;

/// Maps request identifier to asset resource.
@property (readonly, nonatomic)
    NSMutableDictionary<NSNumber *, PHAssetResource *> *requestToResource;

/// Set of cancelled request IDs.
@property (readonly, nonatomic) NSMutableSet<PHAssetResource *> *cancelledRequests;

/// Set of issued request IDs.
@property (readonly, nonatomic) NSMutableSet<PHAssetResource *> *issuedRequests;

/// Next request identifier to return.
@property (nonatomic) PHAssetResourceDataRequestID nextRequestIdentifier;

@end

@implementation PTNPhotoKitFakeAssetResourceManager

- (instancetype)init {
  if (self = [super init]) {
    _resourceToProgress = [NSMapTable ptn_resourceMap];
    _resourceToData = [NSMapTable ptn_resourceMap];
    _resourceToError = [NSMapTable ptn_resourceMap];
    _requestToResource = [NSMutableDictionary dictionary];
    _cancelledRequests = [NSMutableSet set];
    _issuedRequests = [NSMutableSet set];
  }
  return self;
}

- (void)serveResource:(PHAssetResource *)resource withProgress:(NSArray<NSNumber *> *)progress
                 data:(NSData *)data {
  @synchronized(self) {
    [self.resourceToProgress setObject:progress forKey:resource];
    [self.resourceToData setObject:data forKey:resource];
  }
}

- (void)serveResource:(PHAssetResource *)resource withProgress:(NSArray<NSNumber *> *)progress
         finallyError:(NSError *)error {
  @synchronized(self) {
    [self.resourceToProgress setObject:progress forKey:resource];
    [self.resourceToError setObject:error forKey:resource];
  }
}

- (BOOL)isRequestCancelledForResource:(PHAssetResource *)resource {
  @synchronized(self) {
    return [self.cancelledRequests containsObject:resource];
  }
}

- (BOOL)isRequestIssuedForResource:(PHAssetResource *)resource {
  @synchronized(self) {
    return [self.issuedRequests containsObject:resource];
  }
}

- (PHAssetResourceDataRequestID)requestDataForAssetResource:(PHAssetResource *)resource
    options:(nullable PHAssetResourceRequestOptions *)options
    dataReceivedHandler:(void (^)(NSData *))handler
    completionHandler:(void (^)(NSError * _Nullable))completionHandler {
  NSArray * _Nullable progresses;
  NSData * _Nullable data;
  @synchronized(self) {
    progresses = [self.resourceToProgress objectForKey:resource];
    data = [self.resourceToData objectForKey:resource];
  }

  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    if (!progresses) {
      completionHandler([NSError errorWithDomain:@"foo" code:1337 userInfo:nil]);
      return;
    }

    if (!progresses.count) {
      handler(data);
    } else {
      NSUInteger location = 0;

      for (NSNumber *progress in progresses) {
        if (options.progressHandler) {
          options.progressHandler(progress.doubleValue);
        }

        NSUInteger length = data.length * progress.doubleValue - location;
        auto range = NSMakeRange(location, length);
        auto partialData = [data subdataWithRange:range];
        handler(partialData);

        location += length;
      };
    }

    if (!data || [self.resourceToError objectForKey:resource]) {
      completionHandler([self.resourceToError objectForKey:resource]);
    } else {
      completionHandler(nil);
    }
  });

  @synchronized(self) {
    ++self.nextRequestIdentifier;
    self.requestToResource[@(self.nextRequestIdentifier)] = resource;
    [self.issuedRequests addObject:resource];
    return self.nextRequestIdentifier;
  }
}

- (void)writeDataForAssetResource:(PHAssetResource __unused *)resource
                           toFile:(NSURL __unused *)fileURL
                          options:(nullable PHAssetResourceRequestOptions __unused *)options
                completionHandler:(void (__unused ^)(NSError * _Nullable))completionHandler {
  LTMethodNotImplemented();
}

- (void)cancelDataRequest:(PHAssetResourceDataRequestID)requestID {
  @synchronized(self) {
    if (self.requestToResource[@(requestID)]) {
      [self.cancelledRequests addObject:self.requestToResource[@(requestID)]];
    }
  }
}

@end

NS_ASSUME_NONNULL_END
