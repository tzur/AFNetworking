// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "NSData+HexString.h"

#import "LTDataHelpers.h"

SpecBegin(NSData_HexString)

context(@"hexString", ^{
  it(@"should return empty string if buffer is empty and group is zero", ^{
    NSData *data = [[NSData alloc] init];
    expect([data lt_hexString]).to.equal(@"");
  });

  it(@"should return hex string", ^{
    std::vector<unsigned char> values{0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef};
    expect([LTVectorToNSData(values) lt_hexString]).to.equal(@"0123456789ABCDEF");
  });

  it(@"should return all zeros if buffer is all zeros", ^{
    std::vector<unsigned char> values{0x00, 0x00, 0x00};
    expect([LTVectorToNSData(values) lt_hexString]).to.equal(@"000000");
  });
});

SpecEnd
