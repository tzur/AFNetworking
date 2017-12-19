// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRStoreKitFacade.h"

#import <LTKit/NSArray+Functional.h>

#import "BZREvent.h"
#import "BZRPaymentQueue.h"
#import "BZRProductDownloadManager.h"
#import "BZRPurchaseManager.h"
#import "BZRRequestStatusSignal.h"
#import "BZRStoreKitRequestsFactory.h"
#import "BZRTransactionRestorationManager.h"
#import "NSError+Bazaar.h"
#import "NSErrorCodes+Bazaar.h"
#import "SKProductsRequest+RACSignalSupport.h"
#import "SKReceiptRefreshRequest+RACSignalSupport.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRStoreKitFacade ()

/// Payment queue used to make purchases, restore purchase and download products content.
@property (readonly, nonatomic) BZRPaymentQueue *paymentQueue;

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

- (instancetype)initWithApplicationUserID:(nullable NSString *)applicationUserID {
  BZRPaymentQueue *paymentQueue = [[BZRPaymentQueue alloc] init];
  BZRPurchaseManager *purchaseManager =
      [[BZRPurchaseManager alloc] initWithPaymentQueue:paymentQueue
                                     applicationUserID:applicationUserID];
  BZRTransactionRestorationManager *restorationManager =
      [[BZRTransactionRestorationManager alloc] initWithPaymentQueue:paymentQueue
                                                   applicationUserID:applicationUserID];
  BZRProductDownloadManager *downloadManager =
      [[BZRProductDownloadManager alloc] initWithPaymentQueue:paymentQueue];
  BZRStoreKitRequestsFactory *storeKitRequestsFactory = [[BZRStoreKitRequestsFactory alloc] init];

  return [self initWithPaymentQueue:paymentQueue purchaseManager:purchaseManager
                 restorationManager:restorationManager downloadManager:downloadManager
            storeKitRequestsFactory:storeKitRequestsFactory];
}

- (instancetype)initWithPaymentQueue:(BZRPaymentQueue *)paymentQueue
                     purchaseManager:(BZRPurchaseManager *)purchaseManager
                  restorationManager:(BZRTransactionRestorationManager *)restorationManager
                     downloadManager:(BZRProductDownloadManager *)downloadManager
             storeKitRequestsFactory:(id<BZRStoreKitRequestsFactory>)storeKitRequestsFactory {
  if (self = [super init]) {
    _paymentQueue = paymentQueue;
    _purchaseManager = purchaseManager;
    _restorationManager = restorationManager;
    _downloadManager = downloadManager;
    _storeKitRequestsFactory = storeKitRequestsFactory;
    _eventsSignal = [paymentQueue.eventsSignal takeUntil:[self rac_willDeallocSignal]];

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
  [self.paymentQueue finishTransaction:transaction];
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
  return [[[self.paymentQueue.unfinishedTransactionsSignal
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
     self.paymentQueue.unfinishedTransactionsSignal],
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
