// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNDropboxAtomicRestClient.h"

#import <LTKit/LTPath.h>
#import <LTKit/NSFileManager+LTKit.h>

#import "NSError+Photons.h"
#import "PTNDropboxPathProvider.h"
#import "PTNDropboxThumbnail.h"
#import "PTNProgress.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark -
#pragma mark Unique path provider
#pragma mark -

/// A \c PTNDropboxPathProvider implementation that returns unique paths in the application's
/// temporary folder. Each path is pseudo-unique and will not be used more than once. Returned paths
/// are instances of \c NSUUID prefixed with the application's temporary folder's path.
@interface PTNDropboxUniquePathProvider : NSObject <PTNDropboxPathProvider>
@end

@implementation PTNDropboxUniquePathProvider

- (NSString *)localPathForFileInPath:(NSString *)path
                            revision:(nullable NSString __unused *)revision {
  // Since the returned path is unique revision can be ignored.
  return [self uniquePathWithExtension:path.pathExtension];
}

- (NSString *)localPathForThumbnailInPath:(NSString *)path size:(__unused CGSize)size {
  // Since the returned path is unique size can be ignored.
  return [self uniquePathWithExtension:path.pathExtension];
}

- (NSString *)uniquePathWithExtension:(NSString *)pathExtension {
  NSString *suffix = [[[NSUUID UUID] UUIDString] stringByAppendingPathExtension:pathExtension];
  return [LTPath pathWithBaseDirectory:LTPathBaseDirectoryTemp andRelativePath:suffix].path;
}

@end

#pragma mark -
#pragma mark Atomic rest client
#pragma mark -

@interface PTNDropboxAtomicRestClient ()

/// Underlying rest client to be used for downloading.
@property (readonly, nonatomic) PTNDropboxRestClient *restClient;

/// Original path provider to provide paths for files to eventually be moved to.
@property (readonly, nonatomic) id<PTNDropboxPathProvider> pathProvider;

/// File manager used for moving of downloaded content.
@property (readonly, nonatomic) NSFileManager *fileManager;

@end

@implementation PTNDropboxAtomicRestClient

- (instancetype)initWithRestClientProvider:(id<PTNDropboxRestClientProvider>)restClientProvider
                              pathProvider:(id<PTNDropboxPathProvider>)pathProvider
                               fileManager:(NSFileManager *)fileManager {
  if (self = [super init]) {
    id<PTNDropboxPathProvider> internalPathProvider = [[PTNDropboxUniquePathProvider alloc] init];
    _restClient = [[PTNDropboxRestClient alloc] initWithRestClientProvider:restClientProvider
                                                              pathProvider:internalPathProvider];
    _pathProvider = pathProvider;
    _fileManager = fileManager;
  }
  return self;
}

#pragma mark -
#pragma mark PTNDropboxRestClient
#pragma mark -

- (RACSignal *)fetchMetadata:(NSString *)path revision:(nullable NSString *)revision {
  return [self.restClient fetchMetadata:path revision:revision];
}

- (RACSignal *)fetchFile:(NSString *)path revision:(nullable NSString *)revision {
  return [[self.restClient fetchFile:path revision:revision]
      flattenMap:^RACSignal *(PTNProgress *progress) {
        if (!progress.result) {
          return [RACSignal return:progress];
        }

        NSString *originalPath = [self.pathProvider localPathForFileInPath:path revision:revision];
        NSError *moveError;
        BOOL success = [self overwriteMoveItemAtPath:progress.result toPath:originalPath
                                               error:&moveError];
        if (!success) {
          return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeAssetLoadingFailed
                                            underlyingError:moveError]];
        }

        return [RACSignal return:[[PTNProgress alloc] initWithResult:originalPath]];
      }];
}

- (RACSignal *)fetchThumbnail:(NSString *)path type:(PTNDropboxThumbnailType *)type {
  return [[self.restClient fetchThumbnail:path type:type]
      flattenMap:^RACSignal *(NSString *localPath) {
        NSString *originalPath = [self.pathProvider localPathForThumbnailInPath:path
                                                                           size:type.size];
        NSError *moveError;
        BOOL success = [self overwriteMoveItemAtPath:localPath toPath:originalPath
                                               error:&moveError];
        if (!success) {
          return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeAssetLoadingFailed
                                            underlyingError:moveError]];
        }

        return [RACSignal return:originalPath];
      }];
}

- (BOOL)overwriteMoveItemAtPath:(NSString *)srcPath toPath:(NSString *)dstPath
                          error:(NSError * _Nullable *)error {
  if (![self.fileManager fileExistsAtPath:dstPath]) {
    return [self.fileManager moveItemAtPath:srcPath toPath:dstPath error:error];
  }
  
  return [self.fileManager replaceItemAtURL:[NSURL fileURLWithPath:dstPath]
                              withItemAtURL:[NSURL fileURLWithPath:srcPath] backupItemName:nil
                                    options:NSFileManagerItemReplacementUsingNewMetadataOnly
                           resultingItemURL:nil error:error];
}

@end

NS_ASSUME_NONNULL_END
