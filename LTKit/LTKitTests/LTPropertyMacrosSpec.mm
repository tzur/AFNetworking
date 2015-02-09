// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTPropertyMacros.h"

/// Used to test the macro-generated bounded primitive properties.
@interface TestClass : NSObject

@property (nonatomic) CGFloat basicProperty;
LTPropertyDeclare(CGFloat, basicProperty, BasicProperty)
@property (nonatomic) NSUInteger uintProperty;
LTPropertyDeclare(NSUInteger, uintProperty, UintProperty)
@property (nonatomic) CGFloat customSetterProperty;
LTPropertyDeclare(CGFloat, customSetterProperty, CustomSetterProperty)

@property (nonatomic) BOOL didCallCustomSetter;

@end

@interface ContainerClass : NSObject

@property (nonatomic) CGFloat basicProperty;
LTPropertyDeclare(CGFloat, basicProperty, BasicProperty)
@property (nonatomic) CGFloat uintProperty;
LTPropertyDeclare(CGFloat, uintProperty, UintProperty)
@property (nonatomic) CGFloat customProxyProperty;
LTPropertyDeclare(CGFloat, customProxyProperty, CustomProxyProperty)

@property (nonatomic) BOOL didCallCustomSetter;
@property (nonatomic) BOOL didCallProxySetter;
@property (strong, nonatomic) TestClass *testClass;

@end

@implementation TestClass

LTProperty(CGFloat, basicProperty, BasicProperty, 0, 1, 0.5);
LTProperty(NSUInteger, uintProperty, UintProperty, 10, 100, 50);
LTPropertyWithoutSetter(CGFloat, customSetterProperty, CustomSetterProperty, -1, 1, 0.1);
- (void)setCustomSetterProperty:(CGFloat)customSetterProperty {
  [self _verifyAndSetCustomSetterProperty:customSetterProperty];
  self.didCallCustomSetter = YES;
}

@end

@implementation ContainerClass

LTPropertyProxy(CGFloat, basicProperty, BasicProperty, self.testClass);
LTPropertyProxyWithoutSetter(CGFloat, uintProperty, UintProperty, self.testClass);
- (void)setUintProperty:(CGFloat)uintProperty {
  self.testClass.uintProperty = uintProperty;
  self.didCallProxySetter = YES;
}
LTPropertyProxyWithoutSetter(CGFloat, customProxyProperty, CustomProxyProperty,
                                   self.testClass, basicProperty, BasicProperty);
- (void)setCustomProxyProperty:(CGFloat)customProxyProperty {
  self.testClass.basicProperty = customProxyProperty;
  self.didCallCustomSetter = YES;
}

@end

@interface TestClass (TestCategory)
@property (strong, nonatomic) NSString *categoryString;
@property (nonatomic) BOOL categoryBool;
@property (nonatomic) CGFloat categoryFloat;
@property (nonatomic) NSInteger categoryInteger;
@property (nonatomic) NSUInteger categoryUnsignedInteger;
@property (nonatomic) LTVector4 categoryVector;
@end

@implementation TestClass (TestCategory)
LTCategoryProperty(NSString *, categoryString, CategoryString);
LTCategoryBoolProperty(categoryBool, CategoryBool);
LTCategoryCGFloatProperty(categoryFloat, CategoryFloat);
LTCategoryIntegerProperty(categoryInteger, CategoryInteger);
LTCategoryUnsignedIntegerProperty(categoryUnsignedInteger, CategoryUnsignedInteger);
LTCategoryStructProperty(LTVector4, categoryVector, CategoryVector);
@end

LTSpecBegin(LTPropertyMarcros)

__block TestClass *testObject;
__block ContainerClass *containerObject;

beforeEach(^{
  testObject = [[TestClass alloc] init];
  containerObject = [[ContainerClass alloc] init];
  containerObject.testClass = [[TestClass alloc] init];
});

