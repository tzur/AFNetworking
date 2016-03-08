// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

NS_ASSUME_NONNULL_BEGIN

@class DBMetadata, PTNDropboxThumbnailType;

/// Fake REST client used for testing PTNDropboxAssetManager.
@interface PTNDropboxFakeRestClient : NSObject

/// Serves the given \c path and \c revision metadata by sending the given \c metadata.
- (void)serveMetadataAtPath:(NSString *)path revision:(nullable NSString *)revision
               withMetadata:(DBMetadata *)metadata;

/// Serves the given \c path and \c revision metadata by sending the given \c error.
- (void)serveMetadataAtPath:(NSString *)path revision:(nullable NSString *)revision
                  withError:(NSError *)error;

/// Serves the given \c path and \c revision file by sending the given \c progress reports (array of
/// \c NSNumber values wrapped by \c PTNProgress), and finally the given \c localPath wrapped by
/// \c PTNProgress.
- (void)serveFileAtPath:(NSString *)path revision:(nullable NSString *)revision
           withProgress:(nullable NSArray<NSNumber *> *)progress
              localPath:(NSString *)localPath;

/// Serves the given \c path and \c revision file by sending the given \c progress reports (array of
/// \c NSNumber values wrapped by \c PTNProgress), and finally the given \c error.
- (void)serveFileAtPath:(NSString *)path revision:(nullable NSString *)revision
           withProgress:(nullable NSArray<NSNumber *> *)progress
           finallyError:(NSError *)error;

/// Serves the given \c path and \c type thumbnail by sending the given \c localPath.
- (void)serveThumbnailAtPath:(NSString *)path type:(nullable PTNDropboxThumbnailType *)type
               withLocalPath:(NSString *)localPath;

/// Serves the given \c path and \c type thumbnail by sending the given  \c error.
- (void)serveThumbnailAtPath:(NSString *)path type:(nullable PTNDropboxThumbnailType *)type
                   withError:(NSError *)error;

@end

NS_ASSUME_NONNULL_END
