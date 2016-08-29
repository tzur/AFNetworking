// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRLocalContentFetcher.h"

#import "BZRLocalContentFetcherParameters.h"
#import "BZRProduct.h"
#import "NSErrorCodes+Bazaar.h"
#import "NSFileManager+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRLocalContentFetcher ()

/// Manager used to copy files from the given URL to temp folder.
@property (readonly, nonatomic) NSFileManager *fileManager;

@end

@implementation BZRLocalContentFetcher

- (instancetype)initWithFileManager:(NSFileManager *)fileManager {
  if (self = [super init]) {
    _fileManager = fileManager;
  }

  return self;
}

- (RACSignal *)fetchContentForProduct:(BZRProduct *)product {
  LTParameterAssert([product.contentFetcherParameters
                     isKindOfClass:[BZRLocalContentFetcher expectedParametersClass]],
                    @"The product's contentFetcherParameters must be of class %@, got %@",
                    [BZRLocalContentFetcher expectedParametersClass],
                    [product.contentFetcherParameters class]);
  NSURL *URL = ((BZRLocalContentFetcherParameters *)product.contentFetcherParameters).URL;
  LTParameterAssert([URL isFileURL], @"URL provided is not an address to a local file: %@", URL);

  NSString *contentFilename = [[URL absoluteString] lastPathComponent];
  LTPath *targetPath = [LTPath pathWithBaseDirectory:LTPathBaseDirectoryTemp
                                     andRelativePath:contentFilename];

  RACSignal *copySignal = [self createCopyFileSignalFrom:URL to:targetPath];
  return [[[self.fileManager bzr_deleteItemAtPathIfExists:targetPath.path] concat:copySignal]
      setNameWithFormat:@"%@ -fetchContentForProduct", self.description];
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
      [subscriber sendNext:targetPath];
      [subscriber sendCompleted];
    }
    return nil;
  }];
}

+ (Class)expectedParametersClass {
  return [BZRLocalContentFetcherParameters class];
}

@end

NS_ASSUME_NONNULL_END
