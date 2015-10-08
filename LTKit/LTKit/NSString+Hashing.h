// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

NS_ASSUME_NONNULL_BEGIN

/// Category for hashing an \c NSString.
@interface NSString (Hashing)

/// Hex string of the MD5 of the receiver.
- (NSString *)lt_MD5;

/// Hex string of the SHA1-160 of the receiver.
- (NSString *)lt_SHA1;

@end

NS_ASSUME_NONNULL_END
