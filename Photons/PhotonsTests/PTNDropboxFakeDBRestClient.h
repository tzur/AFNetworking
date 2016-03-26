// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import <DropboxSDK/DropboxSDK.h>

NS_ASSUME_NONNULL_BEGIN

/// Fake \c DBRestClient object for easier testing.
@interface PTNDropboxFakeDBRestClient : DBRestClient

/// Calls delegate's \c -[DBRestClientDelegate restClient:loadedMetadata:] with \c metdata.
- (void)deliverMetadata:(DBMetadata *)metadata;

/// Calls delegate's \c -[DBRestClientDelegate restClient:loadedMetadataFailureWithError:] with
/// \c metadataError.
- (void)deliverMetadataError:(NSError *)metadataError;

/// Calls delegate's \c -[DBRestClientDelegate restClient:loadedFile:] with \c localPath.
- (void)deliverFile:(NSString *)localPath;

/// Calls delegate's \c -[DBRestClientDelegate restClient:loadProgress:forFile:] with \c progress
/// and \c localPath.
- (void)deliverProgress:(CGFloat)progress forFile:(NSString *)localPath;

/// Calls delegates \c -[DBRestClientDelegate restClient:loadedFileFailureWithError:] with
/// \c fileError.
- (void)deliverFileError:(NSError *)fileError;

/// Calls delegate's \c -[DBRestClientDelegate restClient:loadedThumbnail:] with \c localPath.
- (void)deliverThumbnail:(NSString *)localPath;

/// Calls delegates \c -[DBRestClientDelegate restClient:loadedThumbnailFailureWithError:] with
/// \c thumbnailError.
- (void)deliverThumbnailError:(NSError *)thumbnail;

/// The requested \c destPath if file at \c path and \c revision was requested or nil if file
/// wasn't requested.
- (nullable NSString *)didRequestFileAtPath:(NSString *)path revision:(nullable NSString *)revision;

/// \c YES if request for file at \c path and \c revision was canceled.
- (BOOL)didCancelRequestForFileAtPath:(NSString *)path revision:(nullable NSString *)revision;

/// The requested \c destinationPath if thumbnail at \c path and \c size was requested or nil if
/// thumbnail wasn't requested
- (nullable NSString *)didRequestThumbnailAtPath:(NSString *)path size:(NSString *)size;

/// \c YES if request for thumbnail at \c path and \c size was canceled.
- (BOOL)didCancelRequestForThumbnailAtPath:(NSString *)path size:(NSString *)size;

/// \c YES if file at \c path and \c revision was requested.
- (BOOL)didRequestMetadataAtPath:(NSString *)path revision:(nullable NSString *)revision;

@end

NS_ASSUME_NONNULL_END
