// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "NSData+HexString.h"

#import "LTDataHelpers.h"
#import "NSErrorCodes+LTKit.h"

SpecBegin(NSData_HexString)

context(@"hexString", ^{
  it(@"should return empty string if buffer is empty and group is zero", ^{
    NSData *data = [NSData data];
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

context(@"dataWithHexString", ^{
  it(@"should retrun nil and set error if the string length is not even", ^{
    NSError *error;
    auto returnedData = [NSData lt_dataWithHexString:@"AAA" error:&error];

    expect(returnedData).to.beNil();
    expect(error.lt_isLTDomain).to.beTruthy();
    expect(error.code).to.equal(LTErrorCodeHexDecodingFailed);
  });

  it(@"should retrun nil and set error if the second char in a hex string is invalid", ^{
    NSError *error;
    auto returnedData = [NSData lt_dataWithHexString:@"A-" error:&error];

    expect(returnedData).to.beNil();
    expect(error.lt_isLTDomain).to.beTruthy();
    expect(error.code).to.equal(LTErrorCodeHexDecodingFailed);
  });

  it(@"should retrun nil and set error if the string contains invalid chars", ^{
    NSError *error;
    auto returnedData = [NSData lt_dataWithHexString:@"-DEAD-BEEF" error:&error];

    expect(returnedData).to.beNil();
    expect(error.lt_isLTDomain).to.beTruthy();
    expect(error.code).to.equal(LTErrorCodeHexDecodingFailed);
  });

  it(@"should return nil and set error if the string is an invalid hex representation", ^{
    NSError *error;
    auto returnedData = [NSData lt_dataWithHexString:@"AAZA" error:&error];

    expect(returnedData).to.beNil();
    expect(error.lt_isLTDomain).to.beTruthy();
    expect(error.code).to.equal(LTErrorCodeHexDecodingFailed);
  });

  it(@"should return empty string if buffer is empty and group is zero", ^{
    expect([NSData lt_dataWithHexString:@"" error:nil]).to.equal([NSData data]);
  });

  it(@"should convert hex string to binary data", ^{
    std::vector<unsigned char> values{0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef};
    expect([NSData lt_dataWithHexString:@"0123456789ABCDEF" error:nil]).to
        .equal(LTVectorToNSData(values));
  });

  it(@"should convert lowercase hex string to binary data", ^{
    std::vector<unsigned char> values{0xab, 0xcd, 0xef, 0x01};
    expect([NSData lt_dataWithHexString:@"abcdef01" error:nil]).to.equal(LTVectorToNSData(values));
  });

  it(@"should return all zeros if hexString is from zeros only", ^{
    std::vector<unsigned char> values{0x00, 0x00, 0x00};
    expect([NSData lt_dataWithHexString:@"000000" error:nil]).to.equal(LTVectorToNSData(values));
  });
});

SpecEnd
