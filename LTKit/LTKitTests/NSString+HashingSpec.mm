// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "NSString+Hashing.h"

SpecBegin(NSString_Hashing)

it(@"should create correct MD5 hash", ^{
  expect([@"123456" lt_MD5]).to.equal(@"e10adc3949ba59abbe56e057f20f883e");
});

it(@"should create correct SHA1 hash", ^{
  expect([@"123456" lt_SHA1]).to.equal(@"7c4a8d09ca3762af61e59520943dc26494f8941b");
});

it(@"should create correct HMAC SHA256 hash", ^{
  expect([@"123456" lt_HMACSHA256WithKey:nn([@"foo" dataUsingEncoding:NSUTF8StringEncoding])])
      .to.equal(@"a4a1015c95080269a487a3f2a83a5511bd852237421a9f8f27776a15cca733ec");
});

SpecEnd
