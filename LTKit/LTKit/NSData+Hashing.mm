// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "NSData+Hashing.h"

#import <CommonCrypto/CommonCrypto.h>

NS_ASSUME_NONNULL_BEGIN

@implementation NSData (Hashing)

- (NSData *)lt_MD5 {
  uint8_t digest[CC_MD5_DIGEST_LENGTH];
  CC_MD5(self.bytes, (CC_LONG)self.length, digest);

  return [NSData dataWithBytes:digest length:sizeof(digest)];
}

- (NSData *)lt_SHA1 {
  uint8_t digest[CC_SHA1_DIGEST_LENGTH];
  CC_SHA1(self.bytes, (CC_LONG)self.length, digest);

  return [NSData dataWithBytes:digest length:sizeof(digest)];
}

- (NSData *)lt_SHA256 {
  uint8_t digest[CC_SHA256_DIGEST_LENGTH];
  CC_SHA256(self.bytes, (CC_LONG)self.length, digest);

  return [NSData dataWithBytes:digest length:sizeof(digest)];
}

- (NSData *)lt_HMACSHA256WithKey:(NSData *)key {
  uint8_t digest[CC_SHA256_DIGEST_LENGTH];
  CCHmac(kCCHmacAlgSHA256, key.bytes, (CC_LONG)key.length, self.bytes, (CC_LONG)self.length,
         digest);

  return [NSData dataWithBytes:digest length:sizeof(digest)];
}

@end

NS_ASSUME_NONNULL_END
