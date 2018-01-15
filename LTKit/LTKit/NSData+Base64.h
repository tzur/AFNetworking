// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

NS_ASSUME_NONNULL_BEGIN

/// Adds methods to convert objects to and from base64 strings, and "URL safe" base64 strings.
/// "URL safe" means that it does not contain characters that need to be percent escaped in URLs.
/// This is done by using '-' instead of '+' and '_' instead of '/' and by removing the '=' padding
/// character.
@interface NSData (Base64)

/// Initializes with given \c urlSafeBase64String. The given string is converted to normal base64
/// encoded string and then converted into \c NSData. \c nil is returned if the string contains
/// non-url-safe-base64 characters or if decoding fails.
///
/// @see -[NSData initWithBase64EncodedString:options:]
- (nullable instancetype)initWithURLSafeBase64EncodedString:(NSString *)urlSafeBase64String;

/// Returns a base64 encoding of the receiver, without any newline characters.
- (NSString *)lt_base64;

/// Returns a "URL safe" base 64 encoding of the receiver.
- (NSString *)lt_urlSafeBase64;

@end

NS_ASSUME_NONNULL_END
