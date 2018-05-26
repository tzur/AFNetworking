// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "NSValueTransformer+Bazaar.h"

#import "BZRReceiptEnvironment.h"
#import "BZRReceiptValidationError.h"

LTEnumMake(NSUInteger, BZRTestEnum,
    BZRTestEnumFoo,
    BZRTestEnumBar
);

SpecBegin(NSValueTransformer_Bazaar)

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

context(@"milliseconds date time transformer", ^{
  static const double kMilliSecondsPerSecond = 1000;

  __block NSValueTransformer *transformer;
  __block double timeInterval;
  __block NSDate *dateTime;

  beforeEach(^{
    transformer = [NSValueTransformer bzr_millisecondsDateTimeValueTransformer];
    timeInterval = 1337 * kMilliSecondsPerSecond;
    dateTime = [NSDate dateWithTimeIntervalSince1970:1337];
  });

  it(@"should indicate that it supports reverse transformation", ^{
    expect([[transformer class] allowsReverseTransformation]).to.beTruthy();
  });

  it(@"should correctly transform an milliseconds since 1970 to NSDate", ^{
    NSDate *transformedDateTime = [transformer transformedValue:@(timeInterval)];
    expect(transformedDateTime).to.equal(dateTime);
  });

  it(@"should return nil if given nil", ^{
    expect([transformer transformedValue:nil]).to.beNil();
    expect([transformer reverseTransformedValue:nil]).to.beNil();
  });

  it(@"should correctly transform an NSDate to milliseconds since 1970", ^{
    double transformedTimeInterval =
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

  it(@"should be a reversible transformer", ^{
    expect([[transformer class] allowsReverseTransformation]).to.beTruthy();
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

  it(@"should return nil if error is nil", ^{
    expect([transformer reverseTransformedValue:nil]).to.beNil();
  });

  it(@"should return the right validatricks error string for every known error value", ^{
    [BZRReceiptValidationError enumerateEnumUsingBlock:^(BZRReceiptValidationError *error) {
      NSString * _Nullable validatricksErrorString = [transformer reverseTransformedValue:error];
      expect(validatricksErrorString).toNot.beNil();
      expect([transformer transformedValue:validatricksErrorString]).to.equal(error);
    }];
  });
});

context(@"validatricks receipt environment transformer", ^{
  __block NSValueTransformer *transformer;

  beforeEach(^{
    transformer = [NSValueTransformer bzr_validatricksReceiptEnvironmentValueTransformer];
  });

  it(@"should transform validatricks receipt environment to the correct enum value", ^{
    expect([transformer transformedValue:@"sandbox"]).to.equal($(BZRReceiptEnvironmentSandbox));
    expect([transformer transformedValue:@"production"]).to
        .equal($(BZRReceiptEnvironmentProduction));
  });

  it(@"should transform receipt environment enum to validatricks receipt environment", ^{
    expect([transformer reverseTransformedValue:$(BZRReceiptEnvironmentSandbox)]).to
        .equal(@"sandbox");
    expect([transformer reverseTransformedValue:$(BZRReceiptEnvironmentProduction)]).to
        .equal(@"production");
  });

  it(@"should return nil if the received value is nil", ^{
    expect([transformer transformedValue:nil]).to.beNil();
  });

  it(@"should return nil if the received value is unknown", ^{
    expect([transformer transformedValue:@"foo"]).to.beNil();
  });
});

context(@"enum class transformer", ^{
  __block NSValueTransformer *transformer;

  beforeEach(^{
    transformer = [NSValueTransformer bzr_enumNameTransformerForClass:BZRTestEnum.class];
  });

  it(@"should perform forward transform", ^{
    expect([transformer transformedValue:$(BZRTestEnumFoo).name]).to.equal($(BZRTestEnumFoo));
  });

  it(@"should perform reverse transform", ^{
    expect([transformer reverseTransformedValue:$(BZRTestEnumFoo)]).to
        .equal($(BZRTestEnumFoo).name);
  });

  it(@"should raise if given enum class is not an enum", ^{
    expect(^{
      [NSValueTransformer bzr_enumNameTransformerForClass:NSString.class];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should transform to nil when transforming an invalid enum field name", ^{
    expect([transformer transformedValue:@"foo"]).to.beNil();
  });

  it(@"should transform to nil when transforming a nil value", ^{
    expect([transformer transformedValue:nil]).to.beNil();
  });

  it(@"should transform to nil when reverse transforming a nil value", ^{
    expect([transformer reverseTransformedValue:nil]).to.beNil();
  });
});

SpecEnd
