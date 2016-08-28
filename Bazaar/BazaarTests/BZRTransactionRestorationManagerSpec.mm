// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRTransactionRestorationManager.h"

#import "BZRRestorationPaymentQueue.h"

@interface BZRTransactionRestorationManager () <BZRPaymentQueueRestorationDelegate>
@end

/// Fake \c BZRFakeRestorationPaymentQueue that enables inspecting whether certain methods were
/// called.
@interface BZRFakeRestorationPaymentQueue : NSObject <BZRRestorationPaymentQueue>

/// \c YES if \c -[self restoreCompletedTransactions] was called, \c NO otherwise.
@property (readonly, nonatomic) BOOL wasRestoreCompletedTransactionsCalled;

/// \c username with which \c -[self restoreCompletedTransactionsWithApplicationUsername:]
/// was called. \c nil if
/// \c -[self restoreCompletedTransactionsWithApplicationUsername:] was never called or was called
/// with \c username equal to \c nil.
@property (readonly, nonatomic, nullable) NSString *restoreCompletedTransactionsCalledWithUsername;

@end

@implementation BZRFakeRestorationPaymentQueue

@synthesize restorationDelegate = _restorationDelegate;

- (void)restoreCompletedTransactions {
  _wasRestoreCompletedTransactionsCalled = YES;
}

- (void)restoreCompletedTransactionsWithApplicationUsername:(nullable NSString *)username {
  _restoreCompletedTransactionsCalledWithUsername = username;
}

@end

SpecBegin(BZRTransactionRestorationManager)

__block BZRFakeRestorationPaymentQueue *paymentQueue;

beforeEach(^{
  paymentQueue = [[BZRFakeRestorationPaymentQueue alloc] init];
});

context(@"deallocating object", ^{
  it(@"should complete when object is deallocated", ^{
    BZRTransactionRestorationManager __weak *weakRestorationManager;

    @autoreleasepool {
      BZRTransactionRestorationManager *restorationManager =
          [[BZRTransactionRestorationManager alloc] initWithPaymentQueue:paymentQueue];
      weakRestorationManager = restorationManager;
      [restorationManager restoreCompletedTransactions];
    }

    expect(weakRestorationManager).to.beNil();
  });
});

context(@"restoring completed transactions", ^{
  __block BZRTransactionRestorationManager *restorationManager;

  beforeEach(^{
    restorationManager =
        [[BZRTransactionRestorationManager alloc] initWithPaymentQueue:paymentQueue];
  });

  it(@"should call restore completed transactions", ^{
    LLSignalTestRecorder *recorder =
        [[restorationManager restoreCompletedTransactions] testRecorder];
    [restorationManager paymentQueueRestorationCompleted:paymentQueue];

    expect(recorder).will.complete();
    expect(paymentQueue.wasRestoreCompletedTransactionsCalled).to.beTruthy();
  });

  it(@"should call restore completed transactions with correct application user ID", ^{
    NSString *username = @"foo";
    LLSignalTestRecorder *recorder =
        [[restorationManager restoreCompletedTransactionsWithApplicationUserID:username]
        testRecorder];
    [restorationManager paymentQueueRestorationCompleted:paymentQueue];

    expect(recorder).will.complete();
    expect(paymentQueue.restoreCompletedTransactionsCalledWithUsername).to.equal(username);
  });

  it(@"should err when restoration failed", ^{
    LLSignalTestRecorder *recorder =
        [[restorationManager restoreCompletedTransactions] testRecorder];
    NSError *error = OCMClassMock([NSError class]);
    [restorationManager paymentQueue:paymentQueue restorationFailedWithError:error];

    expect(recorder).will.sendError(error);
  });

  it(@"should send completed transactions one by one", ^{
    LLSignalTestRecorder *recorder =
        [[restorationManager restoreCompletedTransactions] testRecorder];
    SKPaymentTransaction *firstTransaction = OCMClassMock([SKPaymentTransaction class]);
    SKPaymentTransaction *secondTransaction = OCMClassMock([SKPaymentTransaction class]);
    SKPaymentTransaction *thirdTransaction = OCMClassMock([SKPaymentTransaction class]);

    [restorationManager paymentQueue:paymentQueue
                transactionsRestored:@[firstTransaction, secondTransaction, thirdTransaction]];
    [restorationManager paymentQueueRestorationCompleted:paymentQueue];

    expect(recorder).will.complete();
    expect(recorder).will.sendValues(@[firstTransaction, secondTransaction, thirdTransaction]);
  });
});

SpecEnd
