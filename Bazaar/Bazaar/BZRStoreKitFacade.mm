// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRStoreKitFacade.h"

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

- (instancetype)initWithUnfinishedTransactionsSubject:(RACSubject *)unfinishedTransactionsSubject
                                    applicationUserID:(nullable NSString *)applicationUserID {
  BZRPaymentQueue *paymentQueue =
      [[BZRPaymentQueue alloc] initWithUnfinishedTransactionsSubject:unfinishedTransactionsSubject];
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
  }
  return self;
}

#pragma mark -
#pragma mark Public Interface
#pragma mark -

- (RACSignal *)fetchMetadataForProductsWithIdentifiers:(NSSet<NSString *> *)productIdentifiers {
  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    SKProductsRequest *request =
        [self.storeKitRequestsFactory productsRequestWithIdentifiers:productIdentifiers];
    [[request bzr_statusSignal] subscribe:subscriber];
    [request start];
    return [RACDisposable disposableWithBlock:^{
      [request cancel];
    }];
  }];
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

- (RACSignal *)unhandledTransactionsErrorsSignal {
  return [self.purchaseManager.unhandledTransactionsSignal
      map:^id(SKPaymentTransaction *transaction) {
        return [NSError bzr_errorWithCode:BZRErrorCodeUnhandledTransactionReceived
                              transaction:transaction];
      }];
}

@end

NS_ASSUME_NONNULL_END
