// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "NSData+Encryption.h"

#import <CommonCrypto/CommonCrypto.h>

#import "NSErrorCodes+LTKit.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSData (Encryption)

- (nullable instancetype)lt_decryptWithKey:(NSData *)key error:(NSError *__autoreleasing *)error {
  if (self.length < kCCBlockSizeAES128) {
    if (error) {
      *error = [NSError
                lt_errorWithCode:LTErrorCodeDecryptionFailed
                description:@"Data is too small: %lu, expected at least %d bytes",
                (unsigned long)self.length, kCCBlockSizeAES128];
    }
    return nil;
  }

  NSData *iv = [NSData dataWithBytesNoCopy:(void *)self.bytes
                                    length:kCCBlockSizeAES128 freeWhenDone:NO];
  NSData *data = [NSData dataWithBytesNoCopy:((uint8_t *)self.bytes + kCCBlockSizeAES128)
                                      length:self.length - kCCBlockSizeAES128 freeWhenDone:NO];

  NSMutableData *decryptedData = [NSMutableData dataWithLength:data.length];
  // rdar://31626540: on iOS 10.3 and 32-bit systems, CCCrypt returns kCCBufferTooSmall for
  // decrypted data of length 0.
  if (!decryptedData.length) {
    return decryptedData;
  }

  size_t length;
  CCCryptorStatus status = CCCrypt(kCCDecrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding,
                                   key.bytes, key.length, iv.bytes, data.bytes, data.length,
                                   decryptedData.mutableBytes, decryptedData.length, &length);
  if (status != kCCSuccess) {
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeDecryptionFailed
                             description:@"CCCrypt failed with status %d", status];
    }
    return nil;
  }

  decryptedData.length = length;
  return decryptedData;
}

- (nullable instancetype)lt_encryptWithKey:(NSData *)key iv:(NSData *)iv
                                     error:(NSError *__autoreleasing *)error {
  LTParameterAssert(iv.length == kCCBlockSizeAES128, @"IV must be exactly %u bytes long",
                    kCCBlockSizeAES128);
  NSMutableData *data = [NSMutableData dataWithLength:self.length + (kCCBlockSizeAES128 * 2)];

  void *encryptedBytes = (uint8_t *)data.mutableBytes + kCCBlockSizeAES128;
  size_t encryptedBytesLength = data.length - kCCBlockSizeAES128;

  size_t length;
  CCCryptorStatus status = CCCrypt(kCCEncrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding, key.bytes,
                                   key.length, iv.bytes, self.bytes, self.length, encryptedBytes,
                                   encryptedBytesLength, &length);
  if (status != kCCSuccess) {
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeEncryptionFailed
                             description:@"CCCrypt failed with status %d", status];
    }
    return nil;
  }
  [data replaceBytesInRange:NSMakeRange(0, kCCBlockSizeAES128) withBytes:iv.bytes];

  data.length = length + kCCBlockSizeAES128;
  return data;
}

@end

NS_ASSUME_NONNULL_END
