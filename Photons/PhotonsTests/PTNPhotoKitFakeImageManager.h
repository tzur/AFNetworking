// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import <Photos/Photos.h>

#import "PTNPhotoKitImageManager.h"

NS_ASSUME_NONNULL_BEGIN

/// Fake image manager used for testing PTNPhotoKitAssetManager.
@interface PTNPhotoKitFakeImageManager : NSObject <PTNPhotoKitImageManager>

/// Serves the given \c asset by sending the given \c progress reports (array of \c NSNumber
/// values), and finally the given \c image.
- (void)serveAsset:(PHAsset *)asset withProgress:(NSArray<NSNumber *> *)progress
             image:(UIImage *)image;

/// Serves the given \c asset by sending the given \c progress reports (array of \c NSNumber
/// values), and finally the given \c avasset and \c audioMix.
- (void)serveAsset:(PHAsset *)asset withProgress:(NSArray<NSNumber *> *)progress
           avasset:(AVAsset *)avasset audioMix:(AVAudioMix *)audioMix;

/// Serves the given \c asset by sending the given \c progress reports (array of \c NSNumber
/// values), and finally the given \c imageData, \c dataUTI, and \c orientation.
- (void)serveAsset:(PHAsset *)asset withProgress:(NSArray<NSNumber *> *)progress
         imageData:(NSData *)imageData dataUTI:(NSString *)dataUTI
       orientation:(UIImageOrientation)orientation;

/// Serves the given \c asset by sending the given \c progress reports (array of \c NSNumber
/// values), and finally the given \c playerItem.
- (void)serveAsset:(PHAsset *)asset withProgress:(NSArray<NSNumber *> *)progress
        playerItem:(AVPlayerItem *)playerItem;

/// Serves the given \c asset by sending the given \c progress reports (array of \c NSNumber
/// values), and finally the given \c livePhoto.
- (void)serveAsset:(PHAsset *)asset withProgress:(NSArray<NSNumber *> *)progress
         livePhoto:(PHLivePhoto *)livePhoto API_AVAILABLE(ios(9.1));

/// Serves the given \c asset by sending the given \c progress reports (array of \c NSNumber
/// values), and finally errs with the given \c error.
- (void)serveAsset:(PHAsset *)asset withProgress:(NSArray<NSNumber *> *)progress
      finallyError:(NSError *)error;

/// Serves the given \c asset by sending the given \c progress reports (array of NSNumber values),
/// and errs with the given \c error together with the last progress and in the final handler block.
- (void)serveAsset:(PHAsset *)asset withProgress:(NSArray<NSNumber *> *)progress
   errorInProgress:(NSError *)error;

/// \c YES if a request for the given \c asset has been cancelled.
- (BOOL)isRequestCancelledForAsset:(PHAsset *)asset;

/// \c YES if a request for the given \c asset has been issued.
- (BOOL)isRequestIssuedForAsset:(PHAsset *)asset;

@end

NS_ASSUME_NONNULL_END
