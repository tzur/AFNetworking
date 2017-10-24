// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRTransactionRestorationManager.h"

#import "BZRRestorationPaymentQueue.h"
#import "NSErrorCodes+Bazaar.h"

@interface BZRTransactionRestorationManager () <BZRPaymentQueueRestorationDelegate>
@end

/// Fake \c BZRFakeRestorationPaymentQueue that enables inspecting whether certain methods were
/// called.
@interface BZRFakeRestorationPaymentQueue : NSObject <BZRRestorationPaymentQueue>

/// \c username with which \c -[self restoreCompletedTransactionsWithApplicationUsername:]
/// was called. \c nil if
/// \c -[self restoreCompletedTransactionsWithApplicationUsername:] was never called or was called
/// with \c username equal to \c nil.
@property (readonly, nonatomic, nullable) NSString *restoreCompletedTransactionsCalledWithUsername;

@end

@implementation BZRFakeRestorationPaymentQueue

@synthesize restorationDelegate = _restorationDelegate;

- (void)restoreCompletedTransactionsWithApplicationUserID:(nullable NSString *)applicationUserID {
  _restoreCompletedTransactionsCalledWithUsername = applicationUserID;
}

@end

SpecBegin(BZRTransactionRestorationManager)

__block BZRFakeRestorationPaymentQueue *paymentQueue;
__block NSString *applicationUserID;

beforeEach(^{
  paymentQueue = [[BZRFakeRestorationPaymentQueue alloc] init];
  applicationUserID = @"foo";
});

context(@"deallocating object", ^{
  it(@"should complete when object is deallocated", ^{
    BZRTransactionRestorationManager __weak *weakRestorationManager;

    @autoreleasepool {
      BZRTransactionRestorationManager *restorationManager =
          [[BZRTransactionRestorationManager alloc] initWithPaymentQueue:paymentQueue
                                                       applicationUserID:applicationUserID];
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
        [[BZRTransactionRestorationManager alloc] initWithPaymentQueue:paymentQueue
                                                     applicationUserID:applicationUserID];
  });

  it(@"should call restore completed transactions with correct application user ID", ^{
    LLSignalTestRecorder *recorder =
        [[restorationManager restoreCompletedTransactions] testRecorder];
    [restorationManager paymentQueueRestorationCompleted:paymentQueue];

    expect(recorder).will.complete();
    expect(paymentQueue.restoreCompletedTransactionsCalledWithUsername).to.equal(applicationUserID);
  });

  it(@"should err when restoration failed", ^{
    LLSignalTestRecorder *recorder =
        [[restorationManager restoreCompletedTransactions] testRecorder];
    NSError *restorePurchasesError = [NSError lt_errorWithCode:1337];
    [restorationManager paymentQueue:paymentQueue restorationFailedWithError:restorePurchasesError];

    expect(recorder).will.matchError(^BOOL(NSError *error) {
      return error.code == BZRErrorCodeRestorePurchasesFailed &&
          error.lt_underlyingError == restorePurchasesError;
    });
  });

  it(@"should err with operation cancelled when restore purchases was cancelled", ^{
    LLSignalTestRecorder *recorder =
        [[restorationManager restoreCompletedTransactions] testRecorder];
    NSError *restorePurchasesError =
        [NSError errorWithDomain:SKErrorDomain code:SKErrorPaymentCancelled userInfo:nil];
    [restorationManager paymentQueue:paymentQueue restorationFailedWithError:restorePurchasesError];

    expect(recorder).will.matchError(^BOOL(NSError *error) {
      return error.code == BZRErrorCodeOperationCancelled &&
          error.lt_underlyingError == restorePurchasesError;
    });
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
