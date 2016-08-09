// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRLocalContentProvider.h"

#import "BZRLocalContentProviderParameters.h"
#import "BZRProduct.h"
#import "NSErrorCodes+Bazaar.h"
#import "NSFileManager+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRLocalContentProvider ()

/// Manager used to copy files from the given URL to temp folder.
@property (readonly, nonatomic) NSFileManager *fileManager;

@end

@implementation BZRLocalContentProvider

- (instancetype)initWithFileManager:(NSFileManager *)fileManager {
  if (self = [super init]) {
    _fileManager = fileManager;
  }

  return self;
}

- (RACSignal *)fetchContentForProduct:(BZRProduct *)product {
  LTParameterAssert([product.contentProviderParameters
                     isKindOfClass:[BZRLocalContentProvider expectedParametersClass]],
                    @"The product's contentProviderParameters must be of class %@, got %@",
                    [BZRLocalContentProvider expectedParametersClass],
                    [product.contentProviderParameters class]);
  NSURL *URL = ((BZRLocalContentProviderParameters *)product.contentProviderParameters).URL;
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
      NSError *copyContentError = [NSError lt_errorWithCode:BZErrorCodeCopyProductContentFailed
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
  return [BZRLocalContentProviderParameters class];
}

@end

NS_ASSUME_NONNULL_END
