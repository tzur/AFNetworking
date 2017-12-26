// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "NSData+Encryption.h"

#import <CommonCrypto/CommonCrypto.h>

#import "NSData+HexString.h"
#import "NSErrorCodes+LTKit.h"

SpecBegin(NSData_Encryption)

__block NSData *key;

beforeEach(^{
  uint8_t bytes[kCCBlockSizeAES128] = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16};
  key = [NSData dataWithBytes:bytes length:sizeof(bytes)];
});

context(@"decryption", ^{
  it(@"should fail when decrypting empty data", ^{
    NSError *error;
    auto _Nullable data = [[NSData data] lt_decryptWithKey:key error:&error];

    expect(data).to.beNil();
    expect(error.lt_isLTDomain).to.beTruthy();
    expect(error.code).to.equal(LTErrorCodeDecryptionFailed);
  });

  it(@"should fail when decrypting with invalid key", ^{
    uint8_t bytes[kCCBlockSizeAES128 * 2] = {0};
    auto data = [NSData dataWithBytes:bytes length:sizeof(bytes)];

    NSError *error;
    auto _Nullable decrypted = [data lt_decryptWithKey:[NSData data] error:&error];

    expect(decrypted).to.beNil();
    expect(error.lt_isLTDomain).to.beTruthy();
    expect(error.code).to.equal(LTErrorCodeDecryptionFailed);
  });

  it(@"should decrypt zeros data correctly", ^{
    uint8_t bytes[kCCBlockSizeAES128] = {0};
    auto data = [NSData dataWithBytes:bytes length:sizeof(bytes)];

    NSError *error;
    auto _Nullable decrypted = [data lt_decryptWithKey:key error:&error];

    expect(decrypted.length).to.equal(0);
    expect(error).to.beNil();
  });

  it(@"should decrypt data correctly", ^{
    uint8_t bytes[kCCBlockSizeAES128 * 2] = {0xBD, 0x93, 0x16, 0x6B, 0x42, 0xD5, 0x0B, 0x18, 0x8E,
      0x06, 0x0C, 0xF4, 0x15, 0xEE, 0x38, 0xA1, 0x84, 0x73, 0xE6, 0xF6, 0xED, 0x53, 0x62, 0xA4,
      0x52, 0xE3, 0x11, 0x4A, 0x1F, 0xE9, 0x5B, 0x2B};
    auto data = [NSData dataWithBytes:bytes length:sizeof(bytes)];

    NSError *error;
    auto _Nullable decrypted = [data lt_decryptWithKey:key error:&error];

    expect([[NSString alloc] initWithData:nn(decrypted) encoding:NSUTF8StringEncoding])
        .to.equal(@"foobarbaz");
    expect(error).to.beNil();
  });
});

context(@"encryption", ^{
  __block NSString *ivString;
  __block NSData *iv;

  beforeEach(^{
    ivString = @"01030307010303070103030701030307";
    iv = [NSData lt_dataWithHexString:ivString error:nil];
  });

  it(@"should fail when key is invalid", ^{
    uint8_t bytes[kCCBlockSizeAES128 * 2] = {0};
    auto data = [NSData dataWithBytes:bytes length:sizeof(bytes)];

    NSError *error;
    auto _Nullable encrypted = [data lt_encryptWithKey:[NSData data] iv:iv error:&error];

    expect(encrypted).to.beNil();
    expect(error.code).to.equal(LTErrorCodeEncryptionFailed);
  });

  it(@"should assert when IV size is not block size", ^{
    uint8_t bytes[kCCBlockSizeAES128 * 2] = {0};
    auto data = [NSData dataWithBytes:bytes length:sizeof(bytes)];
    auto shortIV = [NSData lt_dataWithHexString:@"000000000000000000000000000000" error:nil];

    expect(^{
      [data lt_encryptWithKey:key iv:shortIV error:nil];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should encrypt empty data and prepend IV", ^{
    auto _Nullable data = [[NSData data] lt_encryptWithKey:key iv:iv error:nil];
    auto expectedBuffer = [ivString stringByAppendingString:@"d57323d04556b0cb139796211e60ad98"];

    expect(data).to.equal([NSData lt_dataWithHexString:expectedBuffer error:nil]);
  });

  it(@"should encrypt data", ^{
    NSError *error;
    auto *data = [@"foobarbaz" dataUsingEncoding:NSUTF8StringEncoding];
    auto expectedBuffer = [ivString stringByAppendingString:@"ff17ab6d4150a1312cc6071ab5c83506"];
    auto expectedData = [NSData lt_dataWithHexString:expectedBuffer error:nil];

    auto _Nullable encrypted = [data lt_encryptWithKey:key iv:iv error:&error];

    expect(encrypted).to.equal(expectedData);
    expect(error).to.beNil();
  });
});

context(@"encryption and decryption", ^{
  it(@"should restore original buffer when after encryption and decryption", ^{
    auto iv = [NSData lt_dataWithHexString:@"01030307010303070103030701030307" error:nil];
    auto data = [@"Luke, I'm your father" dataUsingEncoding:NSUTF8StringEncoding];

    auto _Nullable encrypted = [data lt_encryptWithKey:key iv:iv error:nil];
    auto _Nullable decrypted = [encrypted lt_decryptWithKey:key error:nil];
    expect(decrypted).to.equal(data);
  });
});

SpecEnd
