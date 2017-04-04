// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRModel.h"

static NSString * const kInvalidValidPropertyValue = @"Baz";
static const NSUInteger kValidationErrorCode = 1337;

/// Validator used to validate that a given keypath is a legal path to variable.
@interface BZRKeypathValidator : NSObject

/// Returns \c YES if \c keypath is a valid keypath, \c NO otherwise.
+ (BOOL)isKeypathValid:(NSString *)keypath;

@end

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

@interface BZRComplexDummyModel : BZRModel

/// Array of dummy models.
@property (readonly, nonatomic) NSArray<BZRDummyModel *> *dummyModels;

/// A single dummy model.
@property (readonly, nonatomic, nullable) BZRDummyModel *singleDummyModel;

/// An array of complex models.
@property (readonly, nonatomic, nullable) NSArray<BZRComplexDummyModel *> *complexModels;

/// An array of non \c BZRModel objects.
@property (readonly, nonatomic, nullable) NSArray<NSNumber *> *nonModelArray;

@end

@implementation BZRComplexDummyModel

+ (NSSet<NSString *> *)optionalPropertyKeys {
  return [NSSet setWithArray:@[
    @instanceKeypath(BZRComplexDummyModel, singleDummyModel),
    @instanceKeypath(BZRComplexDummyModel, complexModels)
  ]];
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

context(@"overriding property", ^{
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

context(@"overriding property by keypath", ^{
  __block BZRDummyModel *dummyModel;
  __block BZRComplexDummyModel *complexModel;

  beforeEach(^{
    dummyModel = [[BZRDummyModel alloc] initWithDictionary:@{
      @instanceKeypath(BZRDummyModel, requiredProperty): @"required",
      @instanceKeypath(BZRDummyModel, optionalProperty): @"optional",
      @instanceKeypath(BZRDummyModel, primitiveProperty): @YES
    } error:nil];

    BZRDummyModel *firstDummyModel =
        [dummyModel modelByOverridingProperty:@keypath(dummyModel, requiredProperty)
                                    withValue:@"firstRequired"];
    BZRDummyModel *secondDummyModel =
        [dummyModel modelByOverridingProperty:@keypath(dummyModel, requiredProperty)
                                    withValue:@"secondRequired"];
    BZRDummyModel *singleDummyModel =
        [dummyModel modelByOverridingProperty:@keypath(dummyModel, requiredProperty)
                                    withValue:@"singleRequired"];

    complexModel = [[BZRComplexDummyModel alloc] initWithDictionary:@{
      @instanceKeypath(BZRComplexDummyModel, dummyModels): @[firstDummyModel, secondDummyModel],
      @instanceKeypath(BZRComplexDummyModel, singleDummyModel): singleDummyModel,
      @instanceKeypath(BZRComplexDummyModel, nonModelArray): @[@1337, @14]
    } error:nil];
  });

  it(@"should raise error if one of the properties in keypath is not found", ^{
    expect(^{
      [complexModel modelByOverridingPropertyAtKeypath:@"singleDummyModel.nonExistentProperty"
                                   withValue:@"barbar"];
    }).to.raise(NSInternalInconsistencyException);
  });

  it(@"should raise error if given keypath describes path to a non existent complex property", ^{
    expect(^{
      [complexModel modelByOverridingPropertyAtKeypath:
       @"singleDummyModel.nonExistentProperty.nestedOfNonExistentProperty" withValue:@"barbar"];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise error if given keypath describes path to property that is not a BZRModel", ^{
    expect(^{
      [complexModel modelByOverridingPropertyAtKeypath:
       @"singleDummyModel.primitiveProperty.nestedPropertyOfPrimitive" withValue:@"barbar"];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should replace key successfully", ^{
    BZRDummyModel *modifiedModel =
        [dummyModel modelByOverridingPropertyAtKeypath:@keypath(dummyModel.requiredProperty)
                                             withValue:@"replacedRequired"];

    expect(modifiedModel.requiredProperty).to.equal(@"replacedRequired");
    expect(modifiedModel.optionalProperty).to.equal(dummyModel.optionalProperty);
    expect(modifiedModel.primitiveProperty).to.equal(dummyModel.primitiveProperty);
  });

  context(@"modifying nested properties", ^{
    it(@"should override model with only the keypath replaced", ^{
      BZRComplexDummyModel *modifiedModel =
          [complexModel modelByOverridingPropertyAtKeypath:
           @keypath(complexModel.singleDummyModel.optionalProperty) withValue:@"replacedOptional"];

      expect(modifiedModel.singleDummyModel.optionalProperty).to.equal(@"replacedOptional");
      expect(modifiedModel.singleDummyModel.requiredProperty).to
          .equal(complexModel.singleDummyModel.requiredProperty);
      expect(modifiedModel.singleDummyModel.primitiveProperty).to
          .equal(complexModel.singleDummyModel.primitiveProperty);
    });
  });

  context(@"modifying array properties", ^{
    it(@"should modify object at index", ^{
      BZRComplexDummyModel *modifiedModel =
          [complexModel modelByOverridingPropertyAtKeypath:@"dummyModels[1]" withValue:dummyModel];

      expect(modifiedModel.dummyModels[1]).to.equal(dummyModel);
    });

    it(@"should not modify other elements in array", ^{
      BZRComplexDummyModel *modifiedModel =
          [complexModel modelByOverridingPropertyAtKeypath:@"dummyModels[1]" withValue:dummyModel];

      expect(modifiedModel.dummyModels[0]).to.equal(complexModel.dummyModels[0]);
    });

    it(@"should successfully insert nil into array", ^{
      BZRComplexDummyModel *modifiedModel =
          [complexModel modelByOverridingPropertyAtKeypath:@"dummyModels[1]" withValue:nil];

      expect(modifiedModel.dummyModels[1]).to.equal([NSNull null]);
    });

    it(@"should raise exception if array is out of range", ^{
      expect(^{
        [complexModel modelByOverridingPropertyAtKeypath:@"dummyModels[2]" withValue:dummyModel];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise exception if property is not an array", ^{
      expect(^{
        [complexModel modelByOverridingPropertyAtKeypath:@"singleDummyModel[1]"
                                               withValue:dummyModel];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise exception if keypath contains element in array that is not the last in "
       "keypath and is not a BZRModel", ^{
      expect(^{
        [complexModel modelByOverridingPropertyAtKeypath:@"nonModelArray[0].nestedNonExistentKey"
                                               withValue:nil];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should modify whole array", ^{
      BZRComplexDummyModel *modifiedModel =
          [complexModel modelByOverridingPropertyAtKeypath:@"dummyModels" withValue:@[dummyModel]];

      expect(modifiedModel.dummyModels).to.equal(@[dummyModel]);
    });

    it(@"should modify property of object at index", ^{
      BZRComplexDummyModel *modifiedModel =
          [complexModel modelByOverridingPropertyAtKeypath:@"dummyModels[0].primitiveProperty"
                                                 withValue:@NO];

      expect(modifiedModel.dummyModels.firstObject.primitiveProperty).to.equal(@NO);
      expect(modifiedModel.dummyModels.lastObject).to.equal(complexModel.dummyModels.lastObject);
    });

    it(@"should modify property of object at nested index", ^{
      BZRComplexDummyModel *underlyingComplexModel =
          [complexModel modelByOverridingProperty:@keypath(complexModel, singleDummyModel)
                                        withValue:dummyModel];
      complexModel = [complexModel modelByOverridingProperty:@keypath(complexModel, complexModels)
                                                   withValue:@[underlyingComplexModel]];

      BZRComplexDummyModel *modifiedModel = [complexModel
          modelByOverridingPropertyAtKeypath:@"complexModels[0].dummyModels[1].requiredProperty"
                                   withValue:@"replacedRequired"];

      expect(modifiedModel.complexModels[0].dummyModels[1].requiredProperty).to
          .equal(@"replacedRequired");
    });
  });
});

context(@"validating keypath", ^{
  it(@"should return YES for valid keypaths", ^{
    expect([BZRKeypathValidator isKeypathValid:@"foo"]).to.beTruthy();
    expect([BZRKeypathValidator isKeypathValid:@"foo[0]"]).to.beTruthy();
    expect([BZRKeypathValidator isKeypathValid:@"foo[1].bar"]).to.beTruthy();
    expect([BZRKeypathValidator isKeypathValid:@"foo[0].bar[2].baz"]).to.beTruthy();
    expect([BZRKeypathValidator isKeypathValid:@"foo"]).to.beTruthy();
    expect([BZRKeypathValidator isKeypathValid:@"_foo"]).to.beTruthy();
    expect([BZRKeypathValidator isKeypathValid:@"foo_bar"]).to.beTruthy();
  });

  it(@"should return NO for invalid keypaths", ^{
    expect([BZRKeypathValidator isKeypathValid:@"foo[]"]).to.beFalsy();
    expect([BZRKeypathValidator isKeypathValid:@"foo]"]).to.beFalsy();
    expect([BZRKeypathValidator isKeypathValid:@"fo]o["]).to.beFalsy();
    expect([BZRKeypathValidator isKeypathValid:@"foo["]).to.beFalsy();
    expect([BZRKeypathValidator isKeypathValid:@"f[oo]"]).to.beFalsy();
    expect([BZRKeypathValidator isKeypathValid:@"]"]).to.beFalsy();
    expect([BZRKeypathValidator isKeypathValid:@"12"]).to.beFalsy();
    expect([BZRKeypathValidator isKeypathValid:@"foo[1]."]).to.beFalsy();
    expect([BZRKeypathValidator isKeypathValid:@"foo.[1]"]).to.beFalsy();
    expect([BZRKeypathValidator isKeypathValid:@"foo[1][2]"]).to.beFalsy();
    expect([BZRKeypathValidator isKeypathValid:@"foo[1."]).to.beFalsy();
    expect([BZRKeypathValidator isKeypathValid:@"foo[-1]"]).to.beFalsy();
    expect([BZRKeypathValidator isKeypathValid:@"foo."]).to.beFalsy();
    expect([BZRKeypathValidator isKeypathValid:@"foo[2]foo2"]).to.beFalsy();
    expect([BZRKeypathValidator isKeypathValid:@"foo.foo2[4].foo4."]).to.beFalsy();
  });
});

SpecEnd
