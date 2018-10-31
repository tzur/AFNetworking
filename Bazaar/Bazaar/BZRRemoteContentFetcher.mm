// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "BZRRemoteContentFetcher.h"

#import <Fiber/FBRHTTPClient.h>
#import <Fiber/FBRHTTPRequest.h>
#import <Fiber/FBRHTTPResponse.h>
#import <LTKit/NSFileManager+LTKit.h>

#import "BZRProduct.h"
#import "BZRProductContentManager.h"
#import "NSErrorCodes+Bazaar.h"
#import "NSFileManager+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRRemoteContentFetcher ()

/// Manager used to delete files.
@property (readonly, nonatomic) NSFileManager *fileManager;

/// Manager used to extract content from an archive file.
@property (readonly, nonatomic) BZRProductContentManager *contentManager;

/// HTTP client used to fetch content from a remote URL.
@property (readonly, nonatomic) FBRHTTPClient *HTTPClient;

@end

@implementation BZRRemoteContentFetcher

+ (Class)expectedParametersClass {
  return [BZRRemoteContentFetcherParameters class];
}

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)init {
  BZRProductContentManager *contentManager =
      [[BZRProductContentManager alloc] initWithFileManager:[NSFileManager defaultManager]];
  return [self initWithFileManager:[NSFileManager defaultManager] contentManager:contentManager
                        HTTPClient:[FBRHTTPClient client]];
}

- (instancetype)initWithFileManager:(NSFileManager *)fileManager
                     contentManager:(BZRProductContentManager *)contentManager
                         HTTPClient:(FBRHTTPClient *)HTTPClient {
  if (self = [super init]) {
    _fileManager = fileManager;
    _contentManager = contentManager;
    _HTTPClient = HTTPClient;
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
         "%@, got product (%@) with parameters %@", [BZRRemoteContentFetcherParameters class],
         [self class], product.identifier, product.contentFetcherParameters];
    auto error = [NSError lt_errorWithCode:BZRErrorCodeInvalidContentFetcherParameters
                               description:@"%@", errorDescription];
    return [RACSignal error:error];
  }

  NSURL *URL = ((BZRRemoteContentFetcherParameters *)product.contentFetcherParameters).URL;
  if (![FBRHTTPRequest isProtocolSupported:URL]) {
    auto error = [NSError lt_errorWithCode:BZRErrorCodeInvalidContentFetcherParameters
                               description:@"Remote content fetcher supports only 'HTTPS' and "
                  "'HTTP' protocols. Got URL: %@", URL];
    return [RACSignal error:error];
  }

  NSString *contentFilename = [[URL absoluteString] lastPathComponent];
  LTPath *contentArchivePath = [LTPath pathWithBaseDirectory:LTPathBaseDirectoryTemp
                                             andRelativePath:contentFilename];

  auto downloadSignal = [self downloadFileSignalFrom:URL to:contentArchivePath];
  auto extractSignal =
      [[self.contentManager extractContentOfProduct:product.identifier
                                        fromArchive:contentArchivePath
                                      intoDirectory:[self contentDirectoryNameForProduct:product]]
       map:^BZRContentFetchingProgress *(NSBundle *bundle) {
         return [[LTProgress alloc] initWithResult:bundle];
       }];
  auto deleteArchiveSignal =
      [self.fileManager bzr_deleteItemAtPathIfExists:contentArchivePath.path];

  return [[RACSignal concat:@[downloadSignal, extractSignal, deleteArchiveSignal]]
          setNameWithFormat:@"%@ -fetchProductContent", self.description];
}

- (RACSignal<BZRContentFetchingProgress *> *)downloadFileSignalFrom:(NSURL *)sourceURL
                                                                 to:(LTPath *)targetPath {
  @weakify(self);
  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    @strongify(self);
    [[self.HTTPClient GET:sourceURL.absoluteString withParameters:nil headers:nil]
     subscribeNext:^(LTProgress<FBRHTTPResponse *> *progress) {
       if (!progress.result) {
         [subscriber sendNext:progress];
         return;
       }

       NSError *error;
       [self.fileManager lt_writeData:[NSData dataWithData:progress.result.content]
                               toFile:targetPath.path options:NSDataWritingAtomic
                                error:&error];
       if (error) {
         [subscriber sendError:error];
       } else {
         [subscriber sendCompleted];
       }
     } error:^(NSError *error) {
       [subscriber sendError:error];
     }];

    return nil;
  }];
}

- (NSString *)contentDirectoryNameForProduct:(BZRProduct *)product {
  NSURL *URL = ((BZRRemoteContentFetcherParameters *)product.contentFetcherParameters).URL;
  return [[[URL absoluteString] lastPathComponent] stringByDeletingPathExtension];
}

- (RACSignal<NSBundle *> *)contentBundleForProduct:(BZRProduct *)product {
  if (![product.contentFetcherParameters isKindOfClass:[[self class] expectedParametersClass]]) {
    return [RACSignal return:nil];
  }

  auto _Nullable contentPath = [self contentDirectoryPathOfProduct:product];
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
#pragma mark BZRRemoteContentFetcherParameters
#pragma mark -

@implementation BZRRemoteContentFetcherParameters

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return [[super JSONKeyPathsByPropertyKey] mtl_dictionaryByAddingEntriesFromDictionary:@{
    @instanceKeypath(BZRRemoteContentFetcherParameters, URL): @"URL"
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
