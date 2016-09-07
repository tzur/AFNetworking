// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRProductContentProvider.h"

#import "BZRProduct.h"
#import "BZRProductContentFetcher.h"
#import "BZRProductContentManager.h"
#import "NSErrorCodes+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRProductContentProvider ()

/// Fetcher used to fetch content.
@property (readonly, nonatomic) id<BZRProductContentFetcher> contentFetcher;

/// Manager used to extract content from an archive file.
@property (readonly, nonatomic) BZRProductContentManager *contentManager;

@end

@implementation BZRProductContentProvider

- (instancetype)initWithContentFetcher:(id<BZRProductContentFetcher>)contentFetcher
                        contentManager:(BZRProductContentManager *)contentManager {
  if (self = [super init]) {
    _contentFetcher = contentFetcher;
    _contentManager = contentManager;
  }
  return self;
}

- (RACSignal *)fetchProductContent:(BZRProduct *)product {
  @weakify(self);
  return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    @strongify(self);
    if (!product.contentFetcherParameters) {
      [subscriber sendCompleted];
      return nil;
    }
    LTPath *pathToContent =
        [self.contentManager pathToContentDirectoryOfProduct:product.identifier];
    [subscriber sendNext:pathToContent];
    [subscriber sendCompleted];
    return nil;
  }]
  flattenMap:^RACStream *(LTPath * _Nullable pathToContent) {
    @strongify(self);
    if (pathToContent) {
      return [RACSignal return:pathToContent];
    }
    return [[self.contentFetcher fetchContentForProduct:product]
        flattenMap:^RACSignal *(LTPath *contentArchivePath) {
          return [self.contentManager extractContentOfProduct:product.identifier
                                                  fromArchive:contentArchivePath];
     }];
  }];
}

@end

NS_ASSUME_NONNULL_END
