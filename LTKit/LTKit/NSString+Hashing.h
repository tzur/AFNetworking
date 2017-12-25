// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

NS_ASSUME_NONNULL_BEGIN

/// Category for hashing an \c NSString.
@interface NSString (Hashing)

/// Hex string of the MD5 of the receiver.
- (NSString *)lt_MD5;

/// Hex string of the SHA1-160 of the receiver.
- (NSString *)lt_SHA1;

/// Hex string of the SHA2-256 of the receiver.
- (NSString *)lt_SHA256;

/// Hex string of the HMAC SHA2-256 with the supplied \c key of the receiver.
- (NSString *)lt_HMACSHA256WithKey:(NSData *)key;

@end

NS_ASSUME_NONNULL_END
