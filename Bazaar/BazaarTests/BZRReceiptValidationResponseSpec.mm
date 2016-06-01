// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRReceiptValidationResponse.h"

#import "BZRReceiptModel.h"
#import "BZRReceiptValidationError.h"

SpecBegin(BZRReceiptValidationResponse)

context(@"initialization", ^{
  __block BZRReceiptValidationResponse *response;
  __block NSError *error;

  beforeEach(^{
    response = nil;
    error = nil;
  });

  it(@"should fail initialization with missing isValid value", ^{
    NSDictionary *dictionaryValue = @{
      @instanceKeypath(BZRReceiptValidationResponse, validationDateTime): [NSDate date],
      @instanceKeypath(BZRReceiptValidationResponse, error): $(BZRReceiptValidationErrorUnknown)
    };

    response =
        [[BZRReceiptValidationResponse alloc] initWithDictionary:dictionaryValue error:&error];
    expect(response).to.beNil();
    expect(error).toNot.beNil();
    expect(error.domain).to.equal(kLTErrorDomain);
    expect(error.code).to.equal(LTErrorCodeObjectCreationFailed);
  });

  it(@"should fail initialization with missing validationDateTime value", ^{
    NSDictionary *dictionaryValue = @{
      @instanceKeypath(BZRReceiptValidationResponse, isValid): @NO,
      @instanceKeypath(BZRReceiptValidationResponse, error): $(BZRReceiptValidationErrorUnknown)
    };

    response =
        [[BZRReceiptValidationResponse alloc] initWithDictionary:dictionaryValue error:&error];
    expect(response).to.beNil();
    expect(error).toNot.beNil();
    expect(error.domain).to.equal(kLTErrorDomain);
    expect(error.code).to.equal(LTErrorCodeObjectCreationFailed);
  });

  it(@"should fail initialization with null validationDateTime value", ^{
    NSDictionary *dictionaryValue = @{
      @instanceKeypath(BZRReceiptValidationResponse, isValid): @NO,
      @instanceKeypath(BZRReceiptValidationResponse, error): $(BZRReceiptValidationErrorUnknown),
      @instanceKeypath(BZRReceiptValidationResponse, validationDateTime): [NSNull null],
    };

    response =
        [[BZRReceiptValidationResponse alloc] initWithDictionary:dictionaryValue error:&error];
    expect(response).to.beNil();
    expect(error).toNot.beNil();
    expect(error.domain).to.equal(kLTErrorDomain);
    expect(error.code).to.equal(LTErrorCodeObjectCreationFailed);
  });

  it(@"should fail initialization if receipt is invalid but no error is specified", ^{
    NSDictionary *dictionaryValue = @{
      @instanceKeypath(BZRReceiptValidationResponse, isValid): @NO,
      @instanceKeypath(BZRReceiptValidationResponse, validationDateTime): [NSDate date]
    };

    response =
        [[BZRReceiptValidationResponse alloc] initWithDictionary:dictionaryValue error:&error];
    expect(response).to.beNil();
    expect(error).toNot.beNil();
    expect(error.domain).to.equal(kLTErrorDomain);
    expect(error.code).to.equal(LTErrorCodeObjectCreationFailed);
  });

  it(@"should initialize if receipt is invalid and no receipt information is specified", ^{
    NSDictionary *dictionaryValue = @{
      @instanceKeypath(BZRReceiptValidationResponse, isValid): @NO,
      @instanceKeypath(BZRReceiptValidationResponse, error): $(BZRReceiptValidationErrorUnknown),
      @instanceKeypath(BZRReceiptValidationResponse, validationDateTime): [NSDate date]
    };

    response =
        [[BZRReceiptValidationResponse alloc] initWithDictionary:dictionaryValue error:&error];
    expect(response).toNot.beNil();
    expect(error).to.beNil();
  });

  it(@"should fail initialization if receipt is valid but no receipt information is specified", ^{
    NSDictionary *dictionaryValue = @{
      @instanceKeypath(BZRReceiptValidationResponse, isValid): @YES,
      @instanceKeypath(BZRReceiptValidationResponse, validationDateTime): [NSDate date]
    };

    response =
        [[BZRReceiptValidationResponse alloc] initWithDictionary:dictionaryValue error:&error];
    expect(response).to.beNil();
    expect(error).toNot.beNil();
    expect(error.domain).to.equal(kLTErrorDomain);
    expect(error.code).to.equal(LTErrorCodeObjectCreationFailed);
  });

  it(@"should initialize if receipt is valid and no error is specified", ^{
    NSDictionary *dictionaryValue = @{
      @instanceKeypath(BZRReceiptValidationResponse, isValid): @YES,
      @instanceKeypath(BZRReceiptValidationResponse, validationDateTime): [NSDate date],
      @instanceKeypath(BZRReceiptValidationResponse, receipt): OCMClassMock([BZRReceiptInfo class])
    };

    response =
        [[BZRReceiptValidationResponse alloc] initWithDictionary:dictionaryValue error:&error];
    expect(response).toNot.beNil();
    expect(error).to.beNil();
  });
});

SpecEnd
