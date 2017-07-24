// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "BZRCompositeContentFetcher.h"

#import <LTKit/NSArray+Functional.h>

#import "BZREvent.h"
#import "BZRFallbackContentFetcher.h"
#import "BZRLocalContentFetcher.h"
#import "BZRMulticastContentFetcher.h"
#import "BZROnDemandContentFetcher.h"
#import "BZRProduct.h"
#import "BZRProductContentFetcher.h"
#import "BZRRemoteContentFetcher.h"
#import "BZRRetryContentFetcher.h"
#import "NSError+Bazaar.h"
#import "NSErrorCodes+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRCompositeContentFetcher ()

/// Dictionary that maps content fetcher name to content fetcher class.
@property (readonly, nonatomic) BZRContentFetchersDictionary *contentFetchers;

/// Subject used to send events with.
@property (readonly, nonatomic) RACSubject *eventsSubject;

@end

@implementation BZRCompositeContentFetcher

@synthesize eventsSignal = _eventsSignal;

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)init {
  auto localContentFetcher = [[BZRLocalContentFetcher alloc] init];
  auto onDemandContentFetcher = [[BZROnDemandContentFetcher alloc] init];
  auto remoteContentFetcher = [[BZRRemoteContentFetcher alloc] init];
  auto mutlicastRemoteContentFetcher =
      [[BZRMulticastContentFetcher alloc] initWithUnderlyingContentFetcher:
       [[BZRRetryContentFetcher alloc] initWithUnderlyingContentFetcher:remoteContentFetcher]];
  auto fallbackContentFetcher =
      [[BZRFallbackContentFetcher alloc] initWithCompositeContentFetcher:self];

  // Note: Any changes made to the fetchers dictionary directly affect existing apps that use \c
  // BZRCompositeContentFetcher and requires careful verification. Providing product list with wrong
  // parameters names or wrong format is detectable only in runtime and some of these errors may be
  // silently ignored in runtime and will be hard to detect.
  return [self initWithContentFetchers:@{
    NSStringFromClass([BZRLocalContentFetcher class]): localContentFetcher,
    NSStringFromClass([BZROnDemandContentFetcher class]): onDemandContentFetcher,
    NSStringFromClass([BZRRemoteContentFetcher class]): mutlicastRemoteContentFetcher,
    NSStringFromClass([BZRFallbackContentFetcher class]): fallbackContentFetcher
  }];
}

#pragma mark -
#pragma mark BZRProductContentFetcher
#pragma mark -

- (instancetype)initWithContentFetchers:(BZRContentFetchersDictionary *)contentFetchers {
  if (self = [super init]) {
    _contentFetchers = contentFetchers;
    _eventsSubject = [RACSubject subject];
    [self initializeEventsSignal];
  }
  return self;
}

- (void)initializeEventsSignal {
  auto underlyingFetchersEventsSignals = [[self.contentFetchers allValues]
      lt_map:^RACSignal *(id<BZRProductContentFetcher> contentFetcher) {
        return contentFetcher.eventsSignal;
      }];

  _eventsSignal = [[RACSignal
      merge:[underlyingFetchersEventsSignals arrayByAddingObject:self.eventsSubject]]
      takeUntil:[self rac_willDeallocSignal]];
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

  return [[contentFetcher fetchProductContent:product]
      doError:^(NSError *underlyingError) {
        auto error = [NSError bzr_errorWithContentFetcherParameters:product.contentFetcherParameters
                                                    underlyingError:underlyingError];
        [self.eventsSubject sendNext:
         [[BZREvent alloc] initWithType:$(BZREventTypeNonCriticalError)
                             eventError:error]];
      }];
}

- (RACSignal *)contentBundleForProduct:(BZRProduct *)product {
  id<BZRProductContentFetcher> contentFetcher =
      self.contentFetchers[product.contentFetcherParameters.type];

  if (!contentFetcher) {
    NSError *error = [NSError lt_errorWithCode:BZRErrorCodeProductContentFetcherNotRegistered
                                   description:@"Content fetcher of type %@ is not registered.",
                                               product.contentFetcherParameters.type];
    return [RACSignal error:error];
  }

  return [self.contentFetchers[product.contentFetcherParameters.type]
          contentBundleForProduct:product];
}

@end

NS_ASSUME_NONNULL_END
