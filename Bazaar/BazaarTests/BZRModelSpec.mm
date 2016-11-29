// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRModel.h"

static NSString * const kInvalidValidPropertyValue = @"Baz";
static const NSUInteger kValidationErrorCode = 1337;

/// Dummy model used for testing \c BZRModel functionality.
@interface BZRDummyModel : BZRModel

/// Non-optional property, its value must be provided on initialization and must not be \c nil.
@property (strong, readonly, nonatomic, nonnull) NSString *requiredProperty;

/// Optional property, its value can be omitted and \c nil is a valid value for that key.
@property (strong, readonly, nonatomic, nullable) NSString *optionalProperty;

/// Optional property of a primitive type, its value can be omitted.
@property (readonly, nonatomic) BOOL primitiveProperty;

/// Property with default, its value can be omitted and determined by \c defaultPropertyValues.
@property (strong, readonly, nonatomic, nonnull) NSString *propertyWithDefault;

/// Property with default of a primitive type, its value can be omitted and determined by
/// \c defaultPropertyValues.
@property (readonly, nonatomic) BOOL primitivePropertyWithDefault;

@end

@implementation BZRDummyModel

+ (NSSet<NSString *> *)optionalPropertyKeys {
  return [NSSet setWithArray:@[
    @instanceKeypath(BZRDummyModel, optionalProperty),
    @instanceKeypath(BZRDummyModel, primitiveProperty),
  ]];
}

+ (NSDictionary<NSString *, id> *)defaultPropertyValues {
  return @{
    @instanceKeypath(BZRDummyModel, propertyWithDefault): @"foo",
    @instanceKeypath(BZRDummyModel, primitivePropertyWithDefault): @YES
  };
}

- (BOOL)validate:(NSError *__autoreleasing *)error {
  if ([self.requiredProperty isEqualToString:kInvalidValidPropertyValue]) {
    if (error) {
      *error = [NSError lt_errorWithCode:kValidationErrorCode];
    }
    return NO;
  }
  return YES;
}

@end

SpecBegin(BZRModel)

context(@"optional properties", ^{
  it(@"should have no optional properties by default", ^{
    expect([BZRModel optionalPropertyKeys].count).to.equal(0);
  });
});

context(@"dictionary validation", ^{
  __block NSError *error;
  __block NSSet<NSString *> *optionalPropertyKeys;
  __block NSDictionary<NSString *, id> *defaultPropertyValues;

  beforeEach(^{
    error = nil;
    optionalPropertyKeys = [BZRDummyModel optionalPropertyKeys];
    defaultPropertyValues = [BZRDummyModel defaultPropertyValues];
  });

  it(@"should succeed if dictionary is missing a value for optional properties", ^{
    NSDictionary *dictionaryValue = @{
      @instanceKeypath(BZRDummyModel, requiredProperty): @"Foo",
      @instanceKeypath(BZRDummyModel, propertyWithDefault): @"Bar",
      @instanceKeypath(BZRDummyModel, primitivePropertyWithDefault): @NO
    };

    BOOL isValid = [BZRDummyModel validateDictionaryValue:dictionaryValue
                                 withOptionalPropertyKeys:optionalPropertyKeys error:&error];
    expect(isValid).to.beTruthy();
    expect(error).to.beNil();
  });

  it(@"should fail validation if dictionary is missing value for a mandatory property", ^{
    NSDictionary *dictionaryValue = @{@instanceKeypath(BZRDummyModel, optionalProperty): @"Foo"};

    BOOL isValid = [BZRDummyModel validateDictionaryValue:dictionaryValue
                                 withOptionalPropertyKeys:optionalPropertyKeys error:&error];
    expect(isValid).to.beFalsy();
    expect(error).toNot.beNil();
    expect(error.domain).to.equal(kLTErrorDomain);
    expect(error.code).to.equal(LTErrorCodeObjectCreationFailed);
  });

  it(@"should fail validation if any property value is missing and no optional keys supplied", ^{
    NSDictionary *dictionaryValue = @{
      @instanceKeypath(BZRDummyModel, requiredProperty): @"Foo"
    };

    BOOL isValid = [BZRDummyModel validateDictionaryValue:dictionaryValue
                                 withOptionalPropertyKeys:[NSSet set] error:&error];
    expect(isValid).to.beFalsy();
    expect(error).toNot.beNil();
    expect(error.domain).to.equal(kLTErrorDomain);
    expect(error.code).to.equal(LTErrorCodeObjectCreationFailed);
  });

  it(@"should fail validation if any property value is missing and default values not supplied", ^{
    NSDictionary *dictionaryValue = @{
      @instanceKeypath(BZRDummyModel, requiredProperty): @"Foo"
    };

    BOOL isValid = [BZRDummyModel validateDictionaryValue:dictionaryValue
                                 withOptionalPropertyKeys:optionalPropertyKeys error:&error];
    expect(isValid).to.beFalsy();
    expect(error).toNot.beNil();
    expect(error.domain).to.equal(kLTErrorDomain);
    expect(error.code).to.equal(LTErrorCodeObjectCreationFailed);
  });
});

