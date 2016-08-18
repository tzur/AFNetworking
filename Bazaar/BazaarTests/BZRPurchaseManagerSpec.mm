// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Hagai Weinfeld.

#import "BZRPurchaseManager.h"

#import "BZRFakePaymentTransaction.h"

/// Returns a mock \c SKPRoduct with the given \c identifier.
static id BZRMockProductWithIdentifier(NSString *identifier) {
  id product = OCMClassMock([SKProduct class]);
  OCMStub([product productIdentifier]).andReturn(identifier);
  return product;
}

/// Returns a \c BZRTransactionUpdateBlock that adds a copy of the \c SKPaymentTransactions updates
/// it receives to \c log.
static BZRTransactionUpdateBlock BZRUpdateBlockWithLog(NSMutableArray<BZRFakePaymentTransaction *> *log) {
  return ^(SKPaymentTransaction * _Nonnull transaction) {
    [log addObject:[transaction copy]];
  };
}

SpecBegin(BZRPurchaseManager)

__block id paymentQueue;
__block dispatch_queue_t updatesQueue;

beforeEach(^{
  paymentQueue = OCMClassMock([SKPaymentQueue class]);
  updatesQueue = dispatch_queue_create("com.lightricks.bazaar.test.purchaseManager.unhandled",
                                       DISPATCH_QUEUE_SERIAL);
});

context(@"initialization", ^{
  
  it(@"should initialize without application user identifier", ^{
    BZRPurchaseManager *purchaseManager =
        [[BZRPurchaseManager alloc] initWithPaymentQueue:paymentQueue
                                       applicationUserId:nil
                                   unhandledUpdatesBlock: ^(SKPaymentTransaction *){}
                                            updatesQueue:updatesQueue];
    expect(purchaseManager).toNot.beNil();
  });
  
  it(@"should initialize with application user identifier", ^{
    BZRPurchaseManager *purchaseManager =
        [[BZRPurchaseManager alloc] initWithPaymentQueue:paymentQueue
                                       applicationUserId:@"userID"
                                   unhandledUpdatesBlock: ^(SKPaymentTransaction *){}
                                            updatesQueue:updatesQueue];
    expect(purchaseManager).toNot.beNil();
  });
});

context(@"payment creation", ^{
  __block BZRPurchaseManager *purchaseManager;
  
  beforeEach(^{
    purchaseManager = [[BZRPurchaseManager alloc] initWithPaymentQueue:paymentQueue
                                                     applicationUserId:nil
                                                 unhandledUpdatesBlock: ^(SKPaymentTransaction *){}
                                                          updatesQueue:updatesQueue];
  });
  
  it(@"should add payment to queue when purchasing", ^{
    SKProduct *product =  BZRMockProductWithIdentifier(@"foo");
    SKPayment *payment = [SKPayment paymentWithProduct:product];
    OCMExpect([paymentQueue addPayment:payment]);
    [purchaseManager purchaseProduct:product quantity:1
                         updateBlock:^(SKPaymentTransaction *){}];
    OCMVerifyAllWithDelay(paymentQueue, 0.01);
  });
});

