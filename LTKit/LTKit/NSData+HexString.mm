// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "NSData+HexString.h"

#import "NSErrorCodes+LTKit.h"

NS_ASSUME_NONNULL_BEGIN

static inline BOOL LTIsValidHexChar(char c) {
  return (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F') || (c >= '0' && c <= '9');
}

@implementation NSData (HexString)

+ (nullable NSData *)lt_dataWithHexString:(NSString *)hexString
                                    error:(NSError * __autoreleasing *)error {
  if (hexString.length % 2 != 0) {
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeHexDecodingFailed
                             description:@"Given string's length should be even, got: %lu",
                (unsigned long)hexString.length];
    }
    return nil;
  }

  auto mutableData = [NSMutableData dataWithCapacity:hexString.length / 2];
  const char *cHexString = [hexString UTF8String];

  for (NSUInteger i = 0; i < hexString.length; i += 2) {
    if (!LTIsValidHexChar(cHexString[i]) || !LTIsValidHexChar(cHexString[i + 1])) {
      if (error) {
        *error = [NSError lt_errorWithCode:LTErrorCodeHexDecodingFailed
                               description:@"Invalid char '%c' at position %lu", cHexString[i],
                  (unsigned long)i];
      }
      return nil;
    }

    uint8_t value;
    sscanf(&cHexString[i], "%02hhx", &value);
    [mutableData appendBytes:&value length:1];
  }

  return [mutableData copy];
}

- (NSString *)lt_hexString {
  NSMutableString *hexString = [NSMutableString string];
  auto bytes = (const unsigned char *)self.bytes;
  for (NSUInteger i = 0; i < self.length; ++i) {
    [hexString appendFormat:@"%02X", bytes[i]];
  }

  return [hexString copy];
}

@end

NS_ASSUME_NONNULL_END
