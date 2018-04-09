// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRReceiptValidationStatus.h"

#import "BZRReceiptEnvironment.h"
#import "BZRReceiptModel.h"
#import "BZRReceiptValidationError.h"
#import "NSValueTransformer+Bazaar.h"

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

context(@"JSON serialization", ^{
  __block NSValueTransformer *millisecondsDateTimeTransformer;

  beforeEach(^{
    millisecondsDateTimeTransformer = [NSValueTransformer bzr_millisecondsDateTimeValueTransformer];
  });

  it(@"should correctly convert from BZRReciptValidationStatus to JSON dictionary", ^{
    BZRReceiptInfo *receipt = [[BZRReceiptInfo alloc] initWithDictionary:@{
      @instanceKeypath(BZRReceiptInfo, environment): $(BZRReceiptEnvironmentSandbox)
    } error:nil];
    NSDictionary *receiptJSONDictionary = [MTLJSONAdapter JSONDictionaryFromModel:receipt];

    NSDate *validationDateTime = [NSDate dateWithTimeIntervalSince1970:1337];
    BZRReceiptValidationStatus *receiptValidationStatus =
        [[BZRReceiptValidationStatus alloc] initWithDictionary:@{
          @instanceKeypath(BZRReceiptValidationStatus, isValid): @YES,
          @instanceKeypath(BZRReceiptValidationStatus, validationDateTime): validationDateTime,
          @instanceKeypath(BZRReceiptValidationStatus, receipt): receipt
        } error:nil];
    NSDictionary *JSONDictionary = [MTLJSONAdapter JSONDictionaryFromModel:receiptValidationStatus];

    expect(JSONDictionary[@"valid"]).to.equal(YES);
    expect(JSONDictionary[@"currentDateTime"])
        .to.equal([millisecondsDateTimeTransformer reverseTransformedValue:validationDateTime]);
    expect(JSONDictionary[@instanceKeypath(BZRReceiptValidationStatus, receipt)])
        .to.equal(receiptJSONDictionary);
  });

  it(@"should correctly convert from JSON dictionary to BZRReciptValidationStatus", ^{
    BZRReceiptInfo *receipt = [[BZRReceiptInfo alloc] initWithDictionary:@{
      @instanceKeypath(BZRReceiptInfo, environment): $(BZRReceiptEnvironmentSandbox)
    } error:nil];
    NSDictionary *receiptJSONDictionary = [MTLJSONAdapter JSONDictionaryFromModel:receipt];

    NSDate *validationDateTime = [NSDate dateWithTimeIntervalSince1970:1337];
    NSDictionary *JSONDictionary = @{
      @"valid": @YES,
      @"currentDateTime":
          [millisecondsDateTimeTransformer reverseTransformedValue:validationDateTime],
      @"receipt": receiptJSONDictionary
    };

    NSError *error;
    BZRReceiptValidationStatus *receiptValidationStatus =
        [MTLJSONAdapter modelOfClass:BZRReceiptValidationStatus.class
                  fromJSONDictionary:JSONDictionary
                               error:&error];

    expect(error).to.beNil();
    expect(receiptValidationStatus.isValid).to.equal(YES);
    expect(receiptValidationStatus.validationDateTime).to.equal(validationDateTime);
    expect(receiptValidationStatus.receipt).to.equal(receipt);
  });
});

SpecEnd
