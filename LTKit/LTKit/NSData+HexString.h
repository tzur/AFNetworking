// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

NS_ASSUME_NONNULL_BEGIN

@interface NSData (HexString)

/// Creates a new \c NSData instance by interpreting \c hexString as a hexadecimal-encoded byte
/// array. \c error is set with an appropriate error if \c hexString contains non-hexdecimal digits
/// or if the string length is odd.
///
/// For example, the hex string "012F04DC343C" creates a new \c NSData as the buffer
/// <tt>{0x1, 0x2f, 0x4, 0xdc, 0x34, 0x3c}</tt>.
+ (nullable NSData *)lt_dataWithHexString:(NSString *)hexString
                                    error:(NSError * __autoreleasing *)error;

/// Returns upper-case hexadecimal, zero padded string represention of the data, For example, the
/// buffer <tt>{0x1, 0x2f, 0x4, 0xdc, 0x34, 0x3c}</tt> be returned as "012F04DC343C".
- (NSString *)lt_hexString;

@end

NS_ASSUME_NONNULL_END
