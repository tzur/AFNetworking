// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "FBRCertificatePinning.h"

NS_ASSUME_NONNULL_BEGIN

NSData *FBRCyclicXorDataWithKey(NSData *buffer, NSData *key);

NSData *FBREncryptCertificate(NSData *buffer, NSString *key) {
  return FBRCyclicXorDataWithKey(buffer, [key dataUsingEncoding:NSUTF8StringEncoding]);
}

NSData *FBRDecryptCertificate(NSData *buffer, NSString *key) {
  return FBRCyclicXorDataWithKey(buffer, [key dataUsingEncoding:NSUTF8StringEncoding]);
}

NSData *FBRCyclicXorDataWithKey(NSData *buffer, NSData *key) {
  NSUInteger keyLength = key.length;
  const char *cKey = (const char *)key.bytes;

  NSMutableData *result = [NSMutableData dataWithLength:buffer.length];
  const char *source = (const char *)buffer.bytes;
  char *target = (char *)result.mutableBytes;

  for (NSUInteger i = 0; i < buffer.length; ++i) {
    target[i] = source[i] ^ cKey[i % keyLength];
  }

  return result;
}

NS_ASSUME_NONNULL_END
