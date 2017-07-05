// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "BZRCompositeContentFetcher.h"

#import "BZRLocalContentFetcher.h"
#import "BZRMulticastContentFetcher.h"
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
  auto localContentFetcher = [[BZRLocalContentFetcher alloc] init];
  auto onDemandContentFetcher = [[BZROnDemandContentFetcher alloc] init];
  auto remoteContentFetcher = [[BZRRemoteContentFetcher alloc] init];
  auto mutlicastRemoteContentFetcher =
      [[BZRMulticastContentFetcher alloc] initWithUnderlyingContentFetcher:remoteContentFetcher];

  // Note: Any changes made to the fetchers dictionary directly affect existing apps that use \c
  // BZRCompositeContentFetcher and requires careful verification. Providing product list with wrong
  // parameters names or wrong format is detectable only in runtime and some of these errors may be
  // silently ignored in runtime and will be hard to detect.
  return [self initWithContentFetchers:@{
    NSStringFromClass([BZRLocalContentFetcher class]): localContentFetcher,
    NSStringFromClass([BZROnDemandContentFetcher class]): onDemandContentFetcher,
    NSStringFromClass([BZRRemoteContentFetcher class]): mutlicastRemoteContentFetcher
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
