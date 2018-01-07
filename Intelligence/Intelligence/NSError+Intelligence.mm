// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "NSError+Intelligence.h"

NS_ASSUME_NONNULL_BEGIN

NSString * const kINTErrorDataRecordKey = @"DataRecord";

@implementation NSError (Intelligence)

+ (instancetype)int_errorWithCode:(NSInteger)code record:(nullable NSData *)record {
  return [NSError lt_errorWithCode:code userInfo:@{
    kINTErrorDataRecordKey: nn<id>(record, [NSNull null])
  }];
}

+ (instancetype)int_errorWithCode:(NSInteger)code record:(nullable NSData *)record
                  underlyingError:(nullable NSError *)underlyingError {
  return [NSError lt_errorWithCode:code userInfo:@{
    kINTErrorDataRecordKey: nn<id>(record, [NSNull null]),
    NSUnderlyingErrorKey: nn(underlyingError, [NSError int_nullValueGivenError])
  }];
}

+ (instancetype)int_nullValueGivenError {
  return [NSError lt_errorWithCode:LTErrorCodeNullValueGiven];
}

- (nullable NSString *)int_record {
  return self.userInfo[kINTErrorDataRecordKey] != [NSNull null] ?
      self.userInfo[kINTErrorDataRecordKey] : nil;
}

@end

NS_ASSUME_NONNULL_END