context(@"single payment update forwarding", ^{
  __block id<SKPaymentTransactionObserver> transactionObserver;
  __block NSMutableArray<BZRFakePaymentTransaction *> *unhandledTransactionsLog;
  __block BZRPurchaseManager *purchaseManager;
  __block NSMutableArray<BZRFakePaymentTransaction *> *updateLog;
  __block BZRTransactionUpdateBlock updateBlock;
  __block SKProduct *product;
  __block SKPayment *payment;
  
  beforeEach(^{
    OCMStub([paymentQueue addTransactionObserver:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
      __unsafe_unretained id<SKPaymentTransactionObserver> _transactionObserver;
      [invocation getArgument:&_transactionObserver atIndex:2];
      transactionObserver = _transactionObserver;
    });
    unhandledTransactionsLog = [[NSMutableArray alloc] init];
    purchaseManager = [[BZRPurchaseManager alloc] initWithPaymentQueue:paymentQueue
                                                     applicationUserId:nil
                                                 unhandledUpdatesBlock:
                           BZRUpdateBlockWithLog(unhandledTransactionsLog)
                                                          updatesQueue:updatesQueue];
    updateLog = [[NSMutableArray alloc] init];
    updateBlock = BZRUpdateBlockWithLog(updateLog);
    product = BZRMockProductWithIdentifier(@"foo");
    payment = [SKPayment paymentWithProduct:product];
  });
  
  it(@"should forward transaction updates for successfull payments", ^{
    [purchaseManager purchaseProduct:product quantity:1 updateBlock:updateBlock];
    
    BZRFakePaymentTransaction *transaction =
        [[BZRFakePaymentTransaction alloc] initWithPayment:payment];
    transaction.transactionState = SKPaymentTransactionStatePurchasing;
    [transactionObserver paymentQueue:paymentQueue updatedTransactions:@[transaction]];
    expect([updateLog lastObject]).will.equal(transaction);
    
    transaction.transactionState = SKPaymentTransactionStatePurchased;
    [transactionObserver paymentQueue:paymentQueue updatedTransactions:@[transaction]];
    expect([updateLog lastObject]).will.equal(transaction);
    expect([updateLog count]).will.equal(2);
    expect([unhandledTransactionsLog count]).will.equal(0);
  });
  
  it(@"should forward transaction updates for deferred payments", ^{
    [purchaseManager purchaseProduct:product quantity:1 updateBlock:updateBlock];
    
    BZRFakePaymentTransaction *transaction =
        [[BZRFakePaymentTransaction alloc] initWithPayment:payment];
    transaction.transactionState = SKPaymentTransactionStateDeferred;
    [transactionObserver paymentQueue:paymentQueue updatedTransactions:@[transaction]];
    expect([updateLog lastObject]).will.equal(transaction);
    
    transaction.transactionState = SKPaymentTransactionStateFailed;
    [transactionObserver paymentQueue:paymentQueue updatedTransactions:@[transaction]];
    expect([updateLog lastObject]).will.equal(transaction);
    expect([updateLog count]).will.equal(2);
    expect([unhandledTransactionsLog count]).will.equal(0);
  });
  
  it(@"should forward transaction updates for eventually failing payments", ^{
    [purchaseManager purchaseProduct:product quantity:1 updateBlock:updateBlock];
    
    BZRFakePaymentTransaction *transaction =
        [[BZRFakePaymentTransaction alloc] initWithPayment:payment];
    transaction.transactionState = SKPaymentTransactionStatePurchasing;
    [transactionObserver paymentQueue:paymentQueue updatedTransactions:@[transaction]];
    expect([updateLog lastObject]).will.equal(transaction);
    
    transaction.transactionState = SKPaymentTransactionStateFailed;
    [transactionObserver paymentQueue:paymentQueue updatedTransactions:@[transaction]];
    expect([updateLog lastObject]).will.equal(transaction);
    expect([updateLog count]).will.equal(2);
    expect([unhandledTransactionsLog count]).will.equal(0);
  });
  
  it(@"should forward transaction updates for immediately failing payments", ^{
    [purchaseManager purchaseProduct:product quantity:1 updateBlock:updateBlock];

    BZRFakePaymentTransaction *transaction =
        [[BZRFakePaymentTransaction alloc] initWithPayment:payment];
    transaction.transactionState = SKPaymentTransactionStateFailed;
    [transactionObserver paymentQueue:paymentQueue updatedTransactions:@[transaction]];
    expect([updateLog lastObject]).will.equal(transaction);
    expect([updateLog count]).will.equal(1);
    expect([unhandledTransactionsLog count]).will.equal(0);
  });
  
  it(@"should ignore restored transactions", ^{
    [purchaseManager purchaseProduct:product quantity:1 updateBlock:updateBlock];
    
    BZRFakePaymentTransaction *transaction =
        [[BZRFakePaymentTransaction alloc] initWithPayment:payment];
    transaction.transactionState = SKPaymentTransactionStateRestored;
    [transactionObserver paymentQueue:paymentQueue updatedTransactions:@[transaction]];
    expect([updateLog lastObject]).will.beNil();
    expect([updateLog count]).will.equal(0);
    expect([unhandledTransactionsLog count]).will.equal(0);
  });
  
  it(@"should forward purchased transactions as unhandled for existing payments if they got no \
     updates yet", ^{
    [purchaseManager purchaseProduct:product quantity:1 updateBlock:updateBlock];
    
    BZRFakePaymentTransaction *transaction =
      [[BZRFakePaymentTransaction alloc] initWithPayment:payment];
    transaction.transactionState = SKPaymentTransactionStatePurchased;
    [transactionObserver paymentQueue:paymentQueue updatedTransactions:@[transaction]];
    expect([updateLog lastObject]).will.beNil();
    expect([updateLog count]).will.equal(0);
    expect([unhandledTransactionsLog lastObject]).will.equal(transaction);
    expect([unhandledTransactionsLog count]).will.equal(1);
  });
  
  it(@"should forward purchasing transactions as unhandled if no matching payments exist", ^{
     BZRFakePaymentTransaction *transaction =
         [[BZRFakePaymentTransaction alloc] initWithPayment:payment];
     transaction.transactionState = SKPaymentTransactionStatePurchasing;
     [transactionObserver paymentQueue:paymentQueue updatedTransactions:@[transaction]];
     expect([updateLog lastObject]).will.beNil();
     expect([updateLog count]).will.equal(0);
     expect([unhandledTransactionsLog lastObject]).will.equal(transaction);
     expect([unhandledTransactionsLog count]).will.equal(1);
   });
  
  it(@"should forward deferred transactions as unhandled if no matching payments exist", ^{
    BZRFakePaymentTransaction *transaction =
        [[BZRFakePaymentTransaction alloc] initWithPayment:payment];
    transaction.transactionState = SKPaymentTransactionStateDeferred;
    [transactionObserver paymentQueue:paymentQueue updatedTransactions:@[transaction]];
    expect([updateLog lastObject]).will.beNil();
    expect([updateLog count]).will.equal(0);
    expect([unhandledTransactionsLog lastObject]).will.equal(transaction);
    expect([unhandledTransactionsLog count]).will.equal(1);
  });
  
  it(@"should forward purchased transactions as unhandled if no matching payments exist", ^{
    BZRFakePaymentTransaction *transaction =
        [[BZRFakePaymentTransaction alloc] initWithPayment:payment];
    transaction.transactionState = SKPaymentTransactionStatePurchased;
    [transactionObserver paymentQueue:paymentQueue updatedTransactions:@[transaction]];
    expect([unhandledTransactionsLog lastObject]).will.equal(transaction);
    expect([updateLog count]).will.equal(0);
    expect([unhandledTransactionsLog count]).will.equal(1);
  });
});

