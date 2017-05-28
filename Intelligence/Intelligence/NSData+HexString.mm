// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "NSData+HexString.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSData (HexString)

- (NSString *)int_hexString {
  NSMutableString *hexString = [NSMutableString string];
  auto bytes = (const unsigned char *)self.bytes;
  for (NSUInteger i = 0; i < self.length; ++i) {
    [hexString appendFormat:@"%02X", bytes[i]];
  }

  return [hexString copy];
}

@end

NS_ASSUME_NONNULL_END
