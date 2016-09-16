// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "NSError+Bazaar.h"

#import <LTKit/NSError+LTKit.h>
#import "BZRFakePaymentTransaction.h"
#import "NSErrorCodes+Bazaar.h"

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
  it(@"should return an error with the given transaction and underlying error", ^{
    BZRFakePaymentTransaction *transaction = [[BZRFakePaymentTransaction alloc] init];
    transaction.transactionState = SKPaymentTransactionStateFailed;
    transaction.error = [NSError lt_errorWithCode:133737];

    NSError *error = [NSError bzr_errorWithCode:1337 transaction:transaction];

    expect(error).toNot.beNil();
    expect(error.lt_isLTDomain).to.beTruthy();
    expect(error.code).to.equal(1337);
    expect(error.lt_underlyingError).to.equal(transaction.error);
  });

  it(@"should return an error with the given transaction without an underlying error", ^{
    BZRFakePaymentTransaction *transaction = [[BZRFakePaymentTransaction alloc] init];
    transaction.transactionState = SKPaymentTransactionStatePurchased;

    NSError *error = [NSError bzr_errorWithCode:1337 transaction:transaction];

    expect(error).toNot.beNil();
    expect(error.lt_isLTDomain).to.beTruthy();
    expect(error.code).to.equal(1337);
    expect(error.lt_underlyingError).to.beNil();
  });
});

SpecEnd
