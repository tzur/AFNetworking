// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "NSData+Base64.h"

static NSData *LTDataFromVector(const std::vector<uint8_t>& vec) {
  return [[NSData alloc] initWithBytes:vec.data() length:vec.size()];
}

SpecBegin(NSData_Base64)

it(@"should decode url safe base64 string to data", ^{
  expect([[NSData alloc] initWithURLSafeBase64EncodedString:@"_-_fzw"])
      .to.equal(LTDataFromVector({0xff, 0xef, 0xdf, 0xcf}));
  expect([[NSData alloc] initWithURLSafeBase64EncodedString:@"_-_f"])
      .to.equal(LTDataFromVector({0xff, 0xef, 0xdf}));
  expect([[NSData alloc] initWithURLSafeBase64EncodedString:@"_-8"])
      .to.equal(LTDataFromVector({0xff, 0xef}));
});

it(@"should return nil when input is not legal url safe base64 string", ^{
  auto data = [[NSData alloc] initWithURLSafeBase64EncodedString:@"_-\t_fz\nw"];
  expect(data).to.beNil();
});

it(@"should convert to base64", ^{
  expect([LTDataFromVector({0xff, 0xef, 0xdf, 0xcf}) lt_base64]).to.equal(@"/+/fzw==");
  expect([LTDataFromVector({0xff, 0xef, 0xdf}) lt_base64]).to.equal(@"/+/f");
  expect([LTDataFromVector({0xff, 0xef}) lt_base64]).to.equal(@"/+8=");
});

it(@"should convert to url safe base64", ^{
  expect([LTDataFromVector({0xff, 0xef, 0xdf, 0xcf}) lt_urlSafeBase64]).to.equal(@"_-_fzw");
  expect([LTDataFromVector({0xff, 0xef, 0xdf}) lt_urlSafeBase64]).to.equal(@"_-_f");
  expect([LTDataFromVector({0xff, 0xef}) lt_urlSafeBase64]).to.equal(@"_-8");
});

SpecEnd
