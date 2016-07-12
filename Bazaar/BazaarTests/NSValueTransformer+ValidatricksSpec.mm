// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "NSValueTransformer+Validatricks.h"

#import "BZRReceiptEnvironment.h"
#import "BZRReceiptValidationError.h"

SpecBegin(NSValueTransformer_Validatricks)

context(@"time interval since 1970 transformer", ^{
  __block NSValueTransformer *transformer;
  __block NSTimeInterval timeInterval;
  __block NSDate *dateTime;

  beforeEach(^{
    transformer = [NSValueTransformer bzr_timeIntervalSince1970ValueTransformer];
    timeInterval = 1337;
    dateTime = [NSDate dateWithTimeIntervalSince1970:1337];
  });

  it(@"should indicate that it supports reverse transformation", ^{
    expect([[transformer class] allowsReverseTransformation]).to.beTruthy();
  });

  it(@"should correctly transform an NSTimeInterval to NSDate", ^{
    NSDate *transformedDateTime = [transformer transformedValue:@(timeInterval)];
    expect(transformedDateTime).to.equal(dateTime);
  });

  it(@"should return nil if given nil", ^{
    expect([transformer transformedValue:nil]).to.beNil();
    expect([transformer reverseTransformedValue:nil]).to.beNil();
  });

  it(@"should correctly transform an NSDate to NSTimeInterval", ^{
    NSTimeInterval transformedTimeInterval =
        [[transformer reverseTransformedValue:dateTime] doubleValue];
    expect(transformedTimeInterval).to.beCloseToWithin(timeInterval, DBL_EPSILON);
  });
});

context(@"validatricks receipt validation error transformer", ^{
  static NSArray<NSString *> * const kValidatricksErrors = @[
    @"invalidJson",
    @"malformedData",
    @"notAuthenticated",
    @"testReceiptInProd",
    @"prodReceiptInTest",
    @"unexpectedBundle"
  ];

  __block NSValueTransformer *transformer;

  beforeEach(^{
    transformer = [NSValueTransformer bzr_validatricksErrorValueTransformer];
  });

  it(@"should provide receipt validation error for every registered validatricks error", ^{
    [kValidatricksErrors enumerateObjectsUsingBlock:^(NSString *errorName, NSUInteger, BOOL *) {
      BZRReceiptValidationError *error = [transformer transformedValue:errorName];
      expect(error).toNot.beNil();
      expect(error).toNot.equal($(BZRReceiptValidationErrorUnknown));
    }];
  });

  it(@"should return nil if the received validatricks error is nil", ^{
    expect([transformer transformedValue:nil]).to.beNil();
  });

  it(@"should return a generic error if the received value is not registered", ^{
    expect([transformer transformedValue:@"foo"]).to.equal($(BZRReceiptValidationErrorUnknown));
  });
});

context(@"validatricks receipt environment transformer", ^{
  __block NSValueTransformer *transformer;

  beforeEach(^{
    transformer = [NSValueTransformer bzr_validatricksReceiptEnvironmentValueTransformer];
  });

  it(@"should transform validatricks receipt environment to the correct enum value", ^{
    expect([transformer transformedValue:@"Sandbox"]).to.equal($(BZRReceiptEnvironmentSandbox));
    expect([transformer transformedValue:@"Production"]).to
        .equal($(BZRReceiptEnvironmentProduction));
  });

  it(@"should transform receipt environment enum to validatricks receipt environment", ^{
    expect([transformer reverseTransformedValue:$(BZRReceiptEnvironmentSandbox)]).to
        .equal(@"Sandbox");
    expect([transformer reverseTransformedValue:$(BZRReceiptEnvironmentProduction)]).to
        .equal(@"Production");
  });

  it(@"should return nil if the received value is nil", ^{
    expect([transformer transformedValue:nil]).to.beNil();
  });

  it(@"should return nil if the received value is unknown", ^{
    expect([transformer transformedValue:@"foo"]).to.beNil();
  });
});

SpecEnd
