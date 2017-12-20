// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "NSString+Hashing.h"

SpecBegin(NSString_Hashing)

it(@"should create correct MD5 hash", ^{
  expect([@"123456" lt_MD5]).to.equal(@"E10ADC3949BA59ABBE56E057F20F883E");
});

it(@"should create correct SHA1 hash", ^{
  expect([@"123456" lt_SHA1]).to.equal(@"7C4A8D09CA3762AF61E59520943DC26494F8941B");
});

it(@"should create correct SHA256 hash", ^{
  expect([@"123456" lt_SHA256])
      .to.equal(@"8D969EEF6ECAD3C29A3A629280E686CF0C3F5D5A86AFF3CA12020C923ADC6C92");
});

it(@"should create correct HMAC SHA256 hash", ^{
  expect([@"123456" lt_HMACSHA256WithKey:nn([@"foo" dataUsingEncoding:NSUTF8StringEncoding])])
      .to.equal(@"A4A1015C95080269A487A3F2A83A5511BD852237421A9F8F27776A15CCA733EC");
});

SpecEnd
