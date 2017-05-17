// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "NSUUID+Zero.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSUUID (Zero)

+ (instancetype)int_zeroUUID {
  return [[NSUUID alloc] initWithUUIDString:@"00000000-0000-0000-0000-000000000000"];
}

@end

NS_ASSUME_NONNULL_END
