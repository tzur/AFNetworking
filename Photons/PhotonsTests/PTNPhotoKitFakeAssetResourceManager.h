// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNPhotoKitAssetResourceManager.h"

NS_ASSUME_NONNULL_BEGIN

/// Fake asset resource manager for testing.
@interface PTNPhotoKitFakeAssetResourceManager : NSObject <PTNPhotoKitAssetResourceManager>

/// Serves the given \c resource by sending the given \c progress reports (array of \c NSNumber
/// values) and the \c data broken to chunks according to slices defined by \c progress.
- (void)serveResource:(PHAssetResource *)resource withProgress:(NSArray<NSNumber *> *)progress
                 data:(NSData *)data;

/// Serves the given \c resource by sending the given \c progress reports (array of \c NSNumber
/// values), and finally errs with the given \c error.
- (void)serveResource:(PHAssetResource *)resource withProgress:(NSArray<NSNumber *> *)progress
         finallyError:(NSError *)error;

/// \c YES if a request for the given \c resource has been cancelled.
- (BOOL)isRequestCancelledForResource:(PHAssetResource *)resource;

/// \c YES if a request for the given \c resource has been issued.
- (BOOL)isRequestIssuedForResource:(PHAssetResource *)resource;

@end

NS_ASSUME_NONNULL_END
