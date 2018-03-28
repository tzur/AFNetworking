// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTNullability.h"

SpecBegin(LTNullability)

it(@"should return original ObjC object if not nil", ^{
  NSString * _Nullable object = @"foo";
  expect(nn(object)).to.equal(object);
});

it(@"should return default ObjC object if nil", ^{
  NSString * _Nullable object = nil;
  NSString *defaultValue = @"bar";
  expect(nn(object, defaultValue)).to.equal(defaultValue);
});

it(@"should return original pointer if not nil", ^{
  int object = 7;
  int * _Nullable ptr = &object;

  expect(nn(ptr)).to.equal(ptr);
});

it(@"should return default pointer if nil", ^{
  int object = 7;
  int * _Nullable ptr = nil;
  int *defaultValue = &object;

  expect(nn(ptr, defaultValue)).to.equal(&object);
});

it(@"should convert convertible type from default value to object", ^{
  id _Nullable object = nil;
  NSString *defaultValue = @"bar";

  expect(nn(object, defaultValue)).to.equal(defaultValue);
});

SpecEnd
