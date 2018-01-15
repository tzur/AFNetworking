// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "NSString+Hashing.h"

#import "NSData+Hashing.h"
#import "NSData+HexString.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSString (Hashing)

- (NSString *)lt_MD5 {
  return [[nn([self dataUsingEncoding:NSUTF8StringEncoding]) lt_MD5] lt_hexString];
}

- (NSString *)lt_SHA1 {
  return [[nn([self dataUsingEncoding:NSUTF8StringEncoding]) lt_SHA1] lt_hexString];
}

- (NSString *)lt_SHA256 {
  return [[nn([self dataUsingEncoding:NSUTF8StringEncoding]) lt_SHA256] lt_hexString];
}

- (NSString *)lt_HMACSHA256WithKey:(NSData *)key {
  return [[nn([self dataUsingEncoding:NSUTF8StringEncoding]) lt_HMACSHA256WithKey:key]
          lt_hexString];
}

@end

NS_ASSUME_NONNULL_END
