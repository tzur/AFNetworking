// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNPhotoKitFakeImageManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTNPhotoKitFakeImageManager ()

/// Maps asset identifier to progress values.
@property (strong, nonatomic) NSMutableDictionary *identifierToProgress;

/// Maps asset identifier to image.
@property (strong, nonatomic) NSMutableDictionary *identifierToImage;

/// Maps asset identifier to error.
@property (strong, nonatomic) NSMutableDictionary *identifierToError;

/// Maps asset identifier to progress error.
@property (strong, nonatomic) NSMutableDictionary *identifierToProgressError;

/// Maps request identifier to asset identifier.
@property (strong, nonatomic) NSMutableDictionary *requestToIdentifier;

/// Set of cancelled request IDs.
@property (strong, nonatomic) NSMutableSet *cancelledRequests;

/// Set of issued request IDs.
@property (strong, nonatomic) NSMutableSet *issuedRequests;

/// Next request identifier to return.
@property (nonatomic) PHImageRequestID nextRequestIdentifier;

@end

@implementation PTNPhotoKitFakeImageManager

- (instancetype)init {
  if (self = [super init]) {
    self.identifierToProgress = [NSMutableDictionary dictionary];
    self.identifierToImage = [NSMutableDictionary dictionary];
    self.identifierToError = [NSMutableDictionary dictionary];
    self.identifierToProgressError = [NSMutableDictionary dictionary];
    self.requestToIdentifier = [NSMutableDictionary dictionary];
    self.cancelledRequests = [NSMutableSet set];
    self.issuedRequests = [NSMutableSet set];
  }
  return self;
}

- (void)serveAsset:(PHAsset *)asset withProgress:(NSArray<NSNumber *> *)progress
             image:(UIImage *)image {
  NSString *identifier = asset.localIdentifier;

  self.identifierToProgress[identifier] = progress;
  self.identifierToImage[identifier] = image;

}

- (void)serveAsset:(PHAsset *)asset withProgress:(NSArray<NSNumber *> *)progress
      finallyError:(NSError *)error {
  NSString *identifier = asset.localIdentifier;

  self.identifierToProgress[identifier] = progress;
  self.identifierToError[identifier] = error;
}

- (void)serveAsset:(PHAsset *)asset withProgress:(NSArray<NSNumber *> *)progress
   errorInProgress:(NSError *)error {
  NSString *identifier = asset.localIdentifier;

  self.identifierToProgress[identifier] = progress;
  self.identifierToProgressError[identifier] = error;
}

- (BOOL)isRequestCancelledForAsset:(PHAsset *)asset {
  return [self.cancelledRequests containsObject:asset.localIdentifier];
}

- (BOOL)isRequestIssuedForAsset:(PHAsset *)asset {
  return [self.issuedRequests containsObject:asset.localIdentifier];
}

- (PHImageRequestID)requestImageForAsset:(PHAsset *)asset targetSize:(CGSize __unused)targetSize
                             contentMode:(PHImageContentMode __unused)contentMode
                                 options:(PHImageRequestOptions *)options
                           resultHandler:(PTNPhotoKitImageManagerHandler)resultHandler {
  NSString *identifier = asset.localIdentifier;

  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    if (!self.identifierToProgress[identifier]) {
      resultHandler(nil, @{
        PHImageErrorKey: [NSError errorWithDomain:@"foo" code:1337 userInfo:nil]
      });
      return;
    }

    if (options.progressHandler) {
      [self.identifierToProgress[identifier] enumerateObjectsUsingBlock:^(NSNumber *progress,
                                                                          NSUInteger idx,
                                                                          BOOL *stop) {
        NSError *error = idx == [self.identifierToProgress[identifier] count] - 1 ?
            self.identifierToProgressError[identifier] : nil;
        options.progressHandler(progress.doubleValue, error, stop, nil);
      }];
    }

    if (self.identifierToError[identifier]) {
      resultHandler(nil, @{
        PHImageErrorKey: self.identifierToError[identifier]
      });
    } else if (self.identifierToProgressError[identifier]) {
      resultHandler(nil, @{
        PHImageErrorKey: self.identifierToProgressError[identifier]
      });
    } else if (self.identifierToImage[identifier]) {
      resultHandler(self.identifierToImage[identifier], nil);
    }
  });

  ++self.nextRequestIdentifier;
  self.requestToIdentifier[@(self.nextRequestIdentifier)] = identifier;
  [self.issuedRequests addObject:identifier];

  return self.nextRequestIdentifier;
}

- (void)cancelImageRequest:(PHImageRequestID)requestID {
  if (self.requestToIdentifier[@(requestID)]) {
    [self.cancelledRequests addObject:self.requestToIdentifier[@(requestID)]];
  }
}

@end

NS_ASSUME_NONNULL_END
