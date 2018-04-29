// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRStoreKitFacade.h"

#import <LTKit/NSArray+Functional.h>

#import "BZREvent.h"
#import "BZRPaymentQueueAdapter.h"
#import "BZRProductDownloadManager.h"
#import "BZRPurchaseHelper.h"
#import "BZRPurchaseManager.h"
#import "BZRRequestStatusSignal.h"
#import "BZRStoreKitRequestsFactory.h"
#import "BZRTransactionRestorationManager.h"
#import "NSError+Bazaar.h"
#import "NSErrorCodes+Bazaar.h"
#import "SKPaymentQueue+Bazaar.h"
#import "SKProductsRequest+RACSignalSupport.h"
#import "SKReceiptRefreshRequest+RACSignalSupport.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRStoreKitFacade ()

/// Payment queue used to make purchases, restore purchase and download products content.
@property (readonly, nonatomic) BZRPaymentQueueAdapter *paymentQueueAdapter;

/// Purchase manager used to make in-app purchases.
@property (readonly, nonatomic) BZRPurchaseManager *purchaseManager;

/// Restoration manager used to restore completed transactions.
@property (readonly, nonatomic) BZRTransactionRestorationManager *restorationManager;

/// Download manager used to download content for products.
@property (readonly, nonatomic) BZRProductDownloadManager *downloadManager;

/// Factory used to create StoreKit's requests.
@property (readonly, nonatomic) id<BZRStoreKitRequestsFactory> storeKitRequestsFactory;

@end

@implementation BZRStoreKitFacade

@synthesize eventsSignal = _eventsSignal;

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithApplicationUserID:(nullable NSString *)applicationUserID
    purchaseHelper:(id<BZRPurchaseHelper>)purchaseHelper {
  BZRPaymentQueueAdapter *paymentQueueAdapter =
      [[BZRPaymentQueueAdapter alloc] initWithPaymentQueue:[SKPaymentQueue defaultQueue]];
  BZRPurchaseManager *purchaseManager =
      [[BZRPurchaseManager alloc] initWithPaymentQueue:paymentQueueAdapter
                                     applicationUserID:applicationUserID
                                        purchaseHelper:purchaseHelper];
  BZRTransactionRestorationManager *restorationManager =
      [[BZRTransactionRestorationManager alloc] initWithPaymentQueue:paymentQueueAdapter
                                                   applicationUserID:applicationUserID];
  BZRProductDownloadManager *downloadManager =
      [[BZRProductDownloadManager alloc] initWithPaymentQueue:paymentQueueAdapter];
  BZRStoreKitRequestsFactory *storeKitRequestsFactory = [[BZRStoreKitRequestsFactory alloc] init];

  return [self initWithPaymentQueueAdapter:paymentQueueAdapter purchaseManager:purchaseManager
                        restorationManager:restorationManager downloadManager:downloadManager
                   storeKitRequestsFactory:storeKitRequestsFactory];
}

- (instancetype)initWithPaymentQueueAdapter:(BZRPaymentQueueAdapter *)paymentQueueAdapter
    purchaseManager:(BZRPurchaseManager *)purchaseManager
    restorationManager:(BZRTransactionRestorationManager *)restorationManager
    downloadManager:(BZRProductDownloadManager *)downloadManager
    storeKitRequestsFactory:(id<BZRStoreKitRequestsFactory>)storeKitRequestsFactory {
  if (self = [super init]) {
    _paymentQueueAdapter = paymentQueueAdapter;
    _purchaseManager = purchaseManager;
    _restorationManager = restorationManager;
    _downloadManager = downloadManager;
    _storeKitRequestsFactory = storeKitRequestsFactory;
    _eventsSignal = [paymentQueueAdapter.eventsSignal takeUntil:[self rac_willDeallocSignal]];

    [self finishFailedTransactions];
  }
  return self;
}

#pragma mark -
#pragma mark Public Interface
#pragma mark -

/// Block used to create an \c SKRequest object that conforms to \c BZRRequestStatusSignal protocol.
typedef SKRequest<BZRRequestStatusSignal> *(^BZRRequestFactoryBlock)();

- (RACSignal<SKProductsResponse *> *)
    fetchMetadataForProductsWithIdentifiers:(NSSet<NSString *> *)productIdentifiers {
  auto requestFactoryBlock = ^SKRequest<BZRRequestStatusSignal> *() {
    return [self.storeKitRequestsFactory productsRequestWithIdentifiers:productIdentifiers];
  };

  // Values sent by \c SKProductsRequest's \c bzr_statusSignal are delivered on the main thread.
  // If Bazaar does additional calculations later it might affect the UI. Therefore, the values are
  // delivered on a background scheduler.
  return [[BZRStoreKitFacade requestSignalWithRequestFactoryBlock:requestFactoryBlock]
      deliverOn:[RACScheduler scheduler]];
}

- (RACSignal<SKPaymentTransaction *> *)purchaseProduct:(SKProduct *)product {
  return [self.purchaseManager purchaseProduct:product quantity:1];
}

- (RACSignal<SKPaymentTransaction *> *)purchaseConsumableProduct:(SKProduct *)product
                                                        quantity:(NSUInteger)quantity {
  return [self.purchaseManager purchaseProduct:product quantity:quantity];
}

