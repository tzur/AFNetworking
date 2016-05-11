// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "NSObject+PropertyAccessors.h"

@interface LTPropertyAccessorsTestObject : NSObject

@property (nonatomic) CGFloat value;
LTPropertyDeclare(CGFloat, value, Value);

@end

@implementation LTPropertyAccessorsTestObject

LTProperty(CGFloat, value, Value, 2, 5, 2.5);

@end

SpecBegin(NSObject_PropertyAccessors)

__block LTPropertyAccessorsTestObject *object;

beforeEach(^{
  object = [[LTPropertyAccessorsTestObject alloc] init];
});

it(@"should return min value for key path", ^{
  expect([object lt_minValueForKeyPath:@"value"]).to.equal(@2);
});

it(@"should return max value for key path", ^{
  expect([object lt_maxValueForKeyPath:@"value"]).to.equal(@5);
});

it(@"should return default value for key path", ^{
  expect([object lt_defaultValueForKeyPath:@"value"]).to.equal(@2.5);
});

SpecEnd
