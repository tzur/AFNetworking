// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRCachedProductsProvider.h"

#import "BZRProduct.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRCachedProductsProvider ()

/// Provider used to provide the list of products.
@property (readonly, nonatomic) id<BZRProductsProvider> underlyingProvider;

/// List of \c BZRProduct fetched using \c underlyingProvider.
@property (strong, atomic, nullable) BZRProductList *productList;

/// Flag indicating whether product list fetch is currently in progress or not.
@property (atomic) BOOL productListFetchInProgress;

/// Scheduler used to sychronize \c fetchProductList between multiple threads.
@property (readonly, nonatomic) RACTargetQueueScheduler *fetchingScheduler;

@end

@implementation BZRCachedProductsProvider

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithUnderlyingProvider:(id<BZRProductsProvider>)underlyingProvider {
  if (self = [super init]) {
    _underlyingProvider = underlyingProvider;

    const char *kProductListFetchingQueueName =
        "com.lightricks.bazaar.cachedProductsProvider.fetchProductList";
    dispatch_queue_t productListFetchingQueue =
        dispatch_queue_create(kProductListFetchingQueueName, DISPATCH_QUEUE_SERIAL);
    _fetchingScheduler = [[RACTargetQueueScheduler alloc]
                          initWithName:[NSString stringWithUTF8String:kProductListFetchingQueueName]
                          targetQueue:productListFetchingQueue];
  }
  return self;
}

#pragma mark -
#pragma mark BZRProductsProvider
#pragma mark -

- (RACSignal<BZRProductList *> *)fetchProductList {
  @weakify(self);
  return [[RACSignal defer:^RACSignal<BZRProductList *> *{
    @strongify(self);
    if (self.productListFetchInProgress) {
      return [[self waitForFetchToComplete] then:^{
        @strongify(self);
        return [self productListSignal];
      }];
    } else {
      return [self productListSignal];
    }
  }]
  subscribeOn:self.fetchingScheduler];
}

- (RACSignal<BZRProductList *> *)productListSignal {
  return self.productList ? [RACSignal return:self.productList] : [self fetchProductListInternal];
}

- (RACSignal<NSNumber *> *)waitForFetchToComplete {
  return [[[RACObserve(self, productListFetchInProgress)
      ignore:@YES]
      take:1]
      deliverOn:self.fetchingScheduler];
}

- (RACSignal<BZRProductList *> *)fetchProductListInternal {
  self.productListFetchInProgress = YES;

  @weakify(self);
  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    @strongify(self);
    RACDisposable *fetchDisposable = [[[[[self.underlyingProvider fetchProductList]
        doNext:^(BZRProductList *productList) {
          @strongify(self);
          self.productList = productList;
        }]
        doCompleted:^{
          @strongify(self);
          self.productListFetchInProgress = NO;
        }]
        doError:^(NSError *) {
          @strongify(self);
          self.productListFetchInProgress = NO;
        }]
        subscribe:subscriber];

    RACDisposable *disposable = [RACDisposable disposableWithBlock:^{
      @strongify(self);
      self.productListFetchInProgress = NO;
    }];

    RACCompoundDisposable *compoundDisposable =
        [RACCompoundDisposable compoundDisposableWithDisposables:
         fetchDisposable ? @[disposable, fetchDisposable] : @[disposable]];
    return compoundDisposable;
  }];
}

- (RACSignal<BZREvent *> *)eventsSignal {
  return self.underlyingProvider.eventsSignal;
}

@end

NS_ASSUME_NONNULL_END
