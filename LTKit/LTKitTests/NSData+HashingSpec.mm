// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "NSData+Hashing.h"

#import "NSData+HexString.h"

SpecBegin(NSData_Hashing)

it(@"should create correct MD5 hash", ^{
  expect([[@"123456" dataUsingEncoding:NSUTF8StringEncoding] lt_MD5])
      .to.equal(nn([NSData lt_dataWithHexString:@"e10adc3949ba59abbe56e057f20f883e" error:nil]));
});

it(@"should create correct SHA1 hash", ^{
  expect([[@"123456" dataUsingEncoding:NSUTF8StringEncoding] lt_SHA1])
      .to.equal(nn([NSData lt_dataWithHexString:@"7c4a8d09ca3762af61e59520943dc26494f8941b"
                                          error:nil]));
});

it(@"should create correct SHA256 hash", ^{
  expect([[@"123456" dataUsingEncoding:NSUTF8StringEncoding] lt_SHA256])
      .to.equal(nn([NSData lt_dataWithHexString:@"8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca1"
                 "2020c923adc6c92" error:nil]));
});

it(@"should create correct HMAC SHA256 hash", ^{
  expect([[@"123456" dataUsingEncoding:NSUTF8StringEncoding]
          lt_HMACSHA256WithKey:nn([@"foo" dataUsingEncoding:NSUTF8StringEncoding])])
      .to.equal(nn([NSData lt_dataWithHexString:@"a4a1015c95080269a487a3f2a83a5511bd852237421a9f8f2"
                    "7776a15cca733ec" error:nil]));
});

SpecEnd
