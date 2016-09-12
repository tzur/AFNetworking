// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRProductContentManager.h"

#import <LTKit/LTPath.h>
#import <LTKit/LTProgress.h>

#import "BZRFileArchiver.h"
#import "NSErrorCodes+Bazaar.h"
#import "NSFileManager+Bazaar.h"
#import "BZRZipFileArchiver.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRProductContentManager ()

/// Manager used to create and delete content directory, and query whether it exists.
@property (readonly, nonatomic) NSFileManager *fileManager;

/// Archiver used to extract content from an archive file into the content directory.
@property (readonly, nonatomic) id<BZRFileArchiver> fileArchiver;

@end

@implementation BZRProductContentManager

/// Base directory where all product's content are saved.
NSString * const kBazaarProductsContentDirectory = @"Bazaar/ProductsContent/";

- (instancetype)init {
  BZRZipFileArchiver *archiver = [[BZRZipFileArchiver alloc] init];
  return [self initWithFileManager:[NSFileManager defaultManager] fileArchiver:archiver];
}

- (instancetype)initWithFileManager:(NSFileManager *)fileManager
                       fileArchiver:(id<BZRFileArchiver>)fileArchiver {
  if (self = [super init]) {
    _fileManager = fileManager;
    _fileArchiver = fileArchiver;
  }

  return self;
}

- (RACSignal *)extractContentOfProduct:(NSString *)productIdentifier
                           fromArchive:(LTPath *)archivePath {
  LTPath *contentDirectoryPath = [self contentDirectoryPathForProduct:productIdentifier];
  RACSignal *removeDirectorySignal =
      [self.fileManager bzr_deleteItemAtPathIfExists:contentDirectoryPath.path];
  RACSignal *createDirectiorySignal =
      [self.fileManager bzr_createDirectoryAtPathIfNotExists:contentDirectoryPath.path];
  RACSignal *extractContentSignal =
      [self extractContentSignal:contentDirectoryPath archivePath:archivePath];

  return [[RACSignal concat:@[removeDirectorySignal, createDirectiorySignal, extractContentSignal]]
      setNameWithFormat:@"%@ -extractContent", self.description];
}

- (RACSignal *)extractContentSignal:(LTPath *)contentDirectoryPath
                        archivePath:(LTPath *)archivePath {
  return [[[self.fileArchiver unarchiveArchiveAtPath:archivePath.path
                                         toDirectory:contentDirectoryPath.path]
      filter:^BOOL(LTProgress<NSString *> *unarchiveProgress) {
        return unarchiveProgress.result != nil;
      }] map:^LTPath *(LTProgress<NSString *> *unarchiveProgress) {
        return [LTPath pathWithPath:unarchiveProgress.result];
      }];
}

- (RACSignal *)deleteContentDirectoryOfProduct:(NSString *)productIdentifier {
  LTPath *contentDirectoryPath = [self contentDirectoryPathForProduct:productIdentifier];
  return [[self.fileManager bzr_deleteItemAtPathIfExists:contentDirectoryPath.path]
      setNameWithFormat:@"%@ -deleteContent", self.description];
}

- (nullable LTPath *)pathToContentDirectoryOfProduct:(NSString *)productIdentifier {
  LTPath *contentDirectoryPath = [self contentDirectoryPathForProduct:productIdentifier];
  if ([self.fileManager fileExistsAtPath:contentDirectoryPath.path]) {
    return contentDirectoryPath;
  }
  return nil;
}

- (LTPath *)contentDirectoryPathForProduct:(NSString *)productIdentifier {
  NSString *relativePathToContent =
      [kBazaarProductsContentDirectory stringByAppendingPathComponent:productIdentifier];
  return [LTPath pathWithBaseDirectory:LTPathBaseDirectoryApplicationSupport
                       andRelativePath:relativePathToContent];
}

@end

NS_ASSUME_NONNULL_END
