// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "NSError+Bazaar.h"

#import <LTKit/NSError+LTKit.h>

#import "BZRFakePaymentTransaction.h"
#import "NSErrorCodes+Bazaar.h"

/// Category that adds method for getting a description of the transaction.
@interface SKPaymentTransaction (Bazaar)

/// Returns a description of the transaction with some of its proerties.
- (NSString *)bzr_description;

@end

SpecBegin(NSError_Bazaar)

context(@"error with exception", ^{
  __block NSException *exception;
  __block NSError *error;

  beforeEach(^{
    exception = [NSException exceptionWithName:@"Foo" reason:@"Bar" userInfo:@{}];
    error = [NSError bzr_errorWithCode:1337 exception:exception];
  });

  it(@"should initialize a new error with the given exception", ^{
    expect(error.bzr_exception).to.equal(exception);
  });

  it(@"should initialize the error with LTKit error domain", ^{
    expect(error.code).to.equal(1337);
  });

  it(@"should initialize the error with the given error code", ^{
    expect(error.lt_isLTDomain).to.beTruthy();
  });
});

context(@"error with products request", ^{
  it(@"should return an error with the specified request and underlying error", ^{
    SKProductsRequest *request = OCMClassMock([SKProductsRequest class]);
    NSError *underlyingError = [NSError lt_errorWithCode:1];
    NSError *error = [NSError bzr_errorWithCode:1337 productsRequest:request
                                underlyingError:underlyingError];

    expect(error.lt_isLTDomain).to.beTruthy();
    expect(error.code).to.equal(1337);
    expect(error.bzr_productsRequest).to.equal(request);
    expect(error.lt_underlyingError).to.equal(underlyingError);
  });
});

context(@"archiving error", ^{
  it(@"should return an error with the specified archive path", ^{
    NSString *archivePath = @"/foo/bar";
    NSError *error = [NSError bzr_errorWithCode:1337 archivePath:archivePath
                         failingArchiveItemPath:nil underlyingError:nil description:nil];

    expect(error).toNot.beNil();
    expect(error.lt_isLTDomain).to.beTruthy();
    expect(error.code).to.equal(1337);
    expect(error.bzr_archivePath).to.equal(archivePath);
  });

  it(@"should return an error with the specified optional parameters", ^{
    NSString *archivePath = @"/foo/bar";
    NSString *failingItem = @"baz";
    NSError *underlyingError = [NSError lt_errorWithCode:1];
    NSString *description = @"Foo bar";
    NSError *error = [NSError bzr_errorWithCode:1337 archivePath:archivePath
                         failingArchiveItemPath:failingItem underlyingError:underlyingError
                         description:description];

    expect(error).toNot.beNil();
    expect(error.lt_isLTDomain).to.beTruthy();
    expect(error.code).to.equal(1337);
    expect(error.bzr_archivePath).to.equal(archivePath);
    expect(error.bzr_failingItemPath).to.equal(failingItem);
    expect(error.lt_underlyingError).to.equal(underlyingError);
    expect(error.lt_description).to.equal(description);
  });
});

