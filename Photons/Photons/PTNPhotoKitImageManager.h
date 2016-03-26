// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

/// Protocol to be implemented by PhotoKit image managers.
@protocol PTNPhotoKitImageManager <NSObject>

/// Handles successful or erroneous callbacks.
typedef void (^PTNPhotoKitImageManagerHandler)(UIImage * __nullable result,
                                               NSDictionary * __nullable info);

/// Requests an image representation for the specified asset.
///
/// @see -[PHImageManager requestImageForAsset:targetSize:contentMode:options:resultHandler:].
- (PHImageRequestID)requestImageForAsset:(PHAsset *)asset
                              targetSize:(CGSize)targetSize
                             contentMode:(PHImageContentMode)contentMode
                                 options:(PHImageRequestOptions *)options
                           resultHandler:(PTNPhotoKitImageManagerHandler)resultHandler;

/// Cancels an asynchronous request.
///
/// @see -[PHImageManager cancelImageRequest:].
- (void)cancelImageRequest:(PHImageRequestID)requestID;

@end

@interface PHImageManager () <PTNPhotoKitImageManager>
@end

NS_ASSUME_NONNULL_END
