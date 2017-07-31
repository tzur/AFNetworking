// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "NSData+Encryption.h"

#import <CommonCrypto/CommonCrypto.h>

#import "NSErrorCodes+LTKit.h"

SpecBegin(NSData_Encryption)

__block NSData *key;

beforeEach(^{
  uint8_t bytes[kCCBlockSizeAES128] = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16};
  key = [NSData dataWithBytes:bytes length:sizeof(bytes)];
});

it(@"should fail when decrypting empty data", ^{
  NSError *error;
  NSData * _Nullable data = [[NSData data] lt_decryptWithKey:key error:&error];

  expect(data).to.beNil();
  expect(error.lt_isLTDomain).to.beTruthy();
  expect(error.code).to.equal(LTErrorCodeDecryptionFailed);
});

it(@"should fail when decrypting with invalid key", ^{
  uint8_t bytes[kCCBlockSizeAES128 * 2] = {0};
  NSData *data = [NSData dataWithBytes:bytes length:sizeof(bytes)];

  NSError *error;
  NSData * _Nullable decrypted = [data lt_decryptWithKey:[NSData data] error:&error];

  expect(decrypted).to.beNil();
  expect(error.lt_isLTDomain).to.beTruthy();
  expect(error.code).to.equal(LTErrorCodeDecryptionFailed);
});

it(@"should decrypt zeros data correctly", ^{
  uint8_t bytes[kCCBlockSizeAES128] = {0};
  NSData *data = [NSData dataWithBytes:bytes length:sizeof(bytes)];

  NSError *error;
  NSData * _Nullable decrypted = [data lt_decryptWithKey:key error:&error];

  expect(decrypted.length).to.equal(0);
  expect(error).to.beNil();
});

it(@"should decrypt data correctly", ^{
  uint8_t bytes[kCCBlockSizeAES128 * 2] = {0xBD, 0x93, 0x16, 0x6B, 0x42, 0xD5, 0xB, 0x18, 0x8E, 0x6,
    0xC, 0xF4, 0x15, 0xEE, 0x38, 0xA1, 0x84, 0x73, 0xE6, 0xF6, 0xED, 0x53, 0x62, 0xA4, 0x52, 0xE3,
    0x11, 0x4A, 0x1F, 0xE9, 0x5B, 0x2B};
  NSData *data = [NSData dataWithBytes:bytes length:sizeof(bytes)];

  NSError *error;
  NSData * _Nullable decrypted = [data lt_decryptWithKey:key error:&error];

  expect([[NSString alloc] initWithData:nn(decrypted) encoding:NSUTF8StringEncoding])
      .to.equal(@"foobarbaz");
  expect(error).to.beNil();
});

SpecEnd
