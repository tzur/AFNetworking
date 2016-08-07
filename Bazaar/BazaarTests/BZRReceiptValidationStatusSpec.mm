// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRReceiptValidationStatus.h"

#import "BZRReceiptModel.h"
#import "BZRReceiptValidationError.h"

SpecBegin(BZRReceiptValidationStatus)

context(@"initialization", ^{
  __block BZRReceiptValidationStatus *status;
  __block NSError *error;

  beforeEach(^{
    status = nil;
    error = nil;
  });

  it(@"should fail initialization with missing isValid value", ^{
    NSDictionary *dictionaryValue = @{
      @instanceKeypath(BZRReceiptValidationStatus, validationDateTime): [NSDate date],
      @instanceKeypath(BZRReceiptValidationStatus, error): $(BZRReceiptValidationErrorUnknown)
    };

    status = [[BZRReceiptValidationStatus alloc] initWithDictionary:dictionaryValue error:&error];
    expect(status).to.beNil();
    expect(error).toNot.beNil();
    expect(error.domain).to.equal(kLTErrorDomain);
    expect(error.code).to.equal(LTErrorCodeObjectCreationFailed);
  });

  it(@"should fail initialization with missing validationDateTime value", ^{
    NSDictionary *dictionaryValue = @{
      @instanceKeypath(BZRReceiptValidationStatus, isValid): @NO,
      @instanceKeypath(BZRReceiptValidationStatus, error): $(BZRReceiptValidationErrorUnknown)
    };

    status =
        [[BZRReceiptValidationStatus alloc] initWithDictionary:dictionaryValue error:&error];
    expect(status).to.beNil();
    expect(error).toNot.beNil();
    expect(error.domain).to.equal(kLTErrorDomain);
    expect(error.code).to.equal(LTErrorCodeObjectCreationFailed);
  });

  it(@"should fail initialization with null validationDateTime value", ^{
    NSDictionary *dictionaryValue = @{
      @instanceKeypath(BZRReceiptValidationStatus, isValid): @NO,
      @instanceKeypath(BZRReceiptValidationStatus, error): $(BZRReceiptValidationErrorUnknown),
      @instanceKeypath(BZRReceiptValidationStatus, validationDateTime): [NSNull null],
    };

    status = [[BZRReceiptValidationStatus alloc] initWithDictionary:dictionaryValue error:&error];
    expect(status).to.beNil();
    expect(error).toNot.beNil();
    expect(error.domain).to.equal(kLTErrorDomain);
    expect(error.code).to.equal(LTErrorCodeObjectCreationFailed);
  });

  it(@"should fail initialization if receipt is invalid but no error is specified", ^{
    NSDictionary *dictionaryValue = @{
      @instanceKeypath(BZRReceiptValidationStatus, isValid): @NO,
      @instanceKeypath(BZRReceiptValidationStatus, validationDateTime): [NSDate date]
    };

    status = [[BZRReceiptValidationStatus alloc] initWithDictionary:dictionaryValue error:&error];
    expect(status).to.beNil();
    expect(error).toNot.beNil();
    expect(error.domain).to.equal(kLTErrorDomain);
    expect(error.code).to.equal(LTErrorCodeObjectCreationFailed);
  });

  it(@"should initialize if receipt is invalid and no receipt information is specified", ^{
    NSDictionary *dictionaryValue = @{
      @instanceKeypath(BZRReceiptValidationStatus, isValid): @NO,
      @instanceKeypath(BZRReceiptValidationStatus, error): $(BZRReceiptValidationErrorUnknown),
      @instanceKeypath(BZRReceiptValidationStatus, validationDateTime): [NSDate date]
    };

    status = [[BZRReceiptValidationStatus alloc] initWithDictionary:dictionaryValue error:&error];
    expect(status).toNot.beNil();
    expect(error).to.beNil();
  });

  it(@"should fail initialization if receipt is valid but no receipt information is specified", ^{
    NSDictionary *dictionaryValue = @{
      @instanceKeypath(BZRReceiptValidationStatus, isValid): @YES,
      @instanceKeypath(BZRReceiptValidationStatus, validationDateTime): [NSDate date]
    };

    status = [[BZRReceiptValidationStatus alloc] initWithDictionary:dictionaryValue error:&error];
    expect(status).to.beNil();
    expect(error).toNot.beNil();
    expect(error.domain).to.equal(kLTErrorDomain);
    expect(error.code).to.equal(LTErrorCodeObjectCreationFailed);
  });

  it(@"should initialize if receipt is valid and no error is specified", ^{
    NSDictionary *dictionaryValue = @{
      @instanceKeypath(BZRReceiptValidationStatus, isValid): @YES,
      @instanceKeypath(BZRReceiptValidationStatus, validationDateTime): [NSDate date],
      @instanceKeypath(BZRReceiptValidationStatus, receipt): OCMClassMock([BZRReceiptInfo class])
    };

    status = [[BZRReceiptValidationStatus alloc] initWithDictionary:dictionaryValue error:&error];
    expect(status).toNot.beNil();
    expect(error).to.beNil();
  });
});

SpecEnd
