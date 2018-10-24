// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Hagai Weinfeld.

#import "BZRPurchaseManager.h"

#import "BZRFakePaymentTransaction.h"
#import "BZRPaymentsPaymentQueue.h"
#import "BZRPurchaseHelper.h"
#import "NSError+Bazaar.h"
#import "NSErrorCodes+Bazaar.h"

/// Returns a mock \c SKPRoduct with the given \c identifier.
static id BZRMockProductWithIdentifier(NSString *identifier) {
  id product = OCMClassMock([SKProduct class]);
  OCMStub([product productIdentifier]).andReturn(identifier);
  return product;
}

/// Fake \c BZRPaymentsPaymentQueue, used to inspect which payment was called with \c addPayment.
@interface BZRFakePaymentsPaymentQueue : NSObject <BZRPaymentsPaymentQueue>

/// Payment expected to be called with \c addPayment
@property (strong, nonatomic, nullable) SKPayment *expectedPaymentForAddPayment;

@end

@implementation BZRFakePaymentsPaymentQueue

@synthesize paymentsDelegate = _paymentsDelegate;

- (void)addPayment:(SKPayment *)payment {
  if (self.expectedPaymentForAddPayment) {
    expect(payment).to.equal(self.expectedPaymentForAddPayment);
  }
}

@end

@interface BZRPurchaseManager () <BZRPaymentQueuePaymentsDelegate>
@end

SpecBegin(BZRPurchaseManager)

__block BZRFakePaymentsPaymentQueue *paymentQueue;
__block id<BZRPurchaseHelper> purchaseHelper;
__block SKProduct *product;
__block SKPayment *payment;
__block BZRFakePaymentTransaction *transaction;

beforeEach(^{
  paymentQueue = [[BZRFakePaymentsPaymentQueue alloc] init];
  purchaseHelper = OCMProtocolMock(@protocol(BZRPurchaseHelper));
  product =  BZRMockProductWithIdentifier(@"foo");
  payment = [SKPayment paymentWithProduct:product];
  transaction = [[BZRFakePaymentTransaction alloc] initWithPayment:payment];
});

context(@"initialization", ^{
  it(@"should initialize without application user identifier", ^{
    BZRPurchaseManager *purchaseManager =
        [[BZRPurchaseManager alloc] initWithPaymentQueue:paymentQueue applicationUserID:nil
                                          purchaseHelper:purchaseHelper];
    expect(purchaseManager).toNot.beNil();
  });

  it(@"should initialize with application user identifier", ^{
    BZRPurchaseManager *purchaseManager =
        [[BZRPurchaseManager alloc] initWithPaymentQueue:paymentQueue applicationUserID:@"userID"
                                          purchaseHelper:purchaseHelper];
    expect(purchaseManager).toNot.beNil();
  });
});

context(@"deallocating object", ^{
  it(@"should complete when object is deallocated", ^{
    BZRPurchaseManager __weak *weakPurchaseManager;
    LLSignalTestRecorder *recorder;

    transaction.transactionState = SKPaymentTransactionStatePurchasing;

    @autoreleasepool {
      BZRPurchaseManager *purchaseManager =
          [[BZRPurchaseManager alloc] initWithPaymentQueue:paymentQueue applicationUserID:nil
                                            purchaseHelper:purchaseHelper];
      weakPurchaseManager = purchaseManager;

      recorder = [[purchaseManager purchaseProduct:product quantity:1] testRecorder];
      [purchaseManager paymentQueue:paymentQueue paymentTransactionsUpdated:@[transaction]];
    }

    expect(weakPurchaseManager).to.beNil();
    expect(recorder).will.complete();
  });
});

context(@"payment creation", ^{
  it(@"should add payment to queue with correct userID when purchasing", ^{
    SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:product];
    payment.quantity = 1337;
    payment.applicationUsername = @"foo";
    paymentQueue.expectedPaymentForAddPayment = payment;

    BZRPurchaseManager *purchaseManager =
        [[BZRPurchaseManager alloc] initWithPaymentQueue:paymentQueue
                                       applicationUserID:payment.applicationUsername
                                          purchaseHelper:purchaseHelper];

    [[purchaseManager purchaseProduct:product quantity:payment.quantity] testRecorder];
  });
});

context(@"promoted IAP", ^{
  it(@"should propagate the decision whether to proceed with promoted purchase or not to the "
     "helper", ^{
    BZRPurchaseManager *purchaseManager =
        [[BZRPurchaseManager alloc] initWithPaymentQueue:paymentQueue applicationUserID:nil
                                          purchaseHelper:purchaseHelper];
    OCMExpect([purchaseHelper shouldProceedWithPurchase:payment]).andReturn(YES);
    OCMExpect([purchaseHelper shouldProceedWithPurchase:payment]).andReturn(NO);

    expect([purchaseManager shouldProceedWithPromotedIAP:product payment:payment]).to.beTruthy();
    expect([purchaseManager shouldProceedWithPromotedIAP:product payment:payment]).to.beFalsy();
  });
});

