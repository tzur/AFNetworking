// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNPhotoKitDeferringImageManager.h"

#import <Photos/Photos.h>

#import "NSErrorCodes+Photons.h"
#import "PTNAuthorizationStatus.h"
#import "PTNPhotoKitAuthorizationManager.h"
#import "PTNPhotoKitAuthorizer.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTNPhotoKitDeferringImageManager ()

/// Authorizer used to validate authorization.
@property (readonly, nonatomic) id<PTNAuthorizationManager> authorizationManager;

/// Block used to create deferred image manager instance.
@property (copy, nonatomic) PTNPhotoKitImageManagerBlock deferredImageManager;

/// Underlying instance of \c PHImageManager used for fetching and canceling of image assets.
@property (readonly, nonatomic) PHImageManager *imageManager;

@end

@implementation PTNPhotoKitDeferringImageManager

- (instancetype)initWithAuthorizationManager:(id<PTNAuthorizationManager>)authorizationManager
              deferredImageManager:(PTNPhotoKitImageManagerBlock)deferredImageManager {
  LTParameterAssert(deferredImageManager, @"deferredImageManager block cannot be nil");
  if (self = [super init]) {
    _authorizationManager = authorizationManager;
    _deferredImageManager = deferredImageManager;
  }
  return self;
}

- (instancetype)initWithAuthorizationManager:(id<PTNAuthorizationManager>)authorizationManager {
  return [self initWithAuthorizationManager:authorizationManager
                       deferredImageManager:^id<PTNPhotoKitImageManager>{
    return [PHCachingImageManager defaultManager];
  }];
}

- (void)instantiateImageManagerIfNeeded {
  if (!self.imageManager) {
    _imageManager = self.deferredImageManager();
  }
}

#pragma mark -
#pragma mark PTNPhotoKitImageManager
#pragma mark -

- (PHImageRequestID)requestImageForAsset:(PHAsset *)asset
                              targetSize:(CGSize)targetSize
                             contentMode:(PHImageContentMode)contentMode
                                 options:(PHImageRequestOptions *)options
                           resultHandler:(PTNPhotoKitImageManagerHandler)resultHandler {
  if (![self.authorizationManager.authorizationStatus
        isEqual:$(PTNAuthorizationStatusAuthorized)]) {
    resultHandler(nil, @{PHImageErrorKey: [NSError lt_errorWithCode:PTNErrorCodeNotAuthorized]});
    return 0;
  }

  [self instantiateImageManagerIfNeeded];
  return [self.imageManager requestImageForAsset:asset targetSize:targetSize
                                     contentMode:contentMode options:options
                                   resultHandler:resultHandler];
}

- (void)cancelImageRequest:(PHImageRequestID)requestID {
  if (![self.authorizationManager.authorizationStatus
        isEqual:$(PTNAuthorizationStatusAuthorized)]) {
    return;
  }

  [self instantiateImageManagerIfNeeded];
  return [self.imageManager cancelImageRequest:requestID];
}

- (PHImageRequestID)requestAVAssetForVideo:(PHAsset *)asset
                                   options:(PHVideoRequestOptions *)options
                             resultHandler:(PTNPhotoKitImageManagerAVAssetHandler)resultHandler {
  LTParameterAssert(resultHandler, "resultHandler block cannot be nil");
  if (![self.authorizationManager.authorizationStatus
        isEqual:$(PTNAuthorizationStatusAuthorized)]) {
    resultHandler(nil, nil,
                  @{PHImageErrorKey: [NSError lt_errorWithCode:PTNErrorCodeNotAuthorized]});
    return 0;
  }

  [self instantiateImageManagerIfNeeded];
  return [self.imageManager requestAVAssetForVideo:asset options:options
                                     resultHandler:resultHandler];
}

- (PHImageRequestID)requestImageDataForAsset:(PHAsset *)asset
    options:(PHImageRequestOptions *)options
    resultHandler:(PTNPhotoKitImageManagerImageDataHandler)resultHandler {
  LTParameterAssert(resultHandler, "resultHandler block cannot be nil");
  if (![self.authorizationManager.authorizationStatus
        isEqual:$(PTNAuthorizationStatusAuthorized)]) {
    resultHandler(nil, nil, UIImageOrientationUp,
                  @{PHImageErrorKey: [NSError lt_errorWithCode:PTNErrorCodeNotAuthorized]});
    return 0;
  }

  [self instantiateImageManagerIfNeeded];
  return [self.imageManager requestImageDataForAsset:asset options:options
                                       resultHandler:resultHandler];
}

- (PHImageRequestID)requestPlayerItemForVideo:(PHAsset *)asset
    options:(PHVideoRequestOptions *)options
    resultHandler:(PTNPhotoKitImageManagerAVPreviewHandler)resultHandler {
  LTParameterAssert(resultHandler, "resultHandler block cannot be nil");
  if (![self.authorizationManager.authorizationStatus
        isEqual:$(PTNAuthorizationStatusAuthorized)]) {
    resultHandler(nil, @{PHImageErrorKey: [NSError lt_errorWithCode:PTNErrorCodeNotAuthorized]});
    return 0;
  }

  [self instantiateImageManagerIfNeeded];
  return [self.imageManager requestPlayerItemForVideo:asset options:options
                                        resultHandler:resultHandler];
}

@end

NS_ASSUME_NONNULL_END