it(@"should create min/max/default getters", ^{
  expect(testObject.minBasicProperty).to.equal(0);
  expect(testObject.maxBasicProperty).to.equal(1);
  expect(testObject.defaultBasicProperty).to.equal(0.5);

  expect(testObject.minUintProperty).to.equal(10);
  expect(testObject.maxUintProperty).to.equal(100);
  expect(testObject.defaultUintProperty).to.equal(50);

  expect(testObject.minCustomSetterProperty).to.equal(-1);
  expect(testObject.maxCustomSetterProperty).to.equal(1);
  expect(testObject.defaultCustomSetterProperty).to.equal(0.1);

  expect(containerObject.minBasicProperty).to.equal(0);
  expect(containerObject.maxBasicProperty).to.equal(1);
  expect(containerObject.defaultBasicProperty).to.equal(0.5);

  expect(containerObject.minUintProperty).to.equal(10);
  expect(containerObject.maxUintProperty).to.equal(100);
  expect(containerObject.defaultUintProperty).to.equal(50);

  expect(containerObject.minCustomProxyProperty).to.equal(0);
  expect(containerObject.maxCustomProxyProperty).to.equal(1);
  expect(containerObject.defaultCustomProxyProperty).to.equal(0.5);
});

it(@"should create getters", ^{
  expect(testObject).to.respondTo(@selector(basicProperty));
  expect(testObject).to.respondTo(@selector(uintProperty));
  expect(testObject).to.respondTo(@selector(customSetterProperty));

  expect(containerObject).to.respondTo(@selector(basicProperty));
  expect(containerObject).to.respondTo(@selector(customProxyProperty));
  expect(containerObject).to.respondTo(@selector(uintProperty));
});

it(@"should create setters", ^{
  expect(testObject).to.respondTo(@selector(setBasicProperty:));
  expect(testObject).to.respondTo(@selector(setUintProperty:));
  expect(testObject).to.respondTo(@selector(setCustomSetterProperty:));

  expect(containerObject).to.respondTo(@selector(setBasicProperty:));
  expect(containerObject).to.respondTo(@selector(setUintProperty:));
  expect(containerObject).to.respondTo(@selector(setCustomProxyProperty:));
});

it(@"should have default values", ^{
  expect(testObject.basicProperty).to.equal(testObject.defaultBasicProperty);
  expect(testObject.uintProperty).to.equal(testObject.defaultUintProperty);
  expect(testObject.customSetterProperty).to.equal(testObject.defaultCustomSetterProperty);

  expect(containerObject.basicProperty).to.equal(containerObject.defaultBasicProperty);
  expect(containerObject.uintProperty).to.equal(containerObject.defaultUintProperty);
  expect(containerObject.customProxyProperty).to.equal(containerObject.defaultCustomProxyProperty);
});

it(@"setters should set values", ^{
  expect(testObject.basicProperty).notTo.equal(testObject.minBasicProperty);
  expect(testObject.uintProperty).notTo.equal(testObject.minUintProperty);
  expect(testObject.customSetterProperty).notTo.equal(testObject.minCustomSetterProperty);

  testObject.basicProperty = testObject.minBasicProperty;
  testObject.uintProperty = testObject.minUintProperty;
  testObject.customSetterProperty = testObject.minCustomSetterProperty;

  expect(testObject.basicProperty).to.equal(testObject.minBasicProperty);
  expect(testObject.uintProperty).to.equal(testObject.minUintProperty);
  expect(testObject.customSetterProperty).to.equal(testObject.minCustomSetterProperty);
  
  expect(containerObject.basicProperty).notTo.equal(containerObject.minBasicProperty);
  containerObject.basicProperty = containerObject.minBasicProperty;
  expect(containerObject.basicProperty).to.equal(containerObject.minBasicProperty);

  expect(containerObject.customProxyProperty).to.equal(containerObject.minBasicProperty);
  containerObject.customProxyProperty = containerObject.maxCustomProxyProperty;
  expect(containerObject.customProxyProperty).to.equal(containerObject.maxCustomProxyProperty);

  expect(containerObject.basicProperty).to.equal(containerObject.maxCustomProxyProperty);
});

