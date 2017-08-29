// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "BZRRetryContentFetcher.h"

#import "RACSignal+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRRetryContentFetcher ()

/// Underlying fetcher used to fetch content.
@property (readonly, nonatomic) id<BZRProductContentFetcher> underlyingContentFetcher;

/// Number of additional retries after the first fetching failure.
@property (readonly, nonatomic) NSUInteger numberOfRetries;

/// Seconds to wait between the first and second tries.
@property (readonly, nonatomic) NSTimeInterval initialDelay;

@end

@implementation BZRRetryContentFetcher

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithUnderlyingContentFetcher:
    (id<BZRProductContentFetcher>)underlyingContentFetcher {
  return [self initWithUnderlyingContentFetcher:underlyingContentFetcher numberOfRetries:4
                                   initialDelay:5];
}

- (instancetype)initWithUnderlyingContentFetcher:
    (id<BZRProductContentFetcher>)underlyingContentFetcher
    numberOfRetries:(NSUInteger)numberOfRetries initialDelay:(NSTimeInterval)initialDelay {
  if (self = [super init]) {
    _underlyingContentFetcher = underlyingContentFetcher;
    _numberOfRetries = numberOfRetries;
    _initialDelay = initialDelay;
  }

  return self;
}

#pragma mark -
#pragma mark BZREventEmitter
#pragma mark -

- (RACSignal *)eventsSignal {
  return self.underlyingContentFetcher.eventsSignal;
}

#pragma mark -
#pragma mark BZRProductContentFetcher
#pragma mark -

- (RACSignal *)fetchProductContent:(BZRProduct *)product {
  return [[self.underlyingContentFetcher fetchProductContent:product]
          bzr_delayedRetry:self.numberOfRetries
          initialDelay:self.initialDelay];
}

- (RACSignal *)contentBundleForProduct:(BZRProduct *)product {
  return [self.underlyingContentFetcher contentBundleForProduct:product];
}

@end

NS_ASSUME_NONNULL_END
