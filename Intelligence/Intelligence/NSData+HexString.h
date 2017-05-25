// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

NS_ASSUME_NONNULL_BEGIN

@interface NSData (HexString)

/// Returns lower-case hexadecimal, zero padded string represention of the data, For example, the
/// buffer { 0x1, 0x2f, 0x4, 0xdc, 0x34, 0x3c } be returned as "012f04dc343c".
- (NSString *)int_hexString;

@end

NS_ASSUME_NONNULL_END
