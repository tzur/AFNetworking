// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "NSData+HexString.h"

#import "INTDataHelpers.h"

SpecBegin(NSData_HexString)

it(@"should return empty string if buffer is empty and group is zero", ^{
  NSData *data = [[NSData alloc] init];
  expect([data int_hexString]).to.equal(@"");
});

it(@"should return  hex string", ^{
  std::vector<unsigned char> values{0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef};
  expect([INTVectorToNSData(values) int_hexString]).to.equal(@"0123456789ABCDEF");
});

it(@"should return all zeros if buffer is all zeros", ^{
  std::vector<unsigned char> values{0x00, 0x00, 0x00};
  expect([INTVectorToNSData(values) int_hexString]).to.equal(@"000000");
});

SpecEnd