- (NSArray<RACSignal<SKDownload *> *> *)
    downloadContentForTransaction:(SKPaymentTransaction *)transaction {
  return [self.downloadManager downloadContentForTransaction:transaction];
}

- (RACSignal<SKPaymentTransaction *> *)restoreCompletedTransactions {
  return [self.restorationManager restoreCompletedTransactions];
}

- (RACSignal *)refreshReceipt {
  auto requestFactoryBlock = ^SKRequest<BZRRequestStatusSignal> *() {
    return [self.storeKitRequestsFactory receiptRefreshRequest];
  };

  return [BZRStoreKitFacade requestSignalWithRequestFactoryBlock:requestFactoryBlock];
}

- (void)finishTransaction:(SKPaymentTransaction *)transaction {
  [self.paymentQueueAdapter finishTransaction:transaction];
}

+ (RACSignal *)requestSignalWithRequestFactoryBlock:(BZRRequestFactoryBlock)requestFactoryBlock {
  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    auto request = requestFactoryBlock();

    __block BOOL didSignalFinish = NO;
    auto disposable = [[[request statusSignal]
        finally:^{
          @synchronized(request) {
            didSignalFinish = YES;
          }
        }]
        subscribe:subscriber];

    [request start];
    auto cancellationDisposable = [RACDisposable disposableWithBlock:^{
      // This code prevents the request from being cancelled after it has completed or erred in most
      // cases. There is still a case where the signal is disposed of at the same time the request
      // finishes, and the request is still cancelled. The correct solution is that invoking
      // `cancel` would not crash after the reqest completes or errs.
      @synchronized (request) {
        if (!didSignalFinish) {
          [request cancel];
        }
      }
    }];

    return [RACCompoundDisposable compoundDisposableWithDisposables:@[
      disposable,
      cancellationDisposable
    ]];
  }];
}

- (NSArray<SKPaymentTransaction *> *)transactions {
  return self.paymentQueueAdapter.transactions;
}

#pragma mark -
#pragma mark Handling transactions errors
#pragma mark -

- (RACSignal<BZREvent *> *)transactionsErrorEventsSignal {
  return [[[RACSignal merge:@[
    [self unfinishedFailedTransactionsErrors],
    [self unhandledTransactionsErrors]
  ]]
  takeUntil:[self rac_willDeallocSignal]]
  setNameWithFormat:@"%@ -transactionsErrorsSignal", self];
}

- (RACSignal<BZREvent *> *)unhandledTransactionsErrors {
  return [[self.purchaseManager.unhandledTransactionsSignal
      flattenMap:^(BZRPaymentTransactionList *transactionList) {
        return [transactionList.rac_sequence signalWithScheduler:[RACScheduler immediateScheduler]];
      }]
      map:^BZREvent *(SKPaymentTransaction *transaction) {
        return [[BZREvent alloc]
                initWithType:$(BZREventTypeNonCriticalError)
                eventError:[NSError bzr_errorWithCode:BZRErrorCodeUnhandledTransactionReceived
                                          transaction:transaction]];
      }];
}

- (RACSignal<BZREvent *> *)unfinishedFailedTransactionsErrors {
  return [[[self.paymentQueueAdapter.unfinishedTransactionsSignal
      flattenMap:^(BZRPaymentTransactionList *transaction) {
        return [transaction.rac_sequence signalWithScheduler:[RACScheduler immediateScheduler]];
      }]
      filter:^BOOL(SKPaymentTransaction *transaction) {
        return transaction.transactionState == SKPaymentTransactionStateFailed;
      }]
      map:^BZREvent *(SKPaymentTransaction *transaction) {
        return [[BZREvent alloc] initWithType:$(BZREventTypeCriticalError)
                                   eventError:[NSError bzr_errorWithCode:BZRErrorCodePurchaseFailed
                                                             transaction:transaction]];
      }];
}

#pragma mark -
#pragma mark Handling unfinished transactions
#pragma mark -

- (void)finishFailedTransactions {
  @weakify(self);
  [[self unfinishedFailedTransactionsErrors] subscribeNext:^(BZREvent *event) {
    @strongify(self);
    [self finishTransaction:event.eventError.bzr_transaction];
  }];
}

- (RACSignal<BZRPaymentTransactionList *> *)unhandledSuccessfulTransactionsSignal {
  return [[RACSignal merge:@[
    [self successfulTransactionsFromTransactionsSignal:
     self.paymentQueueAdapter.unfinishedTransactionsSignal],
    [self successfulTransactionsFromTransactionsSignal:
     self.purchaseManager.unhandledTransactionsSignal]
  ]]
  takeUntil:[self rac_willDeallocSignal]];
}

- (RACSignal<BZRPaymentTransactionList *> *)successfulTransactionsFromTransactionsSignal:
    (RACSignal<BZRPaymentTransactionList *> *)transactionsSignal {
  return [transactionsSignal
      map:^BZRPaymentTransactionList *(BZRPaymentTransactionList *transactions) {
        return [transactions lt_filter:^BOOL(SKPaymentTransaction *transaction) {
          return transaction.transactionState == SKPaymentTransactionStatePurchased ||
              transaction.transactionState == SKPaymentTransactionStateRestored;
        }];
      }];
}

@end

NS_ASSUME_NONNULL_END
