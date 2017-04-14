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

@end

NS_ASSUME_NONNULL_END
