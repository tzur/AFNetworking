// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "NSString+Hashing.h"

#import <CommonCrypto/CommonCrypto.h>

NS_ASSUME_NONNULL_BEGIN

@implementation NSString (Hashes)

- (NSString *)lt_MD5 {
  const char *string = [self cStringUsingEncoding:NSUTF8StringEncoding];
  NSData *data = [NSData dataWithBytes:string length:self.length];

  uint8_t digest[CC_MD5_DIGEST_LENGTH];
  CC_MD5(data.bytes, (CC_LONG)data.length, digest);

  return [self lt_hexStringWithBytes:digest andSize:CC_MD5_DIGEST_LENGTH];
}

- (NSString *)lt_SHA1 {
  const char *string = [self cStringUsingEncoding:NSUTF8StringEncoding];
  NSData *data = [NSData dataWithBytes:string length:self.length];

  // Digest.
  uint8_t digest[CC_SHA1_DIGEST_LENGTH];
  CC_SHA1(data.bytes, (CC_LONG)data.length, digest);

  return [self lt_hexStringWithBytes:digest andSize:CC_SHA1_DIGEST_LENGTH];
}

- (NSString *)lt_hexStringWithBytes:(uint8_t *)bytes andSize:(NSUInteger)size {
  NSMutableString *output = [NSMutableString stringWithCapacity:size * 2];
  for (NSUInteger i = 0; i < size; ++i) {
    [output appendFormat:@"%02x", bytes[i]];
  }
  return output;
}

@end

NS_ASSUME_NONNULL_END
