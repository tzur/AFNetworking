// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Hagai Weinfeld.

#import "BZRPurchaseManager.h"

#import "BZRPurchase.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRPurchaseManager () <SKPaymentTransactionObserver>

/// StoreKit payment queue used to make purchases and restore transactions.
@property (readonly, nonatomic) SKPaymentQueue *paymentQueue;

/// Block used to deliver \c SKPaymentTransactions for payments that were not initiated and are
/// ignored by this \c BZRPurchaseManager instance.
@property (readonly, nonatomic) BZRTransactionUpdateBlock unhandledUpdatesBlock;

/// Application username to use in payments.
@property (readonly, nonatomic) NSString *applicationUserId;

/// Purchases for which no transaction updates have arrived.
@property (readonly, nonatomic) NSMutableArray<BZRPurchase *> *pendingPurchases;

/// Maps \c SKPaymentTransactions that are currently being processed to their corresponding
/// \c SKPurchase.
@property (readonly, nonatomic)
    NSMapTable<SKPaymentTransaction *, BZRPurchase *> *mapTransactionToPurchase;

/// Queue used for accessing \c pendingPurchases and \c mapTransactionToPurchase.
@property (readonly, nonatomic) dispatch_queue_t paymentDataAccessQueue;

/// Queue used when calling \c unhandledUpdatesBlock or an \c updateBlock of a \c BZRPurchase.
@property (readonly, nonatomic) dispatch_queue_t updatesQueue;

@end

@implementation BZRPurchaseManager

- (instancetype)initWithPaymentQueue:(SKPaymentQueue *)paymentQueue
                   applicationUserId:(nullable NSString *)applicationUserId
               unhandledUpdatesBlock:(BZRTransactionUpdateBlock)unhandledUpdatesBlock
                        updatesQueue:(dispatch_queue_t)updatesQueue {
  LTParameterAssert(paymentQueue, @"paymentQueue can't be nil");
  LTParameterAssert(unhandledUpdatesBlock, @"unhandledUpdatesBlock can't be nil");
  
  if (self = [super init]) {
    _paymentQueue = paymentQueue;
    _unhandledUpdatesBlock = unhandledUpdatesBlock;
    _applicationUserId = [applicationUserId copy];
    _pendingPurchases = [[NSMutableArray alloc] init];
    _mapTransactionToPurchase =
        [NSMapTable mapTableWithKeyOptions:NSMapTableObjectPointerPersonality
                              valueOptions:NSMapTableStrongMemory];
    _paymentDataAccessQueue =
        dispatch_queue_create("com.lightricks.bazaar.purchaseManager", DISPATCH_QUEUE_SERIAL);
    _updatesQueue = updatesQueue;
    [paymentQueue addTransactionObserver:self];
  }
  return self;
}

- (void)purchaseProduct:(SKProduct *)product quantity:(NSUInteger)quantity
            updateBlock:(BZRTransactionUpdateBlock)updateBlock {
  SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:product];
  payment.quantity = quantity;
  payment.applicationUsername = self.applicationUserId;
  BZRPurchase *purchase = [[BZRPurchase alloc] initWithPayment:payment updateBlock:updateBlock];
  dispatch_async(self.paymentDataAccessQueue, ^{
    [self.pendingPurchases addObject:purchase];
    [self.paymentQueue addPayment:payment];
  });
}

- (void)paymentQueue:(SKPaymentQueue __unused *)queue
 updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions {
  dispatch_async(self.paymentDataAccessQueue, ^{
    for (SKPaymentTransaction *transaction in transactions) {
      if (transaction.transactionState == SKPaymentTransactionStateRestored) {
        continue;
      }

      BZRPurchase *purchase = [self.mapTransactionToPurchase objectForKey:transaction];
      if (!purchase && transaction.transactionState != SKPaymentTransactionStatePurchased) {
        purchase = [self popPurchaseFromPurchases:self.pendingPurchases forTransaction:transaction];
      }
      
      if (!purchase) {
        dispatch_async(self.updatesQueue, ^{
          self.unhandledUpdatesBlock(transaction);
        });
        continue;
      }
      
      dispatch_async(self.updatesQueue, ^{
        purchase.updateBlock(transaction);
      });
      [self removeTransactionIfCompleted:transaction];
    }
  });
}

- (void)removeTransactionIfCompleted:(SKPaymentTransaction *)transaction {
  if (transaction.transactionState == SKPaymentTransactionStateFailed ||
      transaction.transactionState == SKPaymentTransactionStatePurchased) {
    [self.mapTransactionToPurchase removeObjectForKey:transaction];
  }
}

- (nullable BZRPurchase *)popPurchaseFromPurchases:(NSMutableArray<BZRPurchase *> *)purchases
                                    forTransaction:(SKPaymentTransaction *)transaction {
  BZRPurchase *purchase = [self purchaseInPurchases:purchases forTransaction:transaction];
  if (purchase) {
    [purchases removeObject:purchase];
    [self.mapTransactionToPurchase setObject:purchase forKey:transaction];
  }
  return purchase;
}

- (nullable BZRPurchase *)purchaseInPurchases:(NSArray<BZRPurchase *> *)purchases
                               forTransaction:(SKPaymentTransaction *)transaction {
  for (BZRPurchase *purchase in purchases) {
    if ([purchase.payment isEqual:transaction.payment]) {
      return purchase;
    }
  }
  return nil;
}

- (void)dealloc {
  [self.paymentQueue removeTransactionObserver:self];
}

@end

NS_ASSUME_NONNULL_END
