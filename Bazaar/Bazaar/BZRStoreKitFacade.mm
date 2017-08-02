// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRStoreKitFacade.h"

#import <LTKit/NSArray+Functional.h>

#import "BZREvent.h"
#import "BZRPaymentQueue.h"
#import "BZRProductDownloadManager.h"
#import "BZRPurchaseManager.h"
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

    [self finishFailedTransactions];
  }
  return self;
}

#pragma mark -
#pragma mark Public Interface
#pragma mark -

- (RACSignal *)fetchMetadataForProductsWithIdentifiers:(NSSet<NSString *> *)productIdentifiers {
  // Values sent by \c SKProductsRequest's \c bzr_statusSignal are delivered on the main thread.
  // If Bazaar does additional calculations later it might affect the UI. Therefore, the values are
  // delivered on a background scheduler.
  return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    SKProductsRequest *request =
        [self.storeKitRequestsFactory productsRequestWithIdentifiers:productIdentifiers];
    [[request bzr_statusSignal] subscribe:subscriber];
    [request start];
    return [RACDisposable disposableWithBlock:^{
      [request cancel];
    }];
  }]
  deliverOn:[RACScheduler scheduler]];
}

- (RACSignal *)purchaseProduct:(SKProduct *)product {
  return [self.purchaseManager purchaseProduct:product quantity:1];
}

- (RACSignal *)purchaseConsumableProduct:(SKProduct *)product quantity:(NSUInteger)quantity {
  return [self.purchaseManager purchaseProduct:product quantity:quantity];
}

- (NSArray<RACSignal *> *)downloadContentForTransaction:(SKPaymentTransaction *)transaction {
  return [self.downloadManager downloadContentForTransaction:transaction];
}

- (RACSignal *)restoreCompletedTransactions {
  return [self.restorationManager restoreCompletedTransactions];
}

- (RACSignal *)refreshReceipt {
  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    SKReceiptRefreshRequest *request = [self.storeKitRequestsFactory receiptRefreshRequest];
    [[request bzr_statusSignal] subscribe:subscriber];
    [request start];
    return [RACDisposable disposableWithBlock:^{
      [request cancel];
    }];
  }];
}

- (void)finishTransaction:(SKPaymentTransaction *)transaction {
  [self.paymentQueue finishTransaction:transaction];
}

#pragma mark -
#pragma mark Handling transactions errors
#pragma mark -

- (RACSignal *)transactionsErrorEventsSignal {
  return [[[RACSignal merge:@[
    [self unfinishedFailedTransactionsErrors],
    [self unhandledTransactionsErrors]
  ]]
  takeUntil:[self rac_willDeallocSignal]]
  setNameWithFormat:@"%@ -transactionsErrorsSignal", self];
}

- (RACSignal *)unhandledTransactionsErrors {
  return [self.purchaseManager.unhandledTransactionsSignal
      map:^BZREvent *(SKPaymentTransaction *transaction) {
        return [[BZREvent alloc]
                initWithType:$(BZREventTypeNonCriticalError)
                eventError:[NSError bzr_errorWithCode:BZRErrorCodeUnhandledTransactionReceived
                                          transaction:transaction]];
      }];
}

- (RACSignal *)unfinishedFailedTransactionsErrors {
  return [[[self.paymentQueue.unfinishedTransactionsSignal
      flattenMap:^RACSignal *(NSArray<SKPaymentTransaction *> *transaction) {
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

- (RACSignal *)unfinishedSuccessfulTransactionsSignal {
    return [self.paymentQueue.unfinishedTransactionsSignal
        map:^NSArray<SKPaymentTransaction *> *(NSArray<SKPaymentTransaction *> *transactions) {
          return [transactions lt_filter:^BOOL(SKPaymentTransaction *transaction) {
            return transaction.transactionState == SKPaymentTransactionStatePurchased ||
                transaction.transactionState == SKPaymentTransactionStateRestored;
          }];
        }];
}

@end

NS_ASSUME_NONNULL_END