context(@"payment update forwarding", ^{
  __block BZRPurchaseManager *purchaseManager;
  __block LLSignalTestRecorder *unhandledTransactionsRecorder;

  beforeEach(^{
    purchaseManager =
        [[BZRPurchaseManager alloc] initWithPaymentQueue:paymentQueue applicationUserID:nil
                                          purchaseHelper:purchaseHelper];
    unhandledTransactionsRecorder = [purchaseManager.unhandledTransactionsSignal testRecorder];
  });

  it(@"should forward updated transactions as unhandled if no purchase was requested", ^{
    transaction.transactionState = SKPaymentTransactionStatePurchasing;
    [purchaseManager paymentQueue:paymentQueue paymentTransactionsUpdated:@[transaction]];
    transaction.transactionState = SKPaymentTransactionStateDeferred;
    [purchaseManager paymentQueue:paymentQueue paymentTransactionsUpdated:@[transaction]];
    transaction.transactionState = SKPaymentTransactionStatePurchased;
    [purchaseManager paymentQueue:paymentQueue paymentTransactionsUpdated:@[transaction]];
    transaction.transactionState = SKPaymentTransactionStateFailed;
    [purchaseManager paymentQueue:paymentQueue paymentTransactionsUpdated:@[transaction]];

    expect(unhandledTransactionsRecorder).will
        .sendValues(@[@[transaction], @[transaction], @[transaction], @[transaction]]);
  });

  it(@"should send unhandled transactions when new subscriber subscribes", ^{
    transaction.transactionState = SKPaymentTransactionStatePurchasing;
    [purchaseManager paymentQueue:paymentQueue paymentTransactionsUpdated:@[transaction]];
    transaction.transactionState = SKPaymentTransactionStateDeferred;
    [purchaseManager paymentQueue:paymentQueue paymentTransactionsUpdated:@[transaction]];
    transaction.transactionState = SKPaymentTransactionStatePurchased;
    [purchaseManager paymentQueue:paymentQueue paymentTransactionsUpdated:@[transaction]];
    transaction.transactionState = SKPaymentTransactionStateFailed;
    [purchaseManager paymentQueue:paymentQueue paymentTransactionsUpdated:@[transaction]];

    expect([purchaseManager.unhandledTransactionsSignal testRecorder]).will
        .sendValues(@[@[transaction], @[transaction], @[transaction], @[transaction]]);
  });

  it(@"should not forward removed transactions as unhandled if no purchase was requested", ^{
    transaction.transactionState = SKPaymentTransactionStatePurchased;
    [purchaseManager paymentQueue:paymentQueue paymentTransactionsRemoved:@[transaction]];
    transaction.transactionState = SKPaymentTransactionStateFailed;
    [purchaseManager paymentQueue:paymentQueue paymentTransactionsRemoved:@[transaction]];

    purchaseManager = nil;
    expect(unhandledTransactionsRecorder).will.complete();
    expect(unhandledTransactionsRecorder).will.sendValuesWithCount(0);
  });

  context(@"purchase was requested", ^{
    __block LLSignalTestRecorder *recorder;

    beforeEach(^{
      recorder = [[purchaseManager purchaseProduct:product quantity:1] testRecorder];
    });

    it(@"should not send updates for removed transaction without update first", ^{
      transaction.transactionState = SKPaymentTransactionStatePurchased;
      [purchaseManager paymentQueue:paymentQueue paymentTransactionsRemoved:@[transaction]];

      purchaseManager = nil;
      expect(recorder).will.complete();
      expect(unhandledTransactionsRecorder).will.complete();
      expect(recorder).will.sendValuesWithCount(0);
      expect(unhandledTransactionsRecorder).will.sendValuesWithCount(0);
    });

    it(@"should send transaction updates for successful payments", ^{
      transaction.transactionState = SKPaymentTransactionStatePurchasing;
      [purchaseManager paymentQueue:paymentQueue paymentTransactionsUpdated:@[transaction]];
      transaction.transactionState = SKPaymentTransactionStateDeferred;
      [purchaseManager paymentQueue:paymentQueue paymentTransactionsUpdated:@[transaction]];
      transaction.transactionState = SKPaymentTransactionStatePurchased;
      [purchaseManager paymentQueue:paymentQueue paymentTransactionsUpdated:@[transaction]];
      [purchaseManager paymentQueue:paymentQueue paymentTransactionsRemoved:@[transaction]];

      purchaseManager = nil;
      expect(recorder).will.complete();
      expect(recorder).will.sendValues(@[transaction, transaction, transaction]);
      expect(unhandledTransactionsRecorder).will.complete();
      expect(unhandledTransactionsRecorder).will.sendValuesWithCount(0);
    });

    it(@"should err for failed payment", ^{
      transaction.transactionState = SKPaymentTransactionStateFailed;
      transaction.error = [NSError lt_errorWithCode:1337];
      [purchaseManager paymentQueue:paymentQueue paymentTransactionsUpdated:@[transaction]];

      expect(recorder).will.matchError(^BOOL(NSError *error) {
        return error.lt_isLTDomain && error.code == BZRErrorCodePurchaseFailed &&
            [error.bzr_transaction isEqual:transaction] &&
            error.lt_underlyingError == transaction.error;
      });
      purchaseManager = nil;
      expect(unhandledTransactionsRecorder).will.complete();
      expect(unhandledTransactionsRecorder).will.sendValuesWithCount(0);
    });

    it(@"should send purchase cancelled for transaction with cancelled error code", ^{
      transaction.transactionState = SKPaymentTransactionStateFailed;
      transaction.error = [NSError errorWithDomain:SKErrorDomain code:SKErrorPaymentCancelled
                                          userInfo:@{}];
      [purchaseManager paymentQueue:paymentQueue paymentTransactionsUpdated:@[transaction]];

      expect(recorder).will.matchError(^BOOL(NSError *error) {
        return error.lt_isLTDomain && error.code == BZRErrorCodeOperationCancelled &&
            [error.bzr_transaction isEqual:transaction] &&
            error.lt_underlyingError == transaction.error;
      });
      purchaseManager = nil;
      expect(unhandledTransactionsRecorder).will.complete();
      expect(unhandledTransactionsRecorder).will.sendValuesWithCount(0);
    });

    it(@"should send purchase not allowed for transaction with not allowed error code", ^{
      transaction.transactionState = SKPaymentTransactionStateFailed;
      transaction.error = [NSError errorWithDomain:SKErrorDomain code:SKErrorPaymentNotAllowed
                                          userInfo:@{}];
      [purchaseManager paymentQueue:paymentQueue paymentTransactionsUpdated:@[transaction]];

      expect(recorder).will.matchError(^BOOL(NSError *error) {
        return error.lt_isLTDomain && error.code == BZRErrorCodePurchaseNotAllowed &&
            [error.bzr_transaction isEqual:transaction] &&
            error.lt_underlyingError == transaction.error;
      });
      purchaseManager = nil;
      expect(unhandledTransactionsRecorder).will.complete();
      expect(unhandledTransactionsRecorder).will.sendValuesWithCount(0);
    });

    it(@"should forward restored purchased and deferred transactions to unhandled transaction if "
       "purchasing transaction wasn't called before", ^{
      transaction.transactionState = SKPaymentTransactionStateRestored;
      [purchaseManager paymentQueue:paymentQueue paymentTransactionsUpdated:@[transaction]];
      transaction.transactionState = SKPaymentTransactionStatePurchased;
      [purchaseManager paymentQueue:paymentQueue paymentTransactionsUpdated:@[transaction]];
      transaction.transactionState = SKPaymentTransactionStateDeferred;
      [purchaseManager paymentQueue:paymentQueue paymentTransactionsUpdated:@[transaction]];
      transaction.transactionState = SKPaymentTransactionStatePurchasing;
      [purchaseManager paymentQueue:paymentQueue paymentTransactionsUpdated:@[transaction]];
         transaction.transactionState = SKPaymentTransactionStatePurchased;
      [purchaseManager paymentQueue:paymentQueue paymentTransactionsRemoved:@[transaction]];

      expect(recorder).will.complete();
      expect(recorder).will.sendValues(@[transaction]);
      expect(unhandledTransactionsRecorder).will
         .sendValues(@[@[transaction], @[transaction], @[transaction]]);
    });

    context(@"identical payments update forwarding", ^{
      __block SKPayment *otherPayment;
      __block BZRFakePaymentTransaction *otherTransaction;

      beforeEach(^{
        otherPayment = [SKPayment paymentWithProduct:product];
        otherTransaction = [[BZRFakePaymentTransaction alloc] initWithPayment:otherPayment];
      });

      it(@"should forward second transaction to unhandled when only one purchase was requested", ^{
        transaction.transactionState = SKPaymentTransactionStatePurchasing;
        otherTransaction.transactionState = SKPaymentTransactionStateFailed;

        [purchaseManager paymentQueue:paymentQueue paymentTransactionsUpdated:@[transaction]];
        expect(recorder).will.sendValues(@[transaction]);
        [purchaseManager paymentQueue:paymentQueue paymentTransactionsUpdated:@[otherTransaction]];
        expect(unhandledTransactionsRecorder).will.sendValues(@[@[otherTransaction]]);
      });

      context(@"two purchases requested", ^{
        __block LLSignalTestRecorder *otherRecorder;

        beforeEach(^{
          otherRecorder = [[purchaseManager purchaseProduct:product quantity:1] testRecorder];
        });

        it(@"should forward transaction updates correctly", ^{
          transaction.transactionState = SKPaymentTransactionStatePurchasing;
          otherTransaction.transactionState = SKPaymentTransactionStatePurchasing;

          [purchaseManager paymentQueue:paymentQueue paymentTransactionsUpdated:@[transaction]];
          expect(recorder).will.sendValues(@[transaction]);
          [purchaseManager paymentQueue:paymentQueue
             paymentTransactionsUpdated:@[otherTransaction]];
          expect(otherRecorder).will.sendValues(@[otherTransaction]);

          transaction.transactionState = SKPaymentTransactionStatePurchased;
          [purchaseManager paymentQueue:paymentQueue paymentTransactionsUpdated:@[transaction]];
          expect(recorder).will.sendValues(@[transaction, transaction]);
          otherTransaction.transactionState = SKPaymentTransactionStateDeferred;
          [purchaseManager paymentQueue:paymentQueue
             paymentTransactionsUpdated:@[otherTransaction]];
          expect(otherRecorder).will.sendValues(@[otherTransaction, otherTransaction]);
        });

        it(@"should forward transactions updates correctly when one payment completes", ^{
          transaction.transactionState = SKPaymentTransactionStatePurchasing;
          otherTransaction.transactionState = SKPaymentTransactionStatePurchasing;

          [purchaseManager paymentQueue:paymentQueue
             paymentTransactionsUpdated:@[transaction, otherTransaction]];

          otherTransaction.transactionState = SKPaymentTransactionStatePurchased;
          [purchaseManager paymentQueue:paymentQueue paymentTransactionsRemoved:@[transaction]];
          expect(recorder).will.complete();
          expect(recorder).will.sendValues(@[transaction]);
          expect(otherRecorder).will.sendValues(@[otherTransaction]);
        });

        it(@"should forward simultaneous transaction updates correctly", ^{
          transaction.transactionState = SKPaymentTransactionStatePurchasing;
          otherTransaction.transactionState = SKPaymentTransactionStatePurchasing;
          [purchaseManager paymentQueue:paymentQueue
             paymentTransactionsUpdated:@[transaction, otherTransaction]];
          expect(recorder).will.sendValues(@[transaction]);
          expect(otherRecorder).will.sendValues(@[otherTransaction]);

          transaction.transactionState = SKPaymentTransactionStatePurchased;
          otherTransaction.transactionState = SKPaymentTransactionStateRestored;
          otherTransaction.error = [NSError lt_errorWithCode:1337];
          [purchaseManager paymentQueue:paymentQueue
             paymentTransactionsUpdated:@[transaction, otherTransaction]];
          expect(recorder).will.sendValues(@[transaction, transaction]);
          expect(otherRecorder).will.sendValues(@[otherTransaction, otherTransaction]);
        });

        it(@"should forward simultaneous transaction updates when one payment fails", ^{
          transaction.transactionState = SKPaymentTransactionStatePurchasing;
          otherTransaction.transactionState = SKPaymentTransactionStateFailed;
          otherTransaction.error = [NSError lt_errorWithCode:1337];

          [purchaseManager paymentQueue:paymentQueue
             paymentTransactionsUpdated:@[transaction, otherTransaction]];
          expect(recorder).will.sendValues(@[transaction]);
          expect(otherRecorder).will.matchError(^BOOL(NSError *error) {
            return error.lt_isLTDomain && error.code == BZRErrorCodePurchaseFailed &&
                [error.bzr_transaction isEqual:otherTransaction] &&
                error.lt_underlyingError == otherTransaction.error;
          });
        });

        it(@"should forward simultaneous transactions removals correctly", ^{
          transaction.transactionState = SKPaymentTransactionStatePurchasing;
          otherTransaction.transactionState = SKPaymentTransactionStatePurchasing;
          [purchaseManager paymentQueue:paymentQueue
              paymentTransactionsUpdated:@[transaction, otherTransaction]];

          transaction.transactionState = SKPaymentTransactionStatePurchased;
          otherTransaction.transactionState = SKPaymentTransactionStatePurchased;
          [purchaseManager paymentQueue:paymentQueue
              paymentTransactionsRemoved:@[transaction, otherTransaction]];

          expect(recorder).will.complete();
          expect(otherRecorder).will.complete();
        });
      });
    });
  });
});

SpecEnd
