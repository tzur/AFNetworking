// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRCachedContentFetcher.h"

#import "BZRCompositeContentFetcher.h"
#import "BZRProduct.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRCachedContentFetcher ()

/// Underlying fetcher used to fetch content.
@property (readonly, nonatomic) id<BZRProductContentFetcher> underlyingContentFetcher;

@end

@implementation BZRCachedContentFetcher

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)init {
  return [self initWithUnderlyingContentFetcher:[[BZRCompositeContentFetcher alloc] init]];
}

- (instancetype)initWithUnderlyingContentFetcher:
    (id<BZRProductContentFetcher>)underlyingContentFetcher {
  if (self = [super init]) {
    _underlyingContentFetcher = underlyingContentFetcher;
  }

  return self;
}

#pragma mark -
#pragma mark BZREventEmitter
#pragma mark -

- (RACSignal<BZREvent *> *)eventsSignal {
  return self.underlyingContentFetcher.eventsSignal;
}

#pragma mark -
#pragma mark BZRProductContentFetcher
#pragma mark -

- (RACSignal<BZRContentFetchingProgress *> *)fetchProductContent:(BZRProduct *)product {
  return [[self contentBundleForProduct:product]
    flattenMap:^(NSBundle * _Nullable contentBundle) {
      return contentBundle ?
          [RACSignal return:[[LTProgress alloc] initWithResult:contentBundle]] :
          [self.underlyingContentFetcher fetchProductContent:product];
    }];
}

- (RACSignal<NSBundle *> *)contentBundleForProduct:(BZRProduct *)product {
  return [RACSignal defer:^{
    return [self.underlyingContentFetcher contentBundleForProduct:product];
  }];
}

@end

NS_ASSUME_NONNULL_END
