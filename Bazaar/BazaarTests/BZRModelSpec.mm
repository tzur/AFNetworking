// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRModel.h"

static NSString * const kInvalidValidPropertyValue = @"Baz";
static const NSUInteger kValidationErrorCode = 1337;

@interface BZRDummyModel : BZRModel
@property (strong, readonly, nonatomic, nonnull) NSString *nonnullProperty;
@property (strong, readonly, nonatomic, nullable) NSString *nullableProperty;
@end

@implementation BZRDummyModel

+ (NSSet<NSString *> *)nullablePropertyKeys {
  return [NSSet setWithObjects:@instanceKeypath(BZRDummyModel, nullableProperty), nil];
}

- (BOOL)validate:(NSError *__autoreleasing *)error {
  if ([self.nonnullProperty isEqualToString:kInvalidValidPropertyValue]) {
    if (error) {
      *error = [NSError lt_errorWithCode:kValidationErrorCode];
    }
    return NO;
  }
  return YES;
}

@end

SpecBegin(BZRModel)

context(@"nullable properties", ^{
  it(@"should return nil", ^{
    expect([BZRModel nullablePropertyKeys].count).to.equal(0);
  });
});

context(@"dictionary validation", ^{
  __block NSError *error;
  __block NSSet<NSString *> *nullablePropertyKeys;

  beforeEach(^{
    error = nil;
    nullablePropertyKeys = [BZRDummyModel nullablePropertyKeys];
  });

  it(@"should succeed if dictionary is missing a value for nullable property", ^{
    NSDictionary *dictionaryValue = @{@instanceKeypath(BZRDummyModel, nonnullProperty): @"Foo"};

    BOOL isValid = [BZRDummyModel validateDictionaryValue:dictionaryValue
                                 withNullablePropertyKeys:nullablePropertyKeys error:&error];
    expect(isValid).to.beTruthy();
    expect(error).to.beNil();
  });

  it(@"should fail validation if dictionary is missing value for nonnull property", ^{
    NSDictionary *dictionaryValue = @{@instanceKeypath(BZRDummyModel, nullableProperty): @"Foo"};

    BOOL isValid = [BZRDummyModel validateDictionaryValue:dictionaryValue
                                 withNullablePropertyKeys:nullablePropertyKeys error:&error];
    expect(isValid).to.beFalsy();
    expect(error).toNot.beNil();
    expect(error.domain).to.equal(kLTErrorDomain);
    expect(error.code).to.equal(LTErrorCodeObjectCreationFailed);
  });

  it(@"should fail validation if any property value is missing and no nullable keys are allowed", ^{
    NSDictionary *dictionaryValue = @{
      @instanceKeypath(BZRDummyModel, nonnullProperty): @"Foo"
    };

    BOOL isValid = [BZRDummyModel validateDictionaryValue:dictionaryValue
                                 withNullablePropertyKeys:[NSSet set] error:&error];
    expect(isValid).to.beFalsy();
    expect(error).toNot.beNil();
    expect(error.domain).to.equal(kLTErrorDomain);
    expect(error.code).to.equal(LTErrorCodeObjectCreationFailed);
  });
});

context(@"safe initializer", ^{
  it(@"should fail initialization if dictionary does not pass validation", ^{
    NSDictionary *dictionaryValue = @{@instanceKeypath(BZRDummyModel, nullableProperty): @"Foo"};

    NSError *error;
    BZRDummyModel *model = [[BZRDummyModel alloc] initWithDictionary:dictionaryValue error:&error];
    expect(model).to.beNil();
    expect(error).toNot.beNil();
    expect(error.domain).to.equal(kLTErrorDomain);
    expect(error.code).to.equal(LTErrorCodeObjectCreationFailed);
  });

  it(@"should initialize with valid dictionary value", ^{
    NSDictionary *dictionaryValue = @{@instanceKeypath(BZRDummyModel, nonnullProperty): @"Foo"};

    NSError *error;
    BZRDummyModel *model = [[BZRDummyModel alloc] initWithDictionary:dictionaryValue error:&error];
    expect(model).toNot.beNil();
    expect(model.nonnullProperty).to.equal(@"Foo");
    expect(model.nullableProperty).to.beNil();
    expect(error).to.beNil();
  });

  it(@"should fail initialization if post initialization validation fails", ^{
    NSDictionary *dictionaryValue = @{
      @instanceKeypath(BZRDummyModel, nonnullProperty): kInvalidValidPropertyValue
    };

    NSError *error;
    BZRDummyModel *model = [[BZRDummyModel alloc] initWithDictionary:dictionaryValue error:&error];
    expect(model).to.beNil();
    expect(error).toNot.beNil();
    expect(error.code).to.equal(kValidationErrorCode);
  });
});

SpecEnd