context(@"safe initializer", ^{
  it(@"should fail initialization if dictionary does not pass validation", ^{
    NSDictionary *dictionaryValue = @{@instanceKeypath(BZRDummyModel, optionalProperty): @"Foo"};

    NSError *error;
    BZRDummyModel *model = [[BZRDummyModel alloc] initWithDictionary:dictionaryValue error:&error];
    expect(model).to.beNil();
    expect(error).toNot.beNil();
    expect(error.domain).to.equal(kLTErrorDomain);
    expect(error.code).to.equal(LTErrorCodeObjectCreationFailed);
  });

  it(@"should initialize with valid dictionary value", ^{
    NSDictionary *dictionaryValue = @{@instanceKeypath(BZRDummyModel, requiredProperty): @"Foo"};

    NSError *error;
    BZRDummyModel *model = [[BZRDummyModel alloc] initWithDictionary:dictionaryValue error:&error];
    expect(model).toNot.beNil();
    expect(model.requiredProperty).to.equal(@"Foo");
    expect(model.optionalProperty).to.beNil();
    expect(model.propertyWithDefault).to.equal(@"foo");
    expect(model.primitivePropertyWithDefault).to.equal(YES);
    expect(error).to.beNil();
  });

  it(@"should fail initialization if post initialization validation fails", ^{
    NSDictionary *dictionaryValue = @{
      @instanceKeypath(BZRDummyModel, requiredProperty): kInvalidValidPropertyValue
    };

    NSError *error;
    BZRDummyModel *model = [[BZRDummyModel alloc] initWithDictionary:dictionaryValue error:&error];
    expect(model).to.beNil();
    expect(error).toNot.beNil();
    expect(error.code).to.equal(kValidationErrorCode);
  });

  it(@"should succeed if dictionary is missing a value for default properties", ^{
    NSDictionary *dictionaryValue = @{
      @instanceKeypath(BZRDummyModel, requiredProperty): @"Foo",
      @instanceKeypath(BZRDummyModel, optionalProperty): @"Bar"
    };

    NSError *error;
    BZRDummyModel *model = [[BZRDummyModel alloc] initWithDictionary:dictionaryValue error:&error];

    expect(model).toNot.beNil();
    expect(error).to.beNil();
  });
});

context(@"overriding property values", ^{
  __block BZRDummyModel *model;

  beforeEach(^{
    model = [[BZRDummyModel alloc] initWithDictionary:@{
      @instanceKeypath(BZRDummyModel, requiredProperty): @"Foo",
      @instanceKeypath(BZRDummyModel, optionalProperty): @"Bar",
      @instanceKeypath(BZRDummyModel, primitiveProperty): @YES
    } error:nil];
  });

  it(@"should return a new model with only the specified keys replaced", ^{
    BZRDummyModel *modifiedModel =
        [model modelByOverridingProperty:@keypath(model, optionalProperty) withValue:@"Baz"];

    expect(modifiedModel).toNot.beIdenticalTo(model);
    expect(model.optionalProperty).to.equal(@"Bar");
    expect(modifiedModel.requiredProperty).to.equal(model.requiredProperty);
    expect(modifiedModel.optionalProperty).to.equal(@"Baz");
    expect(modifiedModel.primitiveProperty).to.beTruthy();
  });

  it(@"should return a new model with only the specified primitive key replaced", ^{
    BZRDummyModel *modifiedModel =
        [model modelByOverridingProperty:@keypath(model, primitiveProperty) withValue:@NO];

    expect(modifiedModel).toNot.beIdenticalTo(model);
    expect(model.primitiveProperty).to.beTruthy();
    expect(modifiedModel.requiredProperty).to.equal(model.requiredProperty);
    expect(modifiedModel.optionalProperty).to.equal(@"Bar");
    expect(modifiedModel.primitiveProperty).to.beFalsy();
  });

  it(@"should raise exception if the property key to replace does not exist", ^{
    expect(^{
      BZRDummyModel __unused *modifiedModel =
          [model modelByOverridingProperty:@"baz" withValue:@"Baz"];
    }).to.raise(NSInternalInconsistencyException);
  });
});

SpecEnd