context(@"transaction error", ^{
  it(@"should return an error with the given transaction that has an error", ^{
    BZRFakePaymentTransaction *transaction = [[BZRFakePaymentTransaction alloc] init];
    transaction.transactionState = SKPaymentTransactionStateFailed;
    transaction.transactionIdentifier = @"foo";
    transaction.error = [NSError lt_errorWithCode:133737];

    NSError *error = [NSError bzr_errorWithCode:1337 transaction:transaction];

    expect(error.code).to.equal(1337);
    expect(error.lt_underlyingError).to.equal(transaction.error);
    expect(error.bzr_transaction).to.equal(transaction);
    expect(error.bzr_transactionIdentifier).to.equal(transaction.transactionIdentifier);
  });

  it(@"should return an error with the given transaction that doesn't have an error", ^{
    BZRFakePaymentTransaction *transaction = [[BZRFakePaymentTransaction alloc] init];
    transaction.transactionState = SKPaymentTransactionStateFailed;
    transaction.transactionIdentifier = @"foo";
    transaction.error = [NSError lt_errorWithCode:133737];

    NSError *error = [NSError bzr_errorWithCode:1337 transaction:transaction];

    expect(error.code).to.equal(1337);
    expect(error.lt_underlyingError).to.equal(transaction.error);
    expect(error.bzr_transaction).to.equal(transaction);
    expect(error.bzr_transactionIdentifier).to.equal(transaction.transactionIdentifier);
  });

  it(@"should return an error with the given transaction without an underlying error", ^{
    BZRFakePaymentTransaction *transaction = [[BZRFakePaymentTransaction alloc] init];
    transaction.transactionState = SKPaymentTransactionStatePurchased;

    NSError *error = [NSError bzr_errorWithCode:1337 transaction:transaction];

    expect(error.code).to.equal(1337);
    expect(error.lt_underlyingError).to.beNil();
  });

  it(@"should return an error with description that has the transaction's description", ^{
    BZRFakePaymentTransaction *transaction = [[BZRFakePaymentTransaction alloc] init];
    transaction.transactionState = SKPaymentTransactionStatePurchased;
    transaction.transactionDate = [NSDate date];
    transaction.transactionIdentifier = @"bar";

    BZRFakePaymentTransaction *originalTransaction = [[BZRFakePaymentTransaction alloc] init];
    originalTransaction.transactionIdentifier = @"foofoo";
    transaction.originalTransaction = originalTransaction;

    NSError *error = [NSError bzr_errorWithCode:1337 transaction:transaction];

    NSString *productIdentifierDescription =
        [NSString stringWithFormat:@"%@ = %@", @keypath(transaction.payment, productIdentifier),
         transaction.payment.productIdentifier];
    NSString *dateDescription =
        [NSString stringWithFormat:@"%@ = \"%@\"", @keypath(transaction, transactionDate),
         transaction.transactionDate];
    NSString *transactionIdentifierDescription =
        [NSString stringWithFormat:@"%@ = %@", @keypath(transaction, transactionIdentifier),
         transaction.transactionIdentifier];
    NSString *stateDescription =
        [NSString stringWithFormat:@"%@ = %@", @keypath(transaction, transactionState),
         @"SKPaymentTransactionStatePurchased"];
    NSString *originalTransactionIdentifierDescription =
        [NSString stringWithFormat:@"%@ = %@",
         @keypath(originalTransaction, transactionIdentifier),
         originalTransaction.transactionIdentifier];

    expect(error.description).to.contain(productIdentifierDescription);
    expect(error.description).to.contain(dateDescription);
    expect(error.description).to.contain(transactionIdentifierDescription);
    expect(error.description).to.contain(stateDescription);
    expect(error.description).to.contain(originalTransactionIdentifierDescription);
  });
});

context(@"invalid product identifiers error", ^{
  it(@"should return an invalid product identifiers error with the given products", ^{
    NSSet<NSString *> *products = [NSSet setWithObjects:@"foo", @"bar", nil];
    NSError *error = [NSError bzr_invalidProductsErrorWithIdentifiers:products];

    expect(error.domain).to.equal(kLTErrorDomain);
    expect(error.code).to.equal(BZRErrorCodeInvalidProductIdentifier);
    expect(error.bzr_productIdentifiers).to.equal(products);
  });
});

context(@"periodic validation errors", ^{
  it(@"should return an error with the given days, last validation date and underlying error", ^{
    NSInteger seccondsUntilSubscriptionInvalidation = 4;
    NSDate *lastValidationDate = [NSDate date];
    NSError *underlyingError = [NSError lt_errorWithCode:1337];

    NSError *error =
        [NSError bzr_errorWithSecondsUntilSubscriptionInvalidation:
         @(seccondsUntilSubscriptionInvalidation) lastReceiptValidationDate:lastValidationDate
         underlyingError:underlyingError];

    expect(error).toNot.beNil();
    expect(error.lt_isLTDomain).to.beTruthy();
    expect(error.code).to.equal(BZRErrorCodePeriodicReceiptValidationFailed);
    expect(error.bzr_secondsUntilSubscriptionInvalidation).to
        .equal(seccondsUntilSubscriptionInvalidation);
    expect(error.bzr_lastReceiptValidationDate).to.equal(lastValidationDate);
    expect(error.lt_underlyingError).to.equal(underlyingError);
  });
});

context(@"error with storage failure", ^{
  it(@"should return an error with the given values", ^{
    NSError *underlyingError = [NSError lt_errorWithCode:1337];
    NSError *error = [NSError bzr_storageErrorWithCode:1337 underlyingError:underlyingError
        description:@"foo" keychainStorageServiceName:@"baz" keychainStorageKey:@"bar"
        keychainStorageValue:@[@"value"]];

    expect(error.lt_underlyingError).to.equal(underlyingError);
    expect(error.lt_description).to.equal(@"foo");
    expect(error.bzr_keychainStorageServiceName).to.equal(@"baz");
    expect(error.bzr_keychainStorageKey).to.equal(@"bar");
    expect(error.bzr_keychainStorageValueDescription).to.equal(@[@"value"].description);
  });

  it(@"should return an error without the given nil values", ^{
    NSError *error = [NSError bzr_storageErrorWithCode:1337 underlyingError:nil description:@"foo"
        keychainStorageServiceName:nil keychainStorageKey:@"bar" keychainStorageValue:nil];

    expect(error.lt_underlyingError).to.beNil();
    expect(error.bzr_keychainStorageServiceName).to.beNil();
    expect(error.bzr_keychainStorageValueDescription).to.beNil();
  });
});

SpecEnd
