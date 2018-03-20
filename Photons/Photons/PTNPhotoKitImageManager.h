// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

/// Protocol to be implemented by PhotoKit image managers.
@protocol PTNPhotoKitImageManager <NSObject>

/// Handles successful or erroneous callbacks of \c
/// requestImageForAsset:targetSize:contentMode:options:resultHandler:.
typedef void (^PTNPhotoKitImageManagerHandler)(UIImage * __nullable result,
                                               NSDictionary * __nullable info);

/// Handles successful or erroneous callbacks of \c requestAVAssetForVideo:options:resultHandler:.
typedef void (^PTNPhotoKitImageManagerAVAssetHandler)(AVAsset * __nullable asset,
                                                      AVAudioMix * __nullable audioMix,
                                                      NSDictionary * __nullable info);

/// Handles successful or erroneous callbacks of \c requestImageDataForAsset:options:resultHandler:.
typedef void (^PTNPhotoKitImageManagerImageDataHandler)(NSData *__nullable imageData,
                                                        NSString *__nullable dataUTI,
                                                        UIImageOrientation orientation,
                                                        NSDictionary *__nullable info);

/// Handles successful or erroneous callbacks of
/// \c requestPlayerItemForVideo:options:resultHandler:.
typedef void (^PTNPhotoKitImageManagerAVPreviewHandler)(AVPlayerItem *__nullable playerItem,
                                                        NSDictionary *__nullable info);

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

/// Requests an \c AVAsset for the specified asset.
///
/// @see -[PHImageManager requestAVAssetForVideo:options:resultHandler:].
- (PHImageRequestID)requestAVAssetForVideo:(PHAsset *)asset
                                   options:(PHVideoRequestOptions *)options
                             resultHandler:(PTNPhotoKitImageManagerAVAssetHandler)resultHandler;

/// Requests a full-fized image data for the specified asset.
///
/// @see -[PHImageManager requestImageDataForAsset:options:resultHandler:].
- (PHImageRequestID)requestImageDataForAsset:(PHAsset *)asset
                                     options:(PHImageRequestOptions *)options
                               resultHandler:(PTNPhotoKitImageManagerImageDataHandler)resultHandler;

/// Requests a \c AVPlayerItem object for the specified asset.
///
/// @see -[PHImageManager requestPlayerItemForVideo:options:resultHandler:].
- (PHImageRequestID)requestPlayerItemForVideo:(PHAsset *)asset
    options:(PHVideoRequestOptions *)options
    resultHandler:(PTNPhotoKitImageManagerAVPreviewHandler)resultHandler;

@end

@interface PHImageManager () <PTNPhotoKitImageManager>
@end

NS_ASSUME_NONNULL_END
