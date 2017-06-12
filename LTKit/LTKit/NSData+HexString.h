// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

NS_ASSUME_NONNULL_BEGIN

@interface NSData (HexString)

/// Returns upper-case hexadecimal, zero padded string represention of the data, For example, the
/// buffer { 0x1, 0x2f, 0x4, 0xdc, 0x34, 0x3c } be returned as "012F04DC343C".
- (NSString *)lt_hexString;

@end

NS_ASSUME_NONNULL_END
