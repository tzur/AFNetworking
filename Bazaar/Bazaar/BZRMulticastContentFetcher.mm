// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "BZRMulticastContentFetcher.h"

#import "BZRProduct.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRMulticastContentFetcher ()

/// Underlying fetcher used to fetch content.
@property (readonly, nonatomic) id<BZRProductContentFetcher> underlyingContentFetcher;

/// Dictionary that maps between product identifier to a signal that fetches the content of that
/// product. Contains only products whose fetch is in progress. Products that their content
/// is already available will not appear in this dictionary.
@property (strong, nonatomic) NSDictionary<NSString *, RACSignal *>
    *contentFetchingInProgressSignals;

@end

@implementation BZRMulticastContentFetcher

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithUnderlyingContentFetcher:
    (id<BZRProductContentFetcher>)underlyingContentFetcher {
  if (self = [super init]) {
    _underlyingContentFetcher = underlyingContentFetcher;
    _contentFetchingInProgressSignals = @{};
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
  @weakify(self);
  auto fetchingFinishedBlock = ^{
    @strongify(self);
    @synchronized (self) {
      self.contentFetchingInProgressSignals =
          [self.contentFetchingInProgressSignals
           mtl_dictionaryByRemovingEntriesWithKeys:[NSSet setWithObject:product.identifier]];
    }
  };

  @synchronized (self) {
    if (!self.contentFetchingInProgressSignals[product.identifier]) {
      auto fetchingProgressSignal =
          [[[[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
            @strongify(self);
            auto underlyingDisposable =
                [[self.underlyingContentFetcher fetchProductContent:product] subscribe:subscriber];

            return [RACCompoundDisposable compoundDisposableWithDisposables:@[
              underlyingDisposable,
              [RACDisposable disposableWithBlock:fetchingFinishedBlock]
            ]];
          }]
          publish]
          autoconnect]
          finally:fetchingFinishedBlock];

      self.contentFetchingInProgressSignals =
          [self.contentFetchingInProgressSignals mtl_dictionaryByAddingEntriesFromDictionary:@{
            product.identifier: fetchingProgressSignal
          }];
    }
  }

  return self.contentFetchingInProgressSignals[product.identifier];
}

- (RACSignal *)contentBundleForProduct:(BZRProduct *)product {
  return [self.underlyingContentFetcher contentBundleForProduct:product];
}

@end

NS_ASSUME_NONNULL_END