context(@"identical payments update forwarding", ^{
  __block id<SKPaymentTransactionObserver> transactionObserver;
  __block BZRPurchaseManager *purchaseManager;
  __block NSMutableArray<BZRFakePaymentTransaction *> *updateLog;
  __block BZRTransactionUpdateBlock updateBlock;
  __block NSMutableArray<BZRFakePaymentTransaction *> *otherUpdateLog;
  __block BZRTransactionUpdateBlock otherUpdateBlock;
  __block SKProduct *product;
  __block SKPayment *payment;
  __block SKPayment *otherPayment;
  
  beforeEach(^{
    OCMStub([paymentQueue addTransactionObserver:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
      __unsafe_unretained id<SKPaymentTransactionObserver> _transactionObserver;
      [invocation getArgument:&_transactionObserver atIndex:2];
      transactionObserver = _transactionObserver;
    });
    purchaseManager = [[BZRPurchaseManager alloc] initWithPaymentQueue:paymentQueue
                                                     applicationUserId:nil
                                                 unhandledUpdatesBlock: ^(SKPaymentTransaction *){}
                                                          updatesQueue:updatesQueue];
    updateLog = [[NSMutableArray alloc] init];
    updateBlock = BZRUpdateBlockWithLog(updateLog);
    otherUpdateLog = [[NSMutableArray alloc] init];
    otherUpdateBlock = BZRUpdateBlockWithLog(otherUpdateLog);
    product = BZRMockProductWithIdentifier(@"foo");
    payment = [SKPayment paymentWithProduct:product];
    otherPayment = [SKPayment paymentWithProduct:product];
  });
  
  it(@"should forward transaction updates correctly", ^{
    [purchaseManager purchaseProduct:product quantity:1 updateBlock:updateBlock];
    [purchaseManager purchaseProduct:product quantity:1 updateBlock:otherUpdateBlock];
    
    BZRFakePaymentTransaction *transaction =
        [[BZRFakePaymentTransaction alloc] initWithPayment:payment];
    BZRFakePaymentTransaction *otherTransaction =
        [[BZRFakePaymentTransaction alloc] initWithPayment:otherPayment];
    transaction.transactionState = SKPaymentTransactionStatePurchasing;
    otherTransaction.transactionState = SKPaymentTransactionStatePurchasing;
    
    [transactionObserver paymentQueue:paymentQueue
                  updatedTransactions:@[transaction]];
    expect([updateLog lastObject]).will.equal(transaction);
    [transactionObserver paymentQueue:paymentQueue
                  updatedTransactions:@[otherTransaction]];
    expect([otherUpdateLog lastObject]).will.equal(otherTransaction);
    
    transaction.transactionState = SKPaymentTransactionStatePurchased;
    otherTransaction.transactionState = SKPaymentTransactionStatePurchased;
    [transactionObserver paymentQueue:paymentQueue
                  updatedTransactions:@[transaction]];
    expect([updateLog lastObject]).will.equal(transaction);
    [transactionObserver paymentQueue:paymentQueue
                  updatedTransactions:@[otherTransaction]];
    expect([otherUpdateLog lastObject]).will.equal(otherTransaction);
  });
  
  it(@"should forward simultaneous transaction updates correctly", ^{
    [purchaseManager purchaseProduct:product quantity:1 updateBlock:updateBlock];
    [purchaseManager purchaseProduct:product quantity:1 updateBlock:otherUpdateBlock];
    
    BZRFakePaymentTransaction *transaction =
        [[BZRFakePaymentTransaction alloc] initWithPayment:payment];
    BZRFakePaymentTransaction *otherTransaction =
        [[BZRFakePaymentTransaction alloc] initWithPayment:otherPayment];
    transaction.transactionState = SKPaymentTransactionStatePurchasing;
    otherTransaction.transactionState = SKPaymentTransactionStatePurchasing;
    
    [transactionObserver paymentQueue:paymentQueue
                  updatedTransactions:@[transaction, otherTransaction]];
    expect([updateLog lastObject]).will.equal(transaction);
    expect([otherUpdateLog lastObject]).will.equal(otherTransaction);
    
    transaction.transactionState = SKPaymentTransactionStatePurchased;
    otherTransaction.transactionState = SKPaymentTransactionStatePurchased;
    [transactionObserver paymentQueue:paymentQueue
                  updatedTransactions:@[transaction, otherTransaction]];
    expect([updateLog lastObject]).will.equal(transaction);
    expect([otherUpdateLog lastObject]).will.equal(otherTransaction);
  });
  
  it(@"should forward simultaneous transaction updates when one payment fails", ^{
    [purchaseManager purchaseProduct:product quantity:1 updateBlock:updateBlock];
    [purchaseManager purchaseProduct:product quantity:1 updateBlock:otherUpdateBlock];
    
    BZRFakePaymentTransaction *transaction =
        [[BZRFakePaymentTransaction alloc] initWithPayment:payment];
    BZRFakePaymentTransaction *otherTransaction =
        [[BZRFakePaymentTransaction alloc] initWithPayment:otherPayment];
    transaction.transactionState = SKPaymentTransactionStatePurchasing;
    otherTransaction.transactionState = SKPaymentTransactionStatePurchasing;
    
    [transactionObserver paymentQueue:paymentQueue
                  updatedTransactions:@[transaction, otherTransaction]];
    expect([updateLog lastObject]).will.equal(transaction);
    expect([otherUpdateLog lastObject]).will.equal(otherTransaction);
    
    transaction.transactionState = SKPaymentTransactionStatePurchased;
    otherTransaction.transactionState = SKPaymentTransactionStateFailed;
    [transactionObserver paymentQueue:paymentQueue
                  updatedTransactions:@[transaction, otherTransaction]];
    expect([updateLog lastObject]).will.equal(transaction);
    expect([otherUpdateLog lastObject]).will.equal(otherTransaction);
  });
});

SpecEnd
