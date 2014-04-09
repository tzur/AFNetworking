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
  expect(testObject.minBasicProperty).to.equal(0);
  expect(testObject.maxBasicProperty).to.equal(1);
  expect(testObject.defaultBasicProperty).to.equal(0.5);
  expect(testObject.minUintProperty).to.equal(10);
  expect(testObject.maxUintProperty).to.equal(100);
  expect(testObject.defaultUintProperty).to.equal(50);
  expect(testObject.minNoSetterProperty).to.equal(-1);
  expect(testObject.maxNoSetterProperty).to.equal(0);
  expect(testObject.defaultNoSetterProperty).to.equal(-0.5);
  expect(testObject.minCustomSetterProperty).to.equal(-1);
  expect(testObject.maxCustomSetterProperty).to.equal(1);
  expect(testObject.defaultCustomSetterProperty).to.equal(0.1);
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

it(@"setters should set values", ^{
  expect(testObject.basicProperty).notTo.equal(testObject.defaultBasicProperty);
  expect(testObject.uintProperty).notTo.equal(testObject.defaultUintProperty);
  expect(testObject.noSetterProperty).notTo.equal(testObject.defaultNoSetterProperty);
  expect(testObject.customSetterProperty).notTo.equal(testObject.defaultCustomSetterProperty);
  testObject.basicProperty = testObject.defaultBasicProperty;
  testObject.uintProperty = testObject.defaultUintProperty;
  testObject.noSetterProperty = testObject.defaultNoSetterProperty;
  testObject.customSetterProperty = testObject.defaultCustomSetterProperty;
  expect(testObject.basicProperty).to.equal(testObject.defaultBasicProperty);
  expect(testObject.uintProperty).to.equal(testObject.defaultUintProperty);
  expect(testObject.noSetterProperty).to.equal(testObject.defaultNoSetterProperty);
  expect(testObject.customSetterProperty).to.equal(testObject.defaultCustomSetterProperty);
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
  testObject.customSetterProperty = testObject.defaultCustomSetterProperty;
  expect(testObject.didCallCustomSetter).to.beTruthy();
});

SpecEnd
