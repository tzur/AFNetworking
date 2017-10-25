// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRProductContentManager.h"

#import "BZRFileArchiver.h"
#import "BZRZipFileArchiver.h"
#import "NSErrorCodes+Bazaar.h"
#import "NSFileManager+Bazaar.h"

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

- (instancetype)initWithFileManager:(NSFileManager *)fileManager {
  BZRZipFileArchiver *archiver = [[BZRZipFileArchiver alloc] initWithFileManager:fileManager];
  return [self initWithFileManager:fileManager fileArchiver:archiver];
}

- (instancetype)initWithFileManager:(NSFileManager *)fileManager
                       fileArchiver:(id<BZRFileArchiver>)fileArchiver {
  if (self = [super init]) {
    _fileManager = fileManager;
    _fileArchiver = fileArchiver;
  }

  return self;
}

- (RACSignal<NSBundle *> *)extractContentOfProduct:(NSString *)productIdentifier
                                       fromArchive:(LTPath *)archivePath {
  auto contentDirectoryPath = [self contentDirectoryPathForProduct:productIdentifier];
  return [self extractContentFromArchive:archivePath intoDirectory:contentDirectoryPath
                       productIdentifier:productIdentifier];
}

- (RACSignal<NSBundle *> *)extractContentOfProduct:(NSString *)productIdentifier
                                       fromArchive:(LTPath *)archivePath
                                     intoDirectory:(NSString *)directoryName {
  auto contentDirectoryPath = [[self contentDirectoryPathForProduct:productIdentifier]
                               pathByAppendingPathComponent:directoryName];
  return [self extractContentFromArchive:archivePath intoDirectory:contentDirectoryPath
                       productIdentifier:productIdentifier];
}

- (RACSignal<NSBundle *> *)extractContentFromArchive:(LTPath *)archivePath
                                       intoDirectory:(LTPath *)contentDirectoryPath
                                   productIdentifier:(NSString *)productIdentifier {
  auto productDirectoryPath = [self contentDirectoryPathForProduct:productIdentifier];
  auto directoryName = [contentDirectoryPath.url lastPathComponent];
  auto parentDirectoryURL = [contentDirectoryPath.url URLByDeletingLastPathComponent];
  auto parentDirectoryPath = [LTPath pathWithPath:parentDirectoryURL.path];

  LTPath *tempPath = [parentDirectoryPath
                      pathByAppendingPathComponent:[@"_" stringByAppendingString:directoryName]];

  return [[[RACSignal concat:@[
    [self.fileManager bzr_deleteItemAtPathIfExists:productDirectoryPath.path],
    [self.fileManager bzr_createDirectoryAtPathIfNotExists:tempPath.path],
    [self.fileArchiver unarchiveArchiveAtPath:archivePath.path toDirectory:tempPath.path],
    [self.fileManager bzr_moveItemAtPath:tempPath.path toPath:contentDirectoryPath.path]
  ]]
  then:^RACSignal<NSBundle *> *{
    return [RACSignal return:[self bundleWithPath:contentDirectoryPath]];
  }]
  setNameWithFormat:@"%@ -extractContent", self.description];
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

- (NSBundle *)bundleWithPath:(LTPath *)pathToContent {
  return [NSBundle bundleWithPath:pathToContent.path];
}

@end

NS_ASSUME_NONNULL_END
