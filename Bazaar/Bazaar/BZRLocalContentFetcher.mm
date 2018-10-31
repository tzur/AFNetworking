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

@implementation BZRLocalContentFetcher

+ (Class)expectedParametersClass {
  return [BZRLocalContentFetcherParameters class];
}

#pragma mark -
#pragma mark Initialization
#pragma mark -

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

#pragma mark -
#pragma mark BZREventEmitter
#pragma mark -

- (RACSignal<BZREvent *> *)eventsSignal {
  return [RACSignal empty];
}

#pragma mark -
#pragma mark BZRProductContentFetcher
#pragma mark -

- (RACSignal<BZRContentFetchingProgress *> *)fetchProductContent:(BZRProduct *)product {
  if (![product.contentFetcherParameters isKindOfClass:[[self class] expectedParametersClass]]) {
    auto errorDescription =
        [NSString stringWithFormat:@"Content fetcher of type %@ is expecting parameters of type "
         "%@, got product (%@) with parameters %@", [BZRLocalContentFetcherParameters class],
         [self class], product.identifier, product.contentFetcherParameters];
    auto error = [NSError lt_errorWithCode:BZRErrorCodeInvalidContentFetcherParameters
                               description:@"%@", errorDescription];
    return [RACSignal error:error];
  }

  NSURL *URL = ((BZRLocalContentFetcherParameters *)product.contentFetcherParameters).URL;
  if (![URL isFileURL]) {
    return [RACSignal error:[NSError lt_errorWithCode:BZRErrorCodeInvalidContentFetcherParameters
        description:@"URL provided is not an address to a local file: %@", URL]];
  }

  NSString *contentFilename = [[URL absoluteString] lastPathComponent];
  LTPath *contentArchivePath = [LTPath pathWithBaseDirectory:LTPathBaseDirectoryTemp
                                             andRelativePath:contentFilename];

  auto copySignal = [self createCopyFileSignalFrom:URL to:contentArchivePath];
  auto extractSignal =
      [[self.contentManager extractContentOfProduct:product.identifier
                                        fromArchive:contentArchivePath
                                     intoDirectory:[self contentDirectoryNameForProduct:product]]
       map:^BZRContentFetchingProgress *(NSBundle *bundle) {
         return [[LTProgress alloc] initWithResult:bundle];
       }];
  auto deleteArchiveSignal =
      [self.fileManager bzr_deleteItemAtPathIfExists:contentArchivePath.path];

  return [[RACSignal concat:@[copySignal, extractSignal, deleteArchiveSignal]]
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

- (NSString *)contentDirectoryNameForProduct:(BZRProduct *)product {
  NSURL *URL = ((BZRLocalContentFetcherParameters *)product.contentFetcherParameters).URL;
  return [[[URL absoluteString] lastPathComponent] stringByDeletingPathExtension];
}

- (RACSignal<NSBundle *> *)contentBundleForProduct:(BZRProduct *)product {
  if (![product.contentFetcherParameters isKindOfClass:[[self class] expectedParametersClass]]) {
    return [RACSignal return:nil];
  }

  auto contentPath = [self contentDirectoryPathOfProduct:product];
  return [RACSignal return:(contentPath ? [self bundleWithPath:contentPath] : nil)];
}

- (nullable LTPath *)contentDirectoryPathOfProduct:(BZRProduct *)product {
  auto _Nullable productDirectory =
      [self.contentManager pathToContentDirectoryOfProduct:product.identifier];
  return [productDirectory pathByAppendingPathComponent:
          [self contentDirectoryNameForProduct:product]];
}

- (NSBundle *)bundleWithPath:(LTPath *)pathToContent {
  return [NSBundle bundleWithPath:pathToContent.path];
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
