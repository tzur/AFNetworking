// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNDropboxFakeDBRestClient.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTNDropboxFakeDBRestClient ()

/// Metadata request book keeping. The entry [<path>.rev:<rev>] will be not \c nil if requested.
@property (strong, nonatomic) NSMutableDictionary *metadataRequests;

/// File request book keeping. The entry [<path>.rev:<rev>] will be contain the destination path if
/// requested.
@property (strong, nonatomic) NSMutableDictionary *fileRequests;

/// Thumbnail request book keeping. The entry [<path>.size:<size>] will be contain the destination
/// path if requested.
@property (strong, nonatomic) NSMutableDictionary *thumbnailRequests;

/// File request cancellations book keeping. The entry [<path>.rev:<rev>] will be exist if request
/// was canceled.
@property (strong, nonatomic) NSMutableArray *fileRequestCancels;

/// Thumbnails request cancellations book keeping. The entry [<path>.size:<size>] will be exist if
/// request was canceled.
@property (strong, nonatomic) NSMutableArray *thumbnailRequestCancels;

@end

@implementation PTNDropboxFakeDBRestClient

- (instancetype)init {
  if (self = [super init]) {
    self.metadataRequests = [NSMutableDictionary dictionary];
    self.fileRequests = [NSMutableDictionary dictionary];
    self.thumbnailRequests = [NSMutableDictionary dictionary];
    self.fileRequestCancels = [NSMutableArray array];
    self.thumbnailRequestCancels = [NSMutableArray array];
  }
  return self;
}

- (NSString *)keyForFile:(NSString *)path revision:(nullable NSString *)revision {
  return [NSString stringWithFormat:@"%@.rev:%@", path, revision ?: @"latest"];
}

- (NSString *)keyForThumbnail:(NSString *)path size:(NSString *)size {
  return [NSString stringWithFormat:@"%@.size:%@", path, size];
}

#pragma mark -
#pragma mark Request book keeping
#pragma mark -

- (void)requestedMetadata:(NSString *)path atRev:(NSString *)rev {
  self.metadataRequests[[self keyForFile:path revision:rev]] = @YES;
}

- (void)requestedFile:(NSString *)path atRev:(NSString *)rev toDest:(NSString *)dest{
  self.fileRequests[[self keyForFile:path revision:rev]] = dest;
}

- (void)requestedThumbnail:(NSString *)path ofSize:(NSString *)size toDest:(NSString *)dest{
  self.thumbnailRequests[[self keyForThumbnail:path size:size]] = dest;
}

- (void)requestFileCanceled:(NSString *)keyPath {
  [self.fileRequestCancels addObject:keyPath];
}

- (void)requestThumbnailCanceled:(NSString *)keyPath {
  [self.thumbnailRequestCancels addObject:keyPath];
}

- (nullable NSString *)didRequestFileAtPath:(NSString *)path
                                   revision:(nullable NSString *)revision {
  return self.fileRequests[[self keyForFile:path revision:revision]];
}

- (BOOL)didCancelRequestForFileAtPath:(NSString *)path revision:(nullable NSString *)revision {
  return [self.fileRequestCancels containsObject:[self keyForFile:path revision:revision]];
}

- (nullable NSString *)didRequestThumbnailAtPath:(NSString *)path size:(NSString *)size {
  return self.thumbnailRequests[[self keyForThumbnail:path size:size]];
}

- (BOOL)didCancelRequestForThumbnailAtPath:(NSString *)path size:(NSString *)size {
  return [self.thumbnailRequestCancels containsObject:[self keyForThumbnail:path size:size]];
}

- (BOOL)didRequestMetadataAtPath:(NSString *)path revision:(nullable NSString *)revision {
  return [self.metadataRequests[[self keyForFile:path revision:revision]] boolValue];
}

#pragma mark -
#pragma mark Metadata
#pragma mark -

- (void)loadMetadata:(NSString *)path {
  [self loadMetadata:path atRev:nil];
}

- (void)loadMetadata:(NSString *)path atRev:(NSString *)rev {
  [self requestedMetadata:path atRev:rev];
}

- (void)deliverMetadata:(DBMetadata *)metadata {
  [delegate restClient:self loadedMetadata:metadata];
}

- (void)deliverMetadataError:(NSError *)metadataError {
  [delegate restClient:self loadMetadataFailedWithError:metadataError];
}

#pragma mark -
#pragma mark Files
#pragma mark -

- (void)loadFile:(NSString *)path intoPath:(NSString *)destinationPath {
  [self loadFile:path atRev:@"latest" intoPath:destinationPath];
}

- (void)loadFile:(NSString *)path atRev:(NSString *)rev intoPath:(NSString *)destPath {
  [self requestedFile:path atRev:rev toDest:destPath];
}

- (void)cancelFileLoad:(NSString *)path {
  for (NSString *request in [self.fileRequests keyEnumerator]) {
    if ([[[request componentsSeparatedByString:@".rev:"] firstObject] isEqualToString:path]) {
      [self requestFileCanceled:request];
    }
  }
}

- (void)deliverFile:(NSString *)localPath {
  [delegate restClient:self loadedFile:localPath];
}

- (void)deliverFileError:(NSError *)fileError {
  [delegate restClient:self loadFileFailedWithError:fileError];
}

- (void)deliverProgress:(CGFloat)progress forFile:(NSString *)localPath {
  [delegate restClient:self loadProgress:progress forFile:localPath];
}

#pragma mark -
#pragma mark Thumbnails
#pragma mark -

- (void)loadThumbnail:(NSString *)path ofSize:(NSString *)size
             intoPath:(NSString *)destinationPath {
  [self requestedThumbnail:path ofSize:size toDest:destinationPath];
}

- (void)cancelThumbnailLoad:(NSString *)path size:(NSString *)size{
  [self requestThumbnailCanceled:[self keyForThumbnail:path size:size]];
}

- (void)deliverThumbnail:(NSString *)localPath {
  [delegate restClient:self loadedThumbnail:localPath];
}

- (void)deliverThumbnailError:(NSError *)ThumbnailError {
  [delegate restClient:self loadThumbnailFailedWithError:ThumbnailError];
}

@end

NS_ASSUME_NONNULL_END
