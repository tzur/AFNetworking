// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "NSData+Base64.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSData (Base64)

- (nullable instancetype)initWithURLSafeBase64EncodedString:(NSString *)urlSafeBase64String {
  NSUInteger paddingLength = (4 - (urlSafeBase64String.length % 4)) % 4;
  auto base64 = [[[urlSafeBase64String stringByReplacingOccurrencesOfString:@"-" withString:@"+"]
                  stringByReplacingOccurrencesOfString:@"_" withString:@"/"]
                 stringByPaddingToLength:(urlSafeBase64String.length + paddingLength)
                 withString:@"=" startingAtIndex:0];
  return [[NSData alloc] initWithBase64EncodedString:base64 options:0];
}

- (NSString *)lt_base64 {
  return [self base64EncodedStringWithOptions:0];
}

- (NSString *)lt_urlSafeBase64 {
  return [[[[self base64EncodedStringWithOptions:0]
            stringByReplacingOccurrencesOfString:@"+" withString:@"-"]
            stringByReplacingOccurrencesOfString:@"/" withString:@"_"]
            stringByReplacingOccurrencesOfString:@"=" withString:@""];
}

@end

NS_ASSUME_NONNULL_END
