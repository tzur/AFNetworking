// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "NSObject+DynamicDispatch.h"

@interface LTDynamicDispatchObject : NSObject

/// \c YES when the void method has been called.
@property (nonatomic) BOOL voidMethodCalled;

/// Value that is given as argument.
@property (strong, nonatomic) NSNumber *value;

/// Value that is given as another argument.
@property (strong, nonatomic) NSNumber *anotherValue;

@end

@implementation LTDynamicDispatchObject

- (void)voidMethod {
  self.voidMethodCalled = YES;
}

- (void)voidMethodWithValue:(NSNumber *)value {
  self.value = value;
}

- (void)voidMethodWithValue:(NSNumber *)value anotherValue:(NSNumber *)anotherValue {
  self.value = value;
  self.anotherValue = anotherValue;
}

- (NSNumber *)nonVoidMethod {
  return @(0.5);
}

- (NSNumber *)nonVoidMethodWithValue:(NSNumber *)value {
  self.value = value;
  return @([value doubleValue] + 0.5);
}

- (NSNumber *)nonVoidMethodWithValue:(NSNumber *)value anotherValue:(NSNumber *)anotherValue {
  self.value = value;
  self.anotherValue = anotherValue;
  return @([value doubleValue] * [anotherValue doubleValue]);
}

@end

SpecBegin(NSObject_DynamicDispatch)

__block LTDynamicDispatchObject *object;

beforeEach(^{
  object = [[LTDynamicDispatchObject alloc] init];
});

context(@"dispatching selector without return value", ^{
  it(@"should do nothing and return nil if selector doesn't exist", ^{
    expect([object lt_dispatchSelector:@selector(intValue)]).to.beNil();
    expect([object lt_dispatchSelector:@selector(intValue) withObject:@7]).to.beNil();
    expect([object lt_dispatchSelector:@selector(intValue) withObject:@7 withObject:@8]).to.beNil();
  });

  it(@"should dispatch selector if exists", ^{
    expect([object lt_dispatchSelector:@selector(voidMethod)]).to.beNil();
    expect(object.voidMethodCalled).to.beTruthy();

    expect([object lt_dispatchSelector:@selector(voidMethodWithValue:) withObject:@7]).to.beNil();
    expect(object.value).to.equal(@7);

    expect([object lt_dispatchSelector:@selector(voidMethodWithValue:anotherValue:)
                            withObject:@5 withObject:@8]).to.beNil();
    expect(object.value).to.equal(@5);
    expect(object.anotherValue).to.equal(@8);
  });
});

context(@"dispatching selector with return value", ^{
  it(@"should do nothing and return nil if selector doesn't exist", ^{
    expect([object lt_dispatchSelector:@selector(intValue)]).to.beNil();
    expect([object lt_dispatchSelector:@selector(intValue) withObject:@7]).to.beNil();
    expect([object lt_dispatchSelector:@selector(intValue)
                            withObject:@7
                            withObject:@8]).to.beNil();
  });

  it(@"should dispatch selector if exists", ^{
    NSNumber *value = [object lt_dispatchSelector:@selector(nonVoidMethod)];
    expect(value).to.equal(@0.5);

    value = [object lt_dispatchSelector:@selector(nonVoidMethodWithValue:) withObject:@7];
    expect(object.value).to.equal(@7);
    expect(value).to.equal(@7.5);

    value = [object lt_dispatchSelector:@selector(nonVoidMethodWithValue:anotherValue:)
                             withObject:@7 withObject:@8];
    expect(object.value).to.equal(@7);
    expect(object.anotherValue).to.equal(@8);
    expect(value).to.equal(@56);
  });
});

SpecEnd