it(@"should assert values on generated setters", ^{
  expect(^{
    testObject.basicProperty = testObject.minBasicProperty - FLT_EPSILON;
  }).to.raise(NSInvalidArgumentException);
  expect(^{
    testObject.basicProperty = testObject.maxBasicProperty + FLT_EPSILON;
  }).to.raise(NSInvalidArgumentException);
  expect(^{
    testObject.uintProperty = testObject.minUintProperty - 1;
  }).to.raise(NSInvalidArgumentException);
  expect(^{
    testObject.uintProperty = testObject.maxUintProperty + 1;
  }).to.raise(NSInvalidArgumentException);
  expect(^{
    testObject.customSetterProperty = testObject.minCustomSetterProperty - FLT_EPSILON;
  }).to.raise(NSInvalidArgumentException);
  expect(^{
    testObject.customSetterProperty = testObject.maxCustomSetterProperty + FLT_EPSILON;
  }).to.raise(NSInvalidArgumentException);
  expect(^{
    containerObject.basicProperty = containerObject.minBasicProperty - FLT_EPSILON;
  }).to.raise(NSInvalidArgumentException);
  expect(^{
    containerObject.basicProperty = containerObject.maxBasicProperty + FLT_EPSILON;
  }).to.raise(NSInvalidArgumentException);
  expect(^{
    containerObject.customProxyProperty = containerObject.minCustomProxyProperty - FLT_EPSILON;
  }).to.raise(NSInvalidArgumentException);
  expect(^{
    containerObject.customProxyProperty = containerObject.maxCustomProxyProperty + FLT_EPSILON;
  }).to.raise(NSInvalidArgumentException);
});

it(@"should perform custom setter", ^{
  expect(testObject.didCallCustomSetter).to.beFalsy();
  testObject.customSetterProperty = testObject.defaultCustomSetterProperty;
  expect(testObject.didCallCustomSetter).to.beTruthy();
  expect(containerObject.didCallCustomSetter).to.beFalsy();
  containerObject.customProxyProperty = containerObject.defaultCustomProxyProperty;
  expect(containerObject.didCallCustomSetter).to.beTruthy();
  containerObject.uintProperty = containerObject.defaultUintProperty;
  expect(containerObject.didCallProxySetter).to.beTruthy();
});

context(@"category properties", ^{
  it(@"should set and get string property", ^{
    expect(testObject.categoryString).to.beNil();
    testObject.categoryString = @"1";
    expect(testObject.categoryString).to.equal(@"1");
    testObject.categoryString = nil;
    expect(testObject.categoryString).to.beNil();
  });

  it(@"should set and get boolean property", ^{
    expect(testObject.categoryBool).to.beFalsy();
    testObject.categoryBool = YES;
    expect(testObject.categoryBool).to.beTruthy();
    testObject.categoryBool = NO;
    expect(testObject.categoryBool).to.beFalsy();
  });

  it(@"should set and get float property", ^{
    expect(testObject.categoryFloat).to.equal(0);
    testObject.categoryFloat = 0.5;
    expect(testObject.categoryFloat).to.equal(0.5);
    testObject.categoryFloat = 0;
    expect(testObject.categoryFloat).to.equal(0);
  });

  it(@"should set and get integer property", ^{
    expect(testObject.categoryInteger).to.equal(0);
    testObject.categoryInteger = -1;
    expect(testObject.categoryInteger).to.equal(-1);
    testObject.categoryInteger = 0;
    expect(testObject.categoryInteger).to.equal(0);
  });

  it(@"should set and get unsigned integer property", ^{
    expect(testObject.categoryUnsignedInteger).to.equal(0);
    testObject.categoryUnsignedInteger = 1;
    expect(testObject.categoryUnsignedInteger).to.equal(1);
    testObject.categoryUnsignedInteger = 0;
    expect(testObject.categoryUnsignedInteger).to.equal(0);
  });

  it(@"should set and get vector property", ^{
    expect(testObject.categoryVector).to.equal(LTVector4Zero);
    testObject.categoryVector = LTVector4One;
    expect(testObject.categoryVector).to.equal(LTVector4One);
    testObject.categoryVector = LTVector4Zero;
    expect(testObject.categoryVector).to.equal(LTVector4Zero);
  });
});

LTSpecEnd
