// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNPhotoKitFakeImageManager.h"

@class PTNProgress;

NS_ASSUME_NONNULL_BEGIN

@interface PTNPhotoKitFakeImageManager ()

/// Maps asset identifier to progress values.
@property (strong, nonatomic)
    NSMutableDictionary<NSString *, NSArray<NSNumber *> *> *identifierToProgress;

/// Maps asset identifier to image.
@property (strong, nonatomic) NSMutableDictionary<NSString *, UIImage *> *identifierToImage;

/// Maps asset identifier to \c AVAsset.
@property (strong, nonatomic) NSMutableDictionary<NSString *, AVAsset *> *identifierToAVAsset;

/// Maps asset identifier to audio mix.
@property (strong, nonatomic) NSMutableDictionary<NSString *, AVAudioMix *> *identifierToAudioMix;

/// Maps asset identifier to image data.
@property (strong, nonatomic) NSMutableDictionary<NSString *, NSData *> *identifierToImageData;

/// Maps asset identifier to its UTI.
@property (strong, nonatomic) NSMutableDictionary<NSString *, NSString *> *identifierToDataUTI;

/// Maps asset identifier to orientation.
@property (strong, nonatomic) NSMutableDictionary<NSString *, NSNumber *> *identifierToOrientation;

/// Maps asset identifier to \c AVPlayerItem.
@property (strong, nonatomic)
    NSMutableDictionary<NSString *, AVPlayerItem *> *identifierToPlayerItem;

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
    self.identifierToAVAsset = [NSMutableDictionary dictionary];
    self.identifierToAudioMix = [NSMutableDictionary dictionary];
    self.identifierToImageData = [NSMutableDictionary dictionary];
    self.identifierToDataUTI = [NSMutableDictionary dictionary];
    self.identifierToOrientation = [NSMutableDictionary dictionary];
    self.identifierToPlayerItem = [NSMutableDictionary dictionary];
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
           avasset:(AVAsset *)avasset audioMix:(AVAudioMix *)audioMix {
  NSString *identifier = asset.localIdentifier;

  self.identifierToProgress[identifier] = progress;
  self.identifierToAVAsset[identifier] = avasset;
  self.identifierToAudioMix[identifier] = audioMix;
}

- (void)serveAsset:(PHAsset *)asset withProgress:(NSArray<NSNumber *> *)progress
         imageData:(NSData *)imageData dataUTI:(NSString *)dataUTI
       orientation:(UIImageOrientation)orientation {
  NSString *identifier = asset.localIdentifier;

  self.identifierToProgress[identifier] = progress;
  self.identifierToImageData[identifier] = imageData;
  self.identifierToDataUTI[identifier] = dataUTI;
  self.identifierToOrientation[identifier] = @(orientation);
}

- (void)serveAsset:(PHAsset *)asset withProgress:(NSArray<NSNumber *> *)progress
        playerItem:(AVPlayerItem *)playerItem {
  NSString *identifier = asset.localIdentifier;

  self.identifierToProgress[identifier] = progress;
  self.identifierToPlayerItem[identifier] = playerItem;
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
        NSError *error = (idx == [self.identifierToProgress[identifier] count] - 1) ?
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

- (PHImageRequestID)requestAVAssetForVideo:(PHAsset *)asset options:(PHVideoRequestOptions *)options
                             resultHandler:(PTNPhotoKitImageManagerAVAssetHandler)resultHandler {
  NSString *identifier = asset.localIdentifier;

  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    if (!self.identifierToProgress[identifier]) {
      resultHandler(nil, nil, @{
        PHImageErrorKey: [NSError errorWithDomain:@"foo" code:1337 userInfo:nil]
      });
      return;
    }

    if (options.progressHandler) {
      [self.identifierToProgress[identifier] enumerateObjectsUsingBlock:^(NSNumber *progress,
                                                                          NSUInteger idx,
                                                                          BOOL *stop) {
        NSError *error = (idx == [self.identifierToProgress[identifier] count] - 1) ?
            self.identifierToProgressError[identifier] : nil;
        options.progressHandler(progress.doubleValue, error, stop, nil);
      }];
    }

    if (self.identifierToError[identifier]) {
      resultHandler(nil, nil, @{
        PHImageErrorKey: self.identifierToError[identifier]
      });
    } else if (self.identifierToProgressError[identifier]) {
      resultHandler(nil, nil, @{
        PHImageErrorKey: self.identifierToProgressError[identifier]
      });
    } else if (self.identifierToAVAsset[identifier]) {
      resultHandler(self.identifierToAVAsset[identifier], self.identifierToAudioMix[identifier],
                    nil);
    }
  });

  ++self.nextRequestIdentifier;
  self.requestToIdentifier[@(self.nextRequestIdentifier)] = identifier;
  [self.issuedRequests addObject:identifier];

  return self.nextRequestIdentifier;
}

- (PHImageRequestID)requestImageDataForAsset:(PHAsset *)asset
    options:(PHImageRequestOptions *)options
    resultHandler:(PTNPhotoKitImageManagerImageDataHandler)resultHandler {
  NSString *identifier = asset.localIdentifier;

  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    if (!self.identifierToProgress[identifier]) {
      resultHandler(nil, nil, UIImageOrientationUp, @{
        PHImageErrorKey: [NSError errorWithDomain:@"foo" code:1337 userInfo:nil]
      });
      return;
    }

    if (options.progressHandler) {
      [self.identifierToProgress[identifier] enumerateObjectsUsingBlock:^(NSNumber *progress,
                                                                          NSUInteger idx,
                                                                          BOOL *stop) {
        NSError *error = (idx == [self.identifierToProgress[identifier] count] - 1) ?
            self.identifierToProgressError[identifier] : nil;
        options.progressHandler(progress.doubleValue, error, stop, nil);
      }];
    }

    if (self.identifierToError[identifier]) {
      resultHandler(nil, nil, UIImageOrientationUp, @{
        PHImageErrorKey: self.identifierToError[identifier]
      });
    } else if (self.identifierToProgressError[identifier]) {
      resultHandler(nil, nil, UIImageOrientationUp, @{
        PHImageErrorKey: self.identifierToProgressError[identifier]
      });
    } else if (self.identifierToImageData[identifier]) {
      resultHandler(self.identifierToImageData[identifier], self.identifierToDataUTI[identifier],
                    self.identifierToOrientation[identifier].intValue, nil);
    }
  });

  ++self.nextRequestIdentifier;
  self.requestToIdentifier[@(self.nextRequestIdentifier)] = identifier;
  [self.issuedRequests addObject:identifier];

  return self.nextRequestIdentifier;
}

- (PHImageRequestID)requestPlayerItemForVideo:(PHAsset *)asset
    options:(PHVideoRequestOptions *)options
    resultHandler:(PTNPhotoKitImageManagerAVPreviewHandler)resultHandler {
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
        NSError *error = (idx == [self.identifierToProgress[identifier] count] - 1) ?
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
    } else if (self.identifierToPlayerItem[identifier]) {
      resultHandler(self.identifierToPlayerItem[identifier], nil);
    }
  });

  ++self.nextRequestIdentifier;
  self.requestToIdentifier[@(self.nextRequestIdentifier)] = identifier;
  [self.issuedRequests addObject:identifier];

  return self.nextRequestIdentifier;
}

@end

NS_ASSUME_NONNULL_END
