// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRLocalContentFetcher.h"

#import "BZRProduct.h"
#import "BZRProductContentManager.h"
#import "NSErrorCodes+Bazaar.h"
#import "NSFileManager+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRLocalContentFetcher ()

/// Manager used to copy files from the given URL to temp folder.
@property (readonly, nonatomic) NSFileManager *fileManager;

/// Manager used to extract content from an archive file.
@property (readonly, nonatomic) BZRProductContentManager *contentManager;

@end

#pragma mark -
#pragma mark BZRLocalContentFetcher
#pragma mark -

@implementation BZRLocalContentFetcher

- (instancetype)init {
  BZRProductContentManager *contentManager =
      [[BZRProductContentManager alloc] initWithFileManager:[NSFileManager defaultManager]];
  return [self initWithFileManager:[NSFileManager defaultManager] contentManager:contentManager];
}

- (instancetype)initWithFileManager:(NSFileManager *)fileManager
                     contentManager:(BZRProductContentManager *)contentManager {
  if (self = [super init]) {
    _fileManager = fileManager;
    _contentManager = contentManager;
  }

  return self;
}

- (RACSignal *)fetchProductContent:(BZRProduct *)product {
  if (![product.contentFetcherParameters isKindOfClass:[BZRLocalContentFetcherParameters class]]) {
    auto error = [NSError lt_errorWithCode:BZRErrorCodeInvalidContentFetcherParameters
                               description:@"The provided parameters class must be: %@",
                                           [BZRLocalContentFetcherParameters class]];
    return [RACSignal error:error];
  }

  NSURL *URL = ((BZRLocalContentFetcherParameters *)product.contentFetcherParameters).URL;
  if (![URL isFileURL]) {
    return [RACSignal error:[NSError lt_errorWithCode:BZRErrorCodeInvalidContentFetcherParameters
        description:@"URL provided is not an address to a local file: %@", URL]];
  }

  NSString *contentFilename = [[URL absoluteString] lastPathComponent];
  LTPath *targetPath = [LTPath pathWithBaseDirectory:LTPathBaseDirectoryTemp
                                     andRelativePath:contentFilename];

  RACSignal *deleteSignal = [self.fileManager bzr_deleteItemAtPathIfExists:targetPath.path];
  RACSignal *copySignal = [self createCopyFileSignalFrom:URL to:targetPath];
  RACSignal *extractSignal = [self extractContentOfProduct:product.identifier
                                               fromArchive:targetPath];

  return [[RACSignal concat:@[deleteSignal, copySignal, extractSignal]]
          setNameWithFormat:@"%@ -fetchProductContent", self.description];
}

- (RACSignal *)createCopyFileSignalFrom:(NSURL *)sourceURL to:(LTPath *)targetPath {
  @weakify(self);
  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    @strongify(self);
    NSError *error;
    [self.fileManager copyItemAtURL:sourceURL toURL:targetPath.url error:&error];
    if (error) {
      NSError *copyContentError = [NSError lt_errorWithCode:BZRErrorCodeCopyProductContentFailed
                                            underlyingError:error];
      [subscriber sendError:copyContentError];
    } else {
      [subscriber sendCompleted];
    }
    return nil;
  }];
}

- (RACSignal *)extractContentOfProduct:(NSString *)productIdentifier
                           fromArchive:(LTPath *)archivePath {
  @weakify(self);
  return [RACSignal defer:^RACSignal *{
    @strongify(self);
    return [[self.contentManager extractContentOfProduct:productIdentifier fromArchive:archivePath]
            map:^LTProgress *(LTPath *unarchivedPath) {
              return [[LTProgress alloc] initWithResult:
                      [NSBundle bundleWithPath:unarchivedPath.path]];
            }];
  }];
}

- (nullable NSBundle *)contentBundleForProduct:(BZRProduct *)product {
  LTPath *pathToContent = [self.contentManager pathToContentDirectoryOfProduct:product.identifier];
  return pathToContent ? [NSBundle bundleWithPath:pathToContent.path] : nil;
}

+ (Class)expectedParametersClass {
  return [BZRLocalContentFetcherParameters class];
}

@end

#pragma mark -
#pragma mark BZRLocalContentFetcherParameters
#pragma mark -

@implementation BZRLocalContentFetcherParameters

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return [[super JSONKeyPathsByPropertyKey] mtl_dictionaryByAddingEntriesFromDictionary:@{
    @instanceKeypath(BZRLocalContentFetcherParameters, URL): @"URL"
  }];
}

+ (NSValueTransformer *)URLJSONTransformer {
  return [MTLValueTransformer
      reversibleTransformerWithForwardBlock:^NSURL *(NSString *URLString) {
        return [NSURL URLWithString:URLString];
      }
      reverseBlock:^NSString *(NSURL *URL) {
        return URL.absoluteString;
      }];
}

@end

NS_ASSUME_NONNULL_END
