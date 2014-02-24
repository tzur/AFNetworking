// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTPropertyMacros.h"

/// Used to test the macro-generated bounded primitive properties.
@interface TestClass : NSObject

LTBoundedPrimitiveProperty(CGFloat, basicProperty, BasicProperty)
LTBoundedPrimitiveProperty(NSUInteger, uintProperty, UintProperty)
LTBoundedPrimitiveProperty(CGFloat, noSetterProperty, NoSetterProperty)
LTBoundedPrimitiveProperty(CGFloat, customSetterProperty, CustomSetterProperty)

@property (nonatomic) BOOL didCallCustomSetter;

@end

@implementation TestClass

LTBoundedPrimitivePropertyImplement(CGFloat, basicProperty, BasicProperty, 0, 1, 0.5);
LTBoundedPrimitivePropertyImplement(NSUInteger, uintProperty, UintProperty, 10, 100, 50);
LTBoundedPrimitivePropertyImplementWithoutSetter(CGFloat, noSetterProperty,
                                                 NoSetterProperty, -1, 0, -0.5);
LTBoundedPrimitivePropertyImplementWithCustomSetter(CGFloat, customSetterProperty,
                                                    CustomSetterProperty, -1, 1, 0.1, ^{
  self.didCallCustomSetter = YES;
});

@end

SpecBegin(LTPropertyMarcros)
__block TestClass *testObject;

beforeEach(^{
  testObject = [[TestClass alloc] init];
});

it(@"should declare constants", ^{
  expect(kMinBasicProperty).to.equal(0);
  expect(kMaxBasicProperty).to.equal(1);
  expect(kDefaultBasicProperty).to.equal(0.5);
  expect(kMinUintProperty).to.equal(10);
  expect(kMaxUintProperty).to.equal(100);
  expect(kDefaultUintProperty).to.equal(50);
  expect(kMinNoSetterProperty).to.equal(-1);
  expect(kMaxNoSetterProperty).to.equal(0);
  expect(kDefaultNoSetterProperty).to.equal(-0.5);
  expect(kMinCustomSetterProperty).to.equal(-1);
  expect(kMaxCustomSetterProperty).to.equal(1);
  expect(kDefaultCustomSetterProperty).to.equal(0.1);
});

it(@"should create getters", ^{
  expect([testObject respondsToSelector:@selector(basicProperty)]).to.beTruthy();
  expect([testObject respondsToSelector:@selector(minBasicProperty)]).to.beTruthy();
  expect([testObject respondsToSelector:@selector(maxBasicProperty)]).to.beTruthy();
  expect([testObject respondsToSelector:@selector(uintProperty)]).to.beTruthy();
  expect([testObject respondsToSelector:@selector(minUintProperty)]).to.beTruthy();
  expect([testObject respondsToSelector:@selector(maxUintProperty)]).to.beTruthy();
  expect([testObject respondsToSelector:@selector(noSetterProperty)]).to.beTruthy();
  expect([testObject respondsToSelector:@selector(minNoSetterProperty)]).to.beTruthy();
  expect([testObject respondsToSelector:@selector(maxNoSetterProperty)]).to.beTruthy();
  expect([testObject respondsToSelector:@selector(customSetterProperty)]).to.beTruthy();
  expect([testObject respondsToSelector:@selector(minCustomSetterProperty)]).to.beTruthy();
  expect([testObject respondsToSelector:@selector(maxCustomSetterProperty)]).to.beTruthy();
});

it(@"should create setters", ^{
  expect([testObject respondsToSelector:@selector(setBasicProperty:)]).to.beTruthy();
  expect([testObject respondsToSelector:@selector(setUintProperty:)]).to.beTruthy();
  expect([testObject respondsToSelector:@selector(setNoSetterProperty:)]).to.beTruthy();
  expect([testObject respondsToSelector:@selector(setCustomSetterProperty:)]).to.beTruthy();
});

it(@"getters should return values", ^{
  expect(testObject.minBasicProperty).to.equal(kMinBasicProperty);
  expect(testObject.maxBasicProperty).to.equal(kMaxBasicProperty);
  expect(testObject.minUintProperty).to.equal(kMinUintProperty);
  expect(testObject.maxUintProperty).to.equal(kMaxUintProperty);
  expect(testObject.minNoSetterProperty).to.equal(kMinNoSetterProperty);
  expect(testObject.maxNoSetterProperty).to.equal(kMaxNoSetterProperty);
  expect(testObject.minCustomSetterProperty).to.equal(kMinCustomSetterProperty);
  expect(testObject.maxCustomSetterProperty).to.equal(kMaxCustomSetterProperty);
});

it(@"setters should set values", ^{
  expect(testObject.basicProperty).notTo.equal(kDefaultBasicProperty);
  expect(testObject.uintProperty).notTo.equal(kDefaultUintProperty);
  expect(testObject.noSetterProperty).notTo.equal(kDefaultNoSetterProperty);
  expect(testObject.customSetterProperty).notTo.equal(kDefaultCustomSetterProperty);
  testObject.basicProperty = kDefaultBasicProperty;
  testObject.uintProperty = kDefaultUintProperty;
  testObject.noSetterProperty = kDefaultNoSetterProperty;
  testObject.customSetterProperty = kDefaultCustomSetterProperty;
  expect(testObject.basicProperty).to.equal(kDefaultBasicProperty);
  expect(testObject.uintProperty).to.equal(kDefaultUintProperty);
  expect(testObject.noSetterProperty).to.equal(kDefaultNoSetterProperty);
  expect(testObject.customSetterProperty).to.equal(kDefaultCustomSetterProperty);
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
});

it(@"should not assert on property without setter", ^{
  expect(^{
    testObject.noSetterProperty = testObject.minNoSetterProperty - FLT_EPSILON;
    testObject.noSetterProperty = testObject.maxNoSetterProperty + FLT_EPSILON;
  }).notTo.raiseAny();
});

it(@"should perform custom setter", ^{
  expect(testObject.didCallCustomSetter).to.beFalsy();
  testObject.customSetterProperty = kDefaultCustomSetterProperty;
  expect(testObject.didCallCustomSetter).to.beTruthy();
});

SpecEnd
