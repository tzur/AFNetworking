// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

/// Protocol to be implemented by PhotoKit asset resource managers.
@protocol PTNPhotoKitAssetResourceManager <NSObject>

/// Requests the underlying data for the specified asset resource, to be delivered asynchronously.
///
/// @see -[PHAssetResourcerManager
//         requestDataForAssetResource:options:dataReceivedHandler:completionHandler:].
- (PHAssetResourceDataRequestID)requestDataForAssetResource:(PHAssetResource *)resource
    options:(nullable PHAssetResourceRequestOptions *)options
    dataReceivedHandler:(void (^)(NSData *data))handler
    completionHandler:(void(^)(NSError *_Nullable error))completionHandler;

/// Requests the underlying data for the specified asset resource, to be asynchronously written to a
/// local file.
///
/// @see -[PHAssetResourcerManager writeDataForAssetResource:toFile:options:completionHandler:].
- (void)writeDataForAssetResource:(PHAssetResource *)resource
                           toFile:(NSURL *)fileURL
                          options:(nullable PHAssetResourceRequestOptions *)options
                completionHandler:(void(^)(NSError *_Nullable error))completionHandler;

/// Cancels an asynchronous request.
- (void)cancelDataRequest:(PHAssetResourceDataRequestID)requestID;

@end

@interface PHAssetResourceManager () <PTNPhotoKitAssetResourceManager>
@end

NS_ASSUME_NONNULL_END
