// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

NS_ASSUME_NONNULL_BEGIN

/// Category for creating zeroed out \c NSUUID.
@interface NSUUID (Zero)

/// Return a \c NSUUID with the value "00000000-0000-0000-0000-000000000000".
+ (instancetype)int_zeroUUID;

@end

NS_ASSUME_NONNULL_END
