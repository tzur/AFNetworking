// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "BZRCompositeContentFetcher.h"

#import "BZRLocalContentFetcher.h"
#import "BZROnDemandContentFetcher.h"
#import "BZRProduct.h"
#import "BZRProductContentFetcher.h"
#import "BZRProductContentManager.h"
#import "BZRRemoteContentFetcher.h"
#import "NSErrorCodes+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRCompositeContentFetcher ()

/// Dictionary that maps content fetcher name to content fetcher class.
@property (readonly, nonatomic) BZRContentFetchersDictionary *contentFetchers;

@end

@implementation BZRCompositeContentFetcher

- (instancetype)init {
  BZRLocalContentFetcher *localContentFetcher = [[BZRLocalContentFetcher alloc] init];
  BZROnDemandContentFetcher *onDemandContentFetcher = [[BZROnDemandContentFetcher alloc] init];
  BZRRemoteContentFetcher *remoteContentFetcher = [[BZRRemoteContentFetcher alloc] init];

  return [self initWithContentFetchers:@{
    NSStringFromClass([localContentFetcher class]): localContentFetcher,
    NSStringFromClass([onDemandContentFetcher class]): onDemandContentFetcher,
    NSStringFromClass([remoteContentFetcher class]): remoteContentFetcher
  }];
}

- (instancetype)initWithContentFetchers:(BZRContentFetchersDictionary *)contentFetchers {
  if (self = [super init]) {
    _contentFetchers = contentFetchers;
  }
  return self;
}

- (RACSignal *)fetchProductContent:(BZRProduct *)product {
  id<BZRProductContentFetcher> contentFetcher =
      self.contentFetchers[product.contentFetcherParameters.type];

  if (!contentFetcher) {
    NSError *error = [NSError lt_errorWithCode:BZRErrorCodeProductContentFetcherNotRegistered
                                   description:@"Content fetcher of type %@ is not registered.",
                                               product.contentFetcherParameters.type];
    return [RACSignal error:error];
  }

  return [contentFetcher fetchProductContent:product];
}

- (RACSignal *)contentBundleForProduct:(BZRProduct *)product {
  return [self.contentFetchers[product.contentFetcherParameters.type]
          contentBundleForProduct:product];
}

@end

NS_ASSUME_NONNULL_END
