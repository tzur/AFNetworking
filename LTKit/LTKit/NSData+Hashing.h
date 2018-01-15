// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

NS_ASSUME_NONNULL_BEGIN

/// Category for hashing \c NSData objects.
@interface NSData (Hashing)

/// MD5 of the receiver.
- (NSData *)lt_MD5;

/// SHA1-160 of the receiver.
- (NSData *)lt_SHA1;

/// SHA2-256 of the receiver.
- (NSData *)lt_SHA256;

/// HMAC SHA2-256 with the supplied \c key of the receiver.
- (NSData *)lt_HMACSHA256WithKey:(NSData *)key;

@end

NS_ASSUME_NONNULL_END
